# SOLID Principles - Detailed TypeScript Examples

## S — Single Responsibility Principle

### Problem: God Class
```typescript
// ❌ UserService violates SRP - multiple reasons to change
class UserService {
  registerUser(email: string, password: string): void {
    // Validation logic
    if (!email.includes('@')) throw new Error('Invalid email');

    // Password hashing
    const hash = bcrypt.hashSync(password, 10);

    // Email sending
    const transporter = nodemailer.createTransport({...});
    transporter.sendMail({to: email, subject: 'Welcome'});

    // Database persistence
    db.users.insert({email, passwordHash: hash});
  }
}
```

### Solution: Separate Concerns
```typescript
// ✅ Each class has one reason to change

class UserRegistrationService {
  constructor(
    private userRepository: UserRepository,
    private passwordHasher: PasswordHasher,
    private emailService: EmailService
  ) {}

  register(email: string, password: string): User {
    const hashedPassword = this.passwordHasher.hash(password);
    const user = new User(email, hashedPassword);
    this.userRepository.save(user);
    this.emailService.sendWelcomeEmail(user);
    return user;
  }
}

class PasswordHasher {
  hash(password: string): string {
    return bcrypt.hashSync(password, 10);
  }

  verify(password: string, hash: string): boolean {
    return bcrypt.compareSync(password, hash);
  }
}

class EmailService {
  sendWelcomeEmail(user: User): Promise<void> {
    return this.transporter.sendMail({
      to: user.email,
      subject: 'Welcome!',
      html: this.renderTemplate(user)
    });
  }
}

interface UserRepository {
  save(user: User): Promise<void>;
  findByEmail(email: string): Promise<User | null>;
}
```

**Key:** Each class changes for only one reason:
- `PasswordHasher`: changes when hashing algorithm changes
- `EmailService`: changes when email logic changes
- `UserRegistrationService`: changes when business flow changes

---

## O — Open/Closed Principle

### Problem: Modifying Existing Code for New Features
```typescript
// ❌ Adding a new payment method requires modifying this function
function processPayment(type: string, amount: number): PaymentResult {
  if (type === 'credit') {
    return chargeCreditCard(amount);
  } else if (type === 'pix') {
    return chargePix(amount);
  } else if (type === 'boleto') {
    return chargeBoleto(amount);
  } else if (type === 'apple_pay') {
    // Had to modify this function again!
    return chargeApplePay(amount);
  }
}
```

### Solution: Strategy Pattern
```typescript
// ✅ Open for extension, closed for modification

interface PaymentProcessor {
  process(amount: Money): Promise<PaymentResult>;
}

class CreditCardProcessor implements PaymentProcessor {
  constructor(private gateway: StripeGateway) {}

  async process(amount: Money): Promise<PaymentResult> {
    const result = await this.gateway.charge({
      amount: amount.cents,
      currency: amount.currency
    });
    return new PaymentResult(result.id, 'success');
  }
}

class PixProcessor implements PaymentProcessor {
  constructor(private gateway: PixGateway) {}

  async process(amount: Money): Promise<PaymentResult> {
    const result = await this.gateway.createTransaction({
      value: amount.amount,
      key: this.recipientKey
    });
    return new PaymentResult(result.id, 'pending');
  }
}

class BoletoProcessor implements PaymentProcessor {
  constructor(private gateway: BoletoGateway) {}

  async process(amount: Money): Promise<PaymentResult> {
    const boleto = await this.gateway.generate({
      amount: amount.amount,
      dueDate: this.calculateDueDate()
    });
    return new PaymentResult(boleto.barcode, 'pending');
  }
}

// New payment method? Just add a class, no modifications needed
class ApplePayProcessor implements PaymentProcessor {
  async process(amount: Money): Promise<PaymentResult> {
    // Implementation
  }
}

class PaymentService {
  constructor(private processors: Map<string, PaymentProcessor>) {}

  async pay(method: string, amount: Money): Promise<PaymentResult> {
    const processor = this.processors.get(method);
    if (!processor) throw new Error(`Unknown payment method: ${method}`);
    return processor.process(amount);
  }
}

// Register in DI container
const paymentService = new PaymentService(new Map([
  ['credit', new CreditCardProcessor(stripe)],
  ['pix', new PixProcessor(pix)],
  ['boleto', new BoletoProcessor(boleto)],
  ['apple_pay', new ApplePayProcessor(apple)]
]));
```

**Benefit:** Adding a new payment method is pure addition, zero risk of breaking existing code.

---

## L — Liskov Substitution Principle

### Problem: Broken Substitutability
```typescript
// ❌ Square violates LSP - can't substitute for Rectangle
class Rectangle {
  protected width: number;
  protected height: number;

  setWidth(width: number): void {
    this.width = width;
  }

  setHeight(height: number): void {
    this.height = height;
  }

  area(): number {
    return this.width * this.height;
  }
}

class Square extends Rectangle {
  setWidth(width: number): void {
    this.width = width;
    this.height = width; // Force equal sides
  }

  setHeight(height: number): void {
    this.width = height;
    this.height = height;
  }
}

// This breaks!
function validateArea(shape: Rectangle): void {
  shape.setWidth(5);
  shape.setHeight(4);
  console.assert(shape.area() === 20); // Fails for Square!
}
```

### Solution: Composition Over Inheritance
```typescript
// ✅ Use proper abstractions

interface Shape {
  area(): number;
}

class Rectangle implements Shape {
  constructor(protected width: number, protected height: number) {}

  area(): number {
    return this.width * this.height;
  }
}

class Square implements Shape {
  constructor(private side: number) {}

  area(): number {
    return this.side * this.side;
  }
}

// Both can substitute for Shape safely
function validateArea(shape: Shape): void {
  // Works correctly for all implementations
  const a = shape.area();
  console.assert(a > 0);
}
```

**Key Insight:** Use composition/interfaces instead of inheritance when contracts differ. `Square` and `Rectangle` are distinct shapes with different construction semantics.

---

## I — Interface Segregation Principle

### Problem: Fat Interface
```typescript
// ❌ Clients forced to depend on methods they don't use
interface Worker {
  code(): void;
  test(): void;
  design(): void;
  manage(): void;
  deploy(): void;
}

class Junior implements Worker {
  code(): void { /* OK */ }
  test(): void { /* OK */ }
  design(): void { throw new Error('Not my job'); }
  manage(): void { throw new Error('Not my job'); }
  deploy(): void { throw new Error('Not my job'); }
}

class TeamLead implements Worker {
  code(): void { /* Some */ }
  test(): void { /* Some */ }
  design(): void { /* OK */ }
  manage(): void { /* OK */ }
  deploy(): void { throw new Error('Not my job'); }
}
```

### Solution: Segregated Interfaces
```typescript
// ✅ Clients depend only on what they use

interface Developer {
  code(): void;
}

interface Tester {
  test(): void;
}

interface Architect {
  design(): void;
}

interface Manager {
  manage(): void;
}

interface DevOpsEngineer {
  deploy(): void;
}

class Junior implements Developer, Tester {
  code(): void { /* ... */ }
  test(): void { /* ... */ }
}

class Senior implements Developer, Tester, Architect {
  code(): void { /* ... */ }
  test(): void { /* ... */ }
  design(): void { /* ... */ }
}

class TeamLead implements Developer, Architect, Manager {
  code(): void { /* Some */ }
  design(): void { /* ... */ }
  manage(): void { /* ... */ }
}

class DevOpsEngineer implements DevOpsEngineer {
  deploy(): void { /* ... */ }
}

// Now each role implements only interfaces it actually uses
function assignCode(dev: Developer): void {
  dev.code();
}

function assignManagement(manager: Manager): void {
  manager.manage();
}
```

**Benefit:** Classes aren't forced to implement methods they don't use. Better flexibility, cleaner contracts.

---

## D — Dependency Inversion Principle

### Problem: Direct Infrastructure Dependency
```typescript
// ❌ Domain logic depends on concrete infrastructure
class CreateOrderUseCase {
  async execute(dto: CreateOrderDTO): Promise<Order> {
    // Depends directly on PostgreSQL connection
    const db = new PostgreSQLConnection('localhost', 5432);

    // Depends directly on Stripe API
    const stripe = new Stripe('sk_live_...');

    const order = Order.create(dto.items);
    await stripe.charge(order.total.cents);

    const result = db.query(
      'INSERT INTO orders (items, total) VALUES ($1, $2)',
      [JSON.stringify(order.items), order.total.cents]
    );

    return order;
  }
}
```

### Solution: Depend on Abstractions (Ports)
```typescript
// ✅ Domain defines ports; infrastructure implements adapters

// Domain layer (knows nothing about infrastructure)
interface OrderRepository {
  save(order: Order): Promise<void>;
  findById(id: string): Promise<Order | null>;
}

interface PaymentGateway {
  authorize(amount: Money): Promise<PaymentAuthorization>;
  capture(authorizationId: string): Promise<void>;
}

class CreateOrderUseCase {
  constructor(
    private orderRepository: OrderRepository,      // Port (interface)
    private paymentGateway: PaymentGateway        // Port (interface)
  ) {}

  async execute(dto: CreateOrderDTO): Promise<Order> {
    const order = Order.create(dto.items);

    const auth = await this.paymentGateway.authorize(order.total);

    order.authorizePayment(auth.id);
    await this.orderRepository.save(order);

    return order;
  }
}

// Infrastructure layer (adapters)
class PostgreSQLOrderRepository implements OrderRepository {
  constructor(private db: DatabaseConnection) {}

  async save(order: Order): Promise<void> {
    await this.db.query(
      'INSERT INTO orders (id, items, total, status) VALUES ($1, $2, $3, $4)',
      [order.id, order.items, order.total.cents, order.status]
    );
  }

  async findById(id: string): Promise<Order | null> {
    const row = await this.db.queryOne(
      'SELECT * FROM orders WHERE id = $1',
      [id]
    );
    return row ? Order.reconstruct(row) : null;
  }
}

class StripePaymentGateway implements PaymentGateway {
  constructor(private stripe: StripeAPI) {}

  async authorize(amount: Money): Promise<PaymentAuthorization> {
    const charge = await this.stripe.createCharge({
      amount: amount.cents,
      currency: amount.currency,
      capture: false
    });
    return new PaymentAuthorization(charge.id, charge.status);
  }

  async capture(authorizationId: string): Promise<void> {
    await this.stripe.captureCharge(authorizationId);
  }
}

// Dependency Injection - wire at the edge
const container = {
  orderRepository: new PostgreSQLOrderRepository(dbConnection),
  paymentGateway: new StripePaymentGateway(stripeAPI),
  createOrderUseCase: new CreateOrderUseCase(
    new PostgreSQLOrderRepository(dbConnection),
    new StripePaymentGateway(stripeAPI)
  )
};
```

**Key Benefit:** Domain logic is independent of infrastructure choices. Swap implementations without touching business logic. Easy to test with mock implementations.
