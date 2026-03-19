# Clean Architecture - Detailed Guide

## Core Concepts

Clean Architecture separates code into concentric layers, with dependencies always pointing inward. The domain (business logic) is at the center and knows nothing about frameworks, databases, or external services.

---

## Layer Breakdown

### 1. Domain Layer (Innermost)
Business logic, entities, value objects, and interfaces (ports). **Zero external dependencies.**

### 2. Application Layer
Use cases and orchestration. Coordinates domain objects and infrastructure. Depends on domain layer.

### 3. Interface/Presentation Layer
Controllers, CLI, web handlers. Translates external input to application layer language.

### 4. Infrastructure Layer (Outermost)
Database, APIs, messaging, file systems. Implements ports defined in domain.

---

## Entity Example: Order

An Entity has identity and encapsulates business rules.

```typescript
// Domain layer - knows nothing about databases, APIs, or frameworks
import { OrderStatus, Money, OrderItem } from './value-objects';
import { OrderNotEditableError, InsufficientStockError } from './errors';

export class Order {
  constructor(
    private id: string,
    private items: OrderItem[],
    private status: OrderStatus,
    private total: Money,
    private createdAt: Date
  ) {}

  // ✅ Business logic in the entity
  addItem(item: OrderItem): void {
    if (this.status !== OrderStatus.DRAFT) {
      throw new OrderNotEditableError(
        `Cannot add item to order in ${this.status} status`
      );
    }

    if (item.quantity <= 0) {
      throw new Error('Quantity must be positive');
    }

    this.items.push(item);
    this.total = this.total.add(item.subtotal);
  }

  removeItem(productId: string): void {
    if (this.status !== OrderStatus.DRAFT) {
      throw new OrderNotEditableError();
    }

    const index = this.items.findIndex(item => item.productId === productId);
    if (index === -1) {
      throw new Error('Item not found in order');
    }

    const removed = this.items.splice(index, 1)[0];
    this.total = this.total.subtract(removed.subtotal);
  }

  // Transition through valid states only
  confirmOrder(): void {
    if (this.status !== OrderStatus.DRAFT) {
      throw new Error(`Cannot confirm order in ${this.status} status`);
    }
    this.status = OrderStatus.CONFIRMED;
  }

  completePayment(authorizationId: string): void {
    if (this.status !== OrderStatus.CONFIRMED) {
      throw new Error('Order must be confirmed before payment');
    }
    this.status = OrderStatus.PAID;
    this.paymentAuthorizationId = authorizationId;
  }

  ship(): void {
    if (this.status !== OrderStatus.PAID) {
      throw new Error('Order must be paid before shipping');
    }
    this.status = OrderStatus.SHIPPED;
  }

  // Query methods
  get isEditable(): boolean {
    return this.status === OrderStatus.DRAFT;
  }

  get totalAmount(): Money {
    return this.total;
  }

  get itemCount(): number {
    return this.items.length;
  }

  getItems(): OrderItem[] {
    return [...this.items]; // Return copy, not reference
  }

  // Static factory for domain-driven creation
  static create(id: string, items: OrderItem[]): Order {
    if (items.length === 0) {
      throw new Error('Order must have at least one item');
    }

    const total = items.reduce(
      (sum, item) => sum.add(item.subtotal),
      Money.zero()
    );

    return new Order(id, items, OrderStatus.DRAFT, total, new Date());
  }

  // Reconstruct from persistence (for repository)
  static fromPersistence(data: any): Order {
    return new Order(
      data.id,
      data.items.map(OrderItem.fromPersistence),
      data.status,
      Money.fromPersistence(data.total),
      new Date(data.createdAt)
    );
  }

  // Convert to persistence format
  toPersistence(): any {
    return {
      id: this.id,
      items: this.items.map(item => item.toPersistence()),
      status: this.status,
      total: this.total.toPersistence(),
      createdAt: this.createdAt.toISOString()
    };
  }
}
```

**Key:** Order encapsulates its own rules. You can't create an invalid order; the Entity enforces constraints.

---

## Value Object Example: Money

Value Objects are immutable and defined by their attributes, not identity.

```typescript
// Domain layer
export class Money {
  constructor(
    readonly amount: number,
    readonly currency: string
  ) {
    if (amount < 0) {
      throw new Error('Amount cannot be negative');
    }
    if (!['USD', 'BRL', 'EUR'].includes(currency)) {
      throw new Error(`Unsupported currency: ${currency}`);
    }
  }

  // ✅ Immutability - always return new instance
  add(other: Money): Money {
    this.assertSameCurrency(other);
    return new Money(this.amount + other.amount, this.currency);
  }

  subtract(other: Money): Money {
    this.assertSameCurrency(other);
    if (other.amount > this.amount) {
      throw new Error('Cannot subtract more than available');
    }
    return new Money(this.amount - other.amount, this.currency);
  }

  multiply(factor: number): Money {
    if (factor < 0) {
      throw new Error('Factor must be non-negative');
    }
    return new Money(this.amount * factor, this.currency);
  }

  // ✅ Equality by value, not reference
  equals(other: Money): boolean {
    return this.amount === other.amount && this.currency === other.currency;
  }

  isGreaterThan(other: Money): boolean {
    this.assertSameCurrency(other);
    return this.amount > other.amount;
  }

  isLessThan(other: Money): boolean {
    this.assertSameCurrency(other);
    return this.amount < other.amount;
  }

  get cents(): number {
    return Math.round(this.amount * 100);
  }

  private assertSameCurrency(other: Money): void {
    if (this.currency !== other.currency) {
      throw new Error(
        `Currency mismatch: ${this.currency} vs ${other.currency}`
      );
    }
  }

  static zero(currency: string = 'USD'): Money {
    return new Money(0, currency);
  }

  static fromCents(cents: number, currency: string): Money {
    return new Money(cents / 100, currency);
  }

  static fromPersistence(data: any): Money {
    return new Money(data.amount, data.currency);
  }

  toPersistence(): any {
    return { amount: this.amount, currency: this.currency };
  }

  toString(): string {
    return `${this.currency} ${this.amount.toFixed(2)}`;
  }
}
```

**Key:** Money is immutable. Operations like `add()` return a new Money instance. Two Money objects with the same values are considered equal.

---

## Use Case Example: CreateOrderUseCase

A use case is a transaction script that orchestrates domain objects.

```typescript
// Application layer
import { Order } from '../domain/Order';
import { Money } from '../domain/Money';
import { OrderRepository } from '../domain/ports/OrderRepository';
import { PaymentGateway } from '../domain/ports/PaymentGateway';
import { OrderPlacedEvent } from '../domain/events/OrderPlacedEvent';
import { EventBus } from '../domain/ports/EventBus';

export interface CreateOrderDTO {
  customerId: string;
  items: Array<{
    productId: string;
    quantity: number;
    unitPrice: number;
  }>;
  paymentMethod: string;
}

export class CreateOrderUseCase {
  constructor(
    private orderRepository: OrderRepository,
    private paymentGateway: PaymentGateway,
    private eventBus: EventBus
  ) {}

  async execute(dto: CreateOrderDTO): Promise<string> {
    // 1. Create domain object (validates)
    const items = dto.items.map(item =>
      new OrderItem(
        item.productId,
        item.quantity,
        new Money(item.unitPrice, 'BRL')
      )
    );

    const order = Order.create(generateId(), items);

    // 2. Call payment gateway
    try {
      const auth = await this.paymentGateway.authorize(
        order.totalAmount,
        dto.paymentMethod
      );
      order.completePayment(auth.id);
    } catch (error) {
      throw new PaymentFailedError(`Payment failed: ${error.message}`);
    }

    // 3. Persist
    await this.orderRepository.save(order);

    // 4. Publish domain event
    const event = new OrderPlacedEvent(
      order.id,
      order.customerId,
      order.totalAmount,
      new Date()
    );
    await this.eventBus.publish(event);

    return order.id;
  }
}
```

**Key:**
- Use case orchestrates domain objects and ports
- Does not know about HTTP, databases, or specific APIs
- Easy to test with mock implementations
- Pure business logic flow

---

## Repository Interface (Port)

Defined in the domain layer. Infrastructure implements it.

```typescript
// Domain layer - just the interface
export interface OrderRepository {
  save(order: Order): Promise<void>;
  findById(id: string): Promise<Order | null>;
  findByCustomerId(customerId: string): Promise<Order[]>;
  update(order: Order): Promise<void>;
  delete(id: string): Promise<void>;
}
```

---

## Infrastructure Implementation (Adapter)

```typescript
// Infrastructure layer
import { Pool } from 'pg';
import { Order } from '../domain/Order';
import { OrderRepository } from '../domain/ports/OrderRepository';

export class PostgreSQLOrderRepository implements OrderRepository {
  constructor(private pool: Pool) {}

  async save(order: Order): Promise<void> {
    const data = order.toPersistence();

    const query = `
      INSERT INTO orders (id, customer_id, items, total, status, created_at)
      VALUES ($1, $2, $3, $4, $5, $6)
    `;

    await this.pool.query(query, [
      data.id,
      data.customerId,
      JSON.stringify(data.items),
      data.total.amount,
      data.status,
      data.createdAt
    ]);
  }

  async findById(id: string): Promise<Order | null> {
    const query = 'SELECT * FROM orders WHERE id = $1';
    const result = await this.pool.query(query, [id]);

    if (result.rows.length === 0) return null;

    return Order.fromPersistence(result.rows[0]);
  }

  async findByCustomerId(customerId: string): Promise<Order[]> {
    const query = 'SELECT * FROM orders WHERE customer_id = $1';
    const result = await this.pool.query(query, [customerId]);

    return result.rows.map(row => Order.fromPersistence(row));
  }

  async update(order: Order): Promise<void> {
    const data = order.toPersistence();

    const query = `
      UPDATE orders
      SET items = $2, total = $3, status = $4
      WHERE id = $1
    `;

    await this.pool.query(query, [
      data.id,
      JSON.stringify(data.items),
      data.total.amount,
      data.status
    ]);
  }

  async delete(id: string): Promise<void> {
    const query = 'DELETE FROM orders WHERE id = $1';
    await this.pool.query(query, [id]);
  }
}
```

**Key:** Infrastructure knows about PostgreSQL, but domain doesn't. You can swap this for MongoDB, Firebase, or an in-memory store without touching domain logic.

---

## Project Structure

```
src/
├── domain/                    # ✅ Business logic, zero external deps
│   ├── entities/
│   │   ├── Order.ts
│   │   ├── Product.ts
│   │   └── User.ts
│   ├── value-objects/
│   │   ├── Money.ts
│   │   ├── Email.ts
│   │   └── OrderStatus.ts
│   ├── errors/
│   │   ├── OrderNotEditableError.ts
│   │   └── InsufficientStockError.ts
│   ├── events/
│   │   ├── OrderPlacedEvent.ts
│   │   └── PaymentReceivedEvent.ts
│   └── ports/
│       ├── OrderRepository.ts
│       ├── PaymentGateway.ts
│       └── EventBus.ts
│
├── application/               # ✅ Use cases, depends on domain
│   ├── use-cases/
│   │   ├── CreateOrderUseCase.ts
│   │   ├── CancelOrderUseCase.ts
│   │   └── ListCustomerOrdersUseCase.ts
│   └── dtos/
│       ├── CreateOrderDTO.ts
│       └── OrderResultDTO.ts
│
├── presentation/              # ✅ Controllers, depends on application
│   ├── http/
│   │   ├── OrderController.ts
│   │   └── PaymentWebhookController.ts
│   ├── cli/
│   │   └── OrderCLI.ts
│   └── graphql/
│       └── OrderResolver.ts
│
├── infrastructure/            # ✅ Implementations, depends on domain
│   ├── database/
│   │   ├── PostgreSQLOrderRepository.ts
│   │   └── migrations/
│   ├── payment/
│   │   ├── StripePaymentGateway.ts
│   │   └── PixPaymentGateway.ts
│   ├── events/
│   │   └── RabbitMQEventBus.ts
│   └── persistence/
│       └── database-connection.ts
│
├── container.ts               # ✅ Dependency injection setup
└── main.ts                    # ✅ Application entry point
```

---

## The Dependency Rule

```
       Presentation
            ↓
      Application
            ↓
         Domain
            ↓
     Infrastructure
```

**All arrows point inward.** Domain knows nothing about outer layers. Infrastructure implements domain interfaces. Easy to replace, test, and extend.
