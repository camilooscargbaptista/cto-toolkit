# Domain-Driven Design (DDD) - Quick Reference

## Bounded Context

A clearly defined boundary within which a domain model applies. Each context has its own ubiquitous language (shared vocabulary) and model.

### Example: E-Commerce System

```
┌──────────────────────┐    ┌──────────────────────┐    ┌──────────────────┐
│   Order Context      │    │  Inventory Context   │    │ Shipping Context │
├──────────────────────┤    ├──────────────────────┤    ├──────────────────┤
│ Order                │    │ Product              │    │ Shipment         │
│ OrderItem            │    │ Stock                │    │ TrackingInfo     │
│ OrderStatus          │    │ SKU                  │    │ DeliveryAddress  │
│                      │    │ Warehouse            │    │ CarrierAccount   │
│ Language:            │    │                      │    │                  │
│ - Place Order        │    │ Language:            │    │ Language:        │
│ - Cancel Order       │    │ - Check Stock        │    │ - Create Shipment│
│ - Refund Order       │    │ - Reserve Items      │    │ - Update Tracking│
│ - Process Payment    │    │ - Deduct Stock       │    │ - Confirm Receipt│
└──────────────────────┘    └──────────────────────┘    └──────────────────┘
```

Each context models the problem domain differently. A "Product" in Order context is a simple reference; in Inventory context, it has quantity, warehouse location, reorder points, etc.

---

## Aggregate and Aggregate Root

An aggregate is a cluster of entities and value objects treated as a single unit for data consistency. The **Aggregate Root** is the only entity you interact with from outside the aggregate.

### Anti-Pattern: No Clear Boundaries
```typescript
// ❌ Every part of Order can be modified directly
const order = orderRepository.findById('123');
order.items[0].quantity = 999; // Anyone can do this!
order.customer.email = 'hacker@evil.com'; // Violates business rules!
order.status = OrderStatus.SHIPPED; // Without payment?
```

### Pattern: Aggregate with Root
```typescript
// Domain layer
export class Order {
  constructor(
    private id: string,
    private items: OrderItem[],
    private customer: Customer,
    private status: OrderStatus
  ) {}

  // ✅ All modifications go through the root
  addItem(item: OrderItem): void {
    if (!this.isEditable()) {
      throw new OrderNotEditableError();
    }
    this.items.push(item);
  }

  updateCustomerEmail(email: Email): void {
    // Business rule: Can't change email after payment
    if (this.status === OrderStatus.PAID) {
      throw new Error('Cannot change customer after payment');
    }
    this.customer.updateEmail(email);
  }

  ship(): void {
    // Business rule: Must be paid first
    if (this.status !== OrderStatus.PAID) {
      throw new Error('Must be paid before shipping');
    }
    this.status = OrderStatus.SHIPPED;
  }

  // Query methods return immutable references
  getItems(): ReadonlyArray<OrderItem> {
    return Object.freeze([...this.items]);
  }

  getCustomer(): Customer {
    return this.customer;
  }
}

// ✅ Now you can only modify through the root
const order = orderRepository.findById('123');
order.addItem(newItem); // Safe - validates rules
order.ship(); // Safe - validates payment status
```

**Key:** The aggregate root controls all modifications. You fetch and save the entire aggregate, ensuring consistency.

---

## Domain Events

Something that happened in the domain that other parts of the system care about. Enables loose coupling between aggregates and contexts.

### Events That Matter
```typescript
// Domain layer - in order context
export class OrderPlacedEvent {
  constructor(
    readonly orderId: string,
    readonly customerId: string,
    readonly items: OrderItem[],
    readonly total: Money,
    readonly occurredAt: Date = new Date()
  ) {}
}

export class PaymentReceivedEvent {
  constructor(
    readonly orderId: string,
    readonly amount: Money,
    readonly paymentMethod: string,
    readonly transactionId: string,
    readonly occurredAt: Date = new Date()
  ) {}
}

// In domain entity
export class Order {
  private domainEvents: DomainEvent[] = [];

  static create(id: string, items: OrderItem[]): Order {
    const order = new Order(id, items, OrderStatus.DRAFT);
    order.addDomainEvent(
      new OrderPlacedEvent(id, customerId, items, order.total)
    );
    return order;
  }

  recordPayment(transactionId: string, amount: Money): void {
    this.status = OrderStatus.PAID;
    this.addDomainEvent(
      new PaymentReceivedEvent(this.id, amount, transactionId)
    );
  }

  private addDomainEvent(event: DomainEvent): void {
    this.domainEvents.push(event);
  }

  getDomainEvents(): DomainEvent[] {
    return [...this.domainEvents];
  }

  clearDomainEvents(): void {
    this.domainEvents = [];
  }
}
```

### Publishing Events
```typescript
// Application layer
export class CreateOrderUseCase {
  constructor(
    private orderRepository: OrderRepository,
    private eventBus: EventBus
  ) {}

  async execute(dto: CreateOrderDTO): Promise<string> {
    const order = Order.create(generateId(), items);
    // ... validation and payment ...
    await this.orderRepository.save(order);

    // ✅ Publish events after saving
    for (const event of order.getDomainEvents()) {
      await this.eventBus.publish(event);
    }
    order.clearDomainEvents();

    return order.id;
  }
}
```

### Subscribing to Events
```typescript
// In shipping context - doesn't know about Order context
export class ShippingService {
  constructor(private eventBus: EventBus) {
    this.eventBus.subscribe(PaymentReceivedEvent, (event) => {
      this.createShipment(event.orderId);
    });
  }

  private async createShipment(orderId: string): Promise<void> {
    // Now we know the order is paid, create shipment
    const shipment = Shipment.create(orderId);
    // ... persist, send notifications, etc ...
  }
}

// In accounting context
export class AccountingService {
  constructor(private eventBus: EventBus) {
    this.eventBus.subscribe(OrderPlacedEvent, (event) => {
      this.recordRevenue(event.total);
    });
  }
}
```

**Key:** Events decouple bounded contexts. Shipping and Accounting don't need to know Order's internal structure.

---

## Anti-Corruption Layer

Translates between bounded contexts to prevent external models from polluting your domain.

### Problem: Leaking External Model
```typescript
// ❌ Order context knows about Payment service's response
interface ExternalPaymentResponse {
  transaction_id: string;
  status: string;
  timestamp: string;
  metadata: {
    reference: string;
    provider: string;
  };
}

export class Order {
  // Directly using external structure - violates ubiquitous language
  payment: ExternalPaymentResponse;
}
```

### Solution: Translate at Boundary
```typescript
// Payment context - external service response (not ours)
interface ExternalPaymentResponse {
  transaction_id: string;
  status: string;
  timestamp: string;
  metadata: { reference: string; provider: string };
}

// Anti-Corruption Layer - translates external → domain language
export class PaymentGatewayAdapter implements PaymentGateway {
  constructor(private externalGateway: ExternalPaymentService) {}

  async authorize(
    amount: Money,
    method: string
  ): Promise<PaymentAuthorization> {
    const externalResponse = await this.externalGateway.charge({
      amount: amount.cents,
      currency: amount.currency,
      method: method
    });

    // ✅ Translate to our domain language
    return new PaymentAuthorization(
      externalResponse.transaction_id,
      this.mapStatus(externalResponse.status),
      new Date(externalResponse.timestamp)
    );
  }

  private mapStatus(
    externalStatus: string
  ): PaymentStatus {
    switch (externalStatus) {
      case 'SUCCESSFUL': return PaymentStatus.APPROVED;
      case 'FAILED': return PaymentStatus.DECLINED;
      case 'PENDING': return PaymentStatus.PENDING;
      default: return PaymentStatus.UNKNOWN;
    }
  }
}

// Order domain - clean, independent
export class Order {
  payment: PaymentAuthorization; // Our domain model, not theirs
}
```

**Key:** The adapter isolates your domain from external service quirks. If the payment provider changes their response format, only the adapter changes.

---

## Context Mapping Strategies

How do bounded contexts relate and interact?

### 1. Partnership
Two teams work together on a shared boundary. Both maintain upstream and downstream responsibility.

```
Order Context ←→ Inventory Context
(Partnership)
```

**Example:** Order and Inventory coordinate on reserved items.

### 2. Customer-Supplier
Downstream context (customer) depends on upstream context (supplier). Upstream has responsibility to maintain a stable interface.

```
Order Context → Payment Context
(Customer)     (Supplier)
```

**Example:** Order uses Payment's external API.

### 3. Anti-Corruption Layer
Downstream shields itself with an adapter. Used when you integrate with external systems.

```
Order Context
    ↓
  [ACL Adapter]
    ↓
External Payment System
```

### 4. Separate Ways
Contexts operate independently. No integration, possibly duplicated data.

```
Order Context     Marketing Context
  (Separate)
```

**Example:** Each context tracks its own customer data differently. Marketing doesn't care about Order's details.

### 5. Shared Kernel
Contexts share a common domain model in a shared library. Rare and requires careful coordination.

```
Shared: Money, Address, Email

Order Context ← Shared Kernel → Shipping Context
```

---

## When to Use DDD

✅ **Use DDD when:**
- Domain is complex with rich business logic
- Multiple teams, multiple bounded contexts
- Business rules are a source of competitive advantage
- Long-term system that will evolve significantly

❌ **Don't use DDD for:**
- Simple CRUD applications with no business logic
- Prototypes or MVPs with unclear requirements
- Systems where database schema is the model

DDD is about managing complexity through better language and structure. It's overhead if there's no complexity.
