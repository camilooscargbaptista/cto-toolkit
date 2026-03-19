# BDD/Gherkin Examples & Step Definitions

## Gherkin Syntax

Gherkin is the language for writing BDD scenarios. It's human-readable and maps to test code.

```gherkin
Feature: Shopping Cart Checkout

  Scenario: Apply volume discount
    Given a cart with items totaling $150
    When the user proceeds to checkout
    Then a 10% discount should be applied
    And the total should be $135

  Scenario: Minimum order for free shipping
    Given a cart with items totaling $25
    When the user proceeds to checkout
    Then shipping cost of $10 should be added
    And the total should be $35
```

## Scenario Outline (Parameterized Tests)

Use Scenario Outline to test multiple cases with the same structure:

```gherkin
Feature: User Login

  Scenario Outline: Login with different credentials
    Given the login page is open
    When the user enters username "<username>" and password "<password>"
    Then the system should respond with "<result>"

    Examples:
      | username | password | result           |
      | alice    | correct  | success          |
      | alice    | wrong    | unauthorized     |
      | invalid  | test     | user_not_found   |
      | alice    | ""       | validation_error |
```

Another example with numeric data:

```gherkin
Feature: Discount Tiers

  Scenario Outline: Calculate discount based on cart subtotal
    Given a cart with items totaling <subtotal>
    When the user proceeds to checkout
    Then a <discount>% discount should be applied

    Examples:
      | subtotal | discount |
      | $50      | 0        |
      | $100     | 5        |
      | $200     | 10       |
      | $500     | 15       |
```

## Step Definitions in TypeScript (Cucumber.js)

### Basic Step Definitions

```typescript
import { Given, When, Then, Before, After } from '@cucumber/cucumber';
import { expect } from 'chai';

interface TestContext {
  cart: Cart;
  result: CheckoutResult;
  error: Error | null;
}

let context: TestContext;

Before(() => {
  context = {
    cart: new Cart(),
    result: null,
    error: null,
  };
});

Given('a cart with items totaling {currency}', (amount: string) => {
  const money = parseCurrency(amount); // e.g., "$150" -> Money.of(150, 'USD')
  context.cart = new Cart();
  context.cart.addItem(new CartItem('Product', money));
});

When('the user proceeds to checkout', async () => {
  try {
    context.result = await checkoutService.calculate(context.cart);
  } catch (err) {
    context.error = err;
  }
});

Then('a {int}% discount should be applied', (discountPercent: number) => {
  expect(context.result.discountPercent).to.equal(discountPercent);
});

Then('the total should be {currency}', (expectedTotal: string) => {
  const expected = parseCurrency(expectedTotal);
  expect(context.result.total).to.deep.equal(expected);
});

After(() => {
  // Cleanup
  context = null;
});
```

### Step Definition with Custom Parameters

```typescript
// Define custom parameter type
Given('a user with role {role}', (role: 'admin' | 'user' | 'guest') => {
  const user = createUser({ role });
  context.user = user;
});

When('the user {verb} the {resource}', (verb: string, resource: string) => {
  // Handle generic verbs: "creates", "deletes", "updates"
  const action = getAction(verb);
  context.result = action(context.user, resource);
});
```

### Data Table Step Definition

```gherkin
Feature: Bulk Import

  Scenario: Import multiple users
    Given the following users exist:
      | email              | role   | status  |
      | alice@example.com  | admin  | active  |
      | bob@example.com    | user   | pending |
      | carol@example.com  | user   | active  |
    When the system processes the import
    Then 3 users should be registered
```

Implementation:

```typescript
import { DataTable } from '@cucumber/cucumber';

Given('the following users exist:', async (table: DataTable) => {
  const users = table.hashes(); // Returns array of { email, role, status }
  for (const userData of users) {
    await userService.create(userData);
  }
});

Then('{int} users should be registered', async (count: number) => {
  const total = await userRepo.count();
  expect(total).to.equal(count);
});
```

## Running BDD Tests

Install Cucumber:
```bash
npm install --save-dev @cucumber/cucumber
```

Create feature files in `features/*.feature` and step definitions in `features/step_definitions/*.steps.ts`.

Run tests:
```bash
npx cucumber-js
```

Or with tags to run specific scenarios:
```bash
npx cucumber-js --tags "@smoke"
```

Tag your scenarios:
```gherkin
@smoke @critical
Scenario: Happy path checkout
  Given a cart with items
  ...
```

## Why BDD?

- **Business alignment**: Non-technical stakeholders can read and approve tests
- **Living documentation**: Feature files describe how the system should behave
- **Reduced miscommunication**: Everyone agrees on requirements before coding
- **Traceability**: Link requirements to test automation
