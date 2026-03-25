---
name: domain-modeling
description: "DDD practical guide: Event Storming, Bounded Contexts, Aggregates and domain-driven design patterns"
---

# Domain Modeling (DDD Practical)

## When to Use
- Starting a new module/service and need to define boundaries
- Complex business logic that doesn't fit in simple CRUD
- Team struggling with "where does this logic go?"
- Preparing for microservices decomposition

## Event Storming (Discovery)

### The Process
```
1. Invite: developers + domain experts + product
2. Orange stickies: Domain Events (past tense)
   "Abastecimento Validado", "Ciclo de Faturamento Fechado"
3. Blue stickies: Commands (what triggers events)
   "Validar Abastecimento", "Fechar Ciclo"
4. Yellow stickies: Aggregates (who handles commands)
   "Abastecimento", "CicloFaturamento"
5. Pink stickies: External Systems
   "Gateway Pagamento", "Emissor NF-e"
6. Group into Bounded Contexts
```

### Example — ZECA Domain
```
┌─── Refueling Context ──────────────────────────┐
│ Events:                                         │
│   RefeuelingCodeGenerated                       │
│   RefuelingValidated                            │
│   RefuelingCancelled                            │
│ Aggregates:                                     │
│   RefuelingCode, Refueling                      │
│ Commands:                                       │
│   GenerateCode, ValidateRefueling, CancelCode   │
└─────────────────────────────────────────────────┘

┌─── Billing Context ────────────────────────────┐
│ Events:                                         │
│   BillingCycleOpened                            │
│   FeeCalculated                                 │
│   CycleClosed                                   │
│   InvoiceGenerated                              │
│ Aggregates:                                     │
│   BillingCycle, Invoice                         │
│ Commands:                                       │
│   CalculateFee, CloseCycle, GenerateInvoice     │
└─────────────────────────────────────────────────┘
```

## Bounded Contexts

```
Rules:
1. Each context owns its data (no shared database tables)
2. Same word can mean different things in different contexts
   "User" in Auth = credentials + session
   "User" in Billing = payment info + billing address
3. Communication between contexts via events or APIs
4. One team per context (ideally)
```

## Aggregates

```typescript
// Aggregate = consistency boundary
// One transaction per aggregate
// Reference other aggregates by ID, not by object

// ✅ Good aggregate design
class BillingCycle {
  private id: string;
  private stationId: string;        // Reference by ID
  private status: CycleStatus;
  private transactions: Transaction[]; // Owned by this aggregate
  private totalFees: Money;

  // Business logic lives HERE
  addTransaction(refueling: RefuelingEvent): void {
    if (this.status !== 'ACTIVE') {
      throw new DomainError('Cannot add to closed cycle');
    }
    const fee = this.calculateFee(refueling);
    this.transactions.push(new Transaction(refueling.id, fee));
    this.totalFees = this.totalFees.add(fee);
  }

  close(): void {
    if (this.transactions.length === 0) {
      throw new DomainError('Cannot close empty cycle');
    }
    this.status = 'CLOSED';
    // Raises domain event
    this.raise(new BillingCycleClosed(this.id, this.totalFees));
  }
}

// ❌ Bad: anemic domain model
class BadBillingCycle {
  id: string;
  stationId: string;
  status: string;         // Public, no validation
  transactions: any[];    // No encapsulation
  totalFees: number;      // Primitive obsession
}
// All logic in BillingCycleService → anemic!
```

## Value Objects

```typescript
// Immutable, compared by value (not by ID)
class Money {
  constructor(
    private readonly amount: number,
    private readonly currency: string = 'BRL',
  ) {
    if (amount < 0) throw new DomainError('Amount cannot be negative');
    // Store as integer cents to avoid float precision
    this.amount = Math.round(amount * 100) / 100;
  }

  add(other: Money): Money {
    if (this.currency !== other.currency) {
      throw new DomainError('Cannot add different currencies');
    }
    return new Money(this.amount + other.amount, this.currency);
  }

  equals(other: Money): boolean {
    return this.amount === other.amount && this.currency === other.currency;
  }
}

class CPF {
  constructor(private readonly value: string) {
    if (!this.isValid(value)) {
      throw new DomainError('Invalid CPF');
    }
    this.value = value.replace(/\D/g, '');
  }

  private isValid(cpf: string): boolean {
    // Validation logic
    return true;
  }

  masked(): string {
    return `***.${this.value.slice(3, 6)}.${this.value.slice(6, 9)}-**`;
  }
}
```

## Domain Events

```typescript
// Event = something that happened (past tense, immutable)
class RefuelingValidated {
  constructor(
    public readonly refuelingId: string,
    public readonly stationId: string,
    public readonly amount: Money,
    public readonly occurredAt: Date = new Date(),
  ) {}
}

// Handler in another bounded context
@EventHandler(RefuelingValidated)
class BillingEventHandler {
  async handle(event: RefuelingValidated): Promise<void> {
    const cycle = await this.cycleRepo.findActive(event.stationId);
    cycle.addTransaction(event);
    await this.cycleRepo.save(cycle);
  }
}
```

## Quality Gates

- [ ] Business logic in domain objects (not services)
- [ ] Value Objects for domain concepts (Money, CPF, Email)
- [ ] Aggregates enforce invariants
- [ ] Bounded contexts communicate via events/APIs
- [ ] No direct database queries in domain layer
- [ ] Domain events for cross-context communication
