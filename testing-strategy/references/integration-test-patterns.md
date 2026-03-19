# Integration & E2E Test Patterns

## API Testing with Supertest

Supertest provides a fluent API for testing HTTP servers without binding to a port.

### Basic API Test

```typescript
import request from 'supertest';
import { app } from '../src/app';

describe('POST /api/orders', () => {
  it('should create an order and return 201', async () => {
    const response = await request(app)
      .post('/api/orders')
      .set('Authorization', `Bearer ${validToken}`)
      .send({
        items: [{ productId: 'prod-1', quantity: 2 }],
      });

    expect(response.status).toBe(201);
    expect(response.body.id).toBeDefined();
    expect(response.body.status).toBe('pending');

    // Verify side effects: order persisted
    const order = await orderRepo.findById(response.body.id);
    expect(order).toBeDefined();
    expect(order.items).toHaveLength(1);
  });

  it('should reject invalid authorization', async () => {
    const response = await request(app)
      .post('/api/orders')
      .set('Authorization', 'Bearer invalid_token')
      .send({ items: [] });

    expect(response.status).toBe(401);
    expect(response.body.message).toMatch(/unauthorized/i);
  });

  it('should return 400 for missing required fields', async () => {
    const response = await request(app)
      .post('/api/orders')
      .set('Authorization', `Bearer ${validToken}`)
      .send({}); // Missing 'items'

    expect(response.status).toBe(400);
    expect(response.body.errors).toContainEqual(
      expect.objectContaining({ field: 'items' })
    );
  });
});
```

### Testing Pagination

```typescript
describe('GET /api/orders', () => {
  beforeEach(async () => {
    // Create test data
    for (let i = 0; i < 25; i++) {
      await orderRepo.create({ orderId: `order-${i}`, amount: 100 });
    }
  });

  it('should return paginated results', async () => {
    const response = await request(app)
      .get('/api/orders')
      .query({ page: 1, limit: 10 });

    expect(response.status).toBe(200);
    expect(response.body.items).toHaveLength(10);
    expect(response.body.total).toBe(25);
    expect(response.body.hasNextPage).toBe(true);
  });

  it('should return empty array for out-of-range page', async () => {
    const response = await request(app)
      .get('/api/orders')
      .query({ page: 100, limit: 10 });

    expect(response.status).toBe(200);
    expect(response.body.items).toHaveLength(0);
  });
});
```

## Database Testing Best Practices

### Use Test Database

```typescript
// jest.config.js
module.exports = {
  testEnvironment: 'node',
  setupFilesAfterEnv: ['<rootDir>/tests/setup.ts'],
};

// tests/setup.ts
import { Pool } from 'pg';

export const testDb = new Pool({
  connectionString: process.env.TEST_DATABASE_URL || 'postgres://localhost/app_test',
});

// Ensure fresh database before each test suite
beforeAll(async () => {
  await testDb.query('BEGIN'); // Start transaction
});

afterEach(async () => {
  await testDb.query('ROLLBACK'); // Rollback changes
  await testDb.query('BEGIN'); // Start fresh transaction
});

afterAll(async () => {
  await testDb.query('ROLLBACK');
  await testDb.end();
});
```

### Database Query Tests

```typescript
describe('UserRepository', () => {
  it('should find user by email', async () => {
    // Setup
    const email = 'alice@example.com';
    const userId = await userRepo.create({
      email,
      name: 'Alice',
      passwordHash: 'hashed_pw',
    });

    // Act
    const user = await userRepo.findByEmail(email);

    // Assert
    expect(user.id).toBe(userId);
    expect(user.email).toBe(email);
  });

  it('should return null for non-existent user', async () => {
    const user = await userRepo.findByEmail('nonexistent@example.com');
    expect(user).toBeNull();
  });

  it('should update user attributes', async () => {
    const userId = await userRepo.create({ email: 'bob@example.com', name: 'Bob' });

    await userRepo.update(userId, { name: 'Robert' });

    const updated = await userRepo.findById(userId);
    expect(updated.name).toBe('Robert');
  });

  it('should enforce unique email constraint', async () => {
    await userRepo.create({ email: 'duplicate@example.com', name: 'User 1' });

    // Second insert with same email should fail
    await expect(
      userRepo.create({ email: 'duplicate@example.com', name: 'User 2' })
    ).rejects.toThrow(/unique constraint/i);
  });
});
```

### Testing Migrations

```typescript
describe('User table migration', () => {
  it('should have created users table with required columns', async () => {
    const result = await testDb.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'users'
      ORDER BY ordinal_position
    `);

    const columns = result.rows.reduce((acc, row) => {
      acc[row.column_name] = { type: row.data_type, nullable: row.is_nullable === 'YES' };
      return acc;
    }, {});

    expect(columns.id.type).toBe('integer');
    expect(columns.id.nullable).toBe(false);
    expect(columns.email.type).toMatch(/character/); // varchar
    expect(columns.email.nullable).toBe(false);
    expect(columns.created_at.type).toMatch(/timestamp/);
  });

  it('should support rollback', async () => {
    // Rollback migration
    await runMigration('down');

    // Verify table no longer exists
    const result = await testDb.query(`
      SELECT to_regclass('public.users')
    `);
    expect(result.rows[0].to_regclass).toBeNull();

    // Restore
    await runMigration('up');
  });
});
```

## E2E Testing with Playwright/Cypress

### When to Write E2E Tests

Write E2E tests for **critical user journeys** that cross multiple services:

- User registration → email verification → login
- Checkout flow → payment → order confirmation
- Multi-step workflows with multiple pages
- Features involving third-party integrations

### E2E Test Example (Playwright)

```typescript
import { test, expect } from '@playwright/test';

test.describe('User registration flow', () => {
  test('should register new user and send verification email', async ({ page, context }) => {
    // Navigate to signup
    await page.goto('/signup');

    // Fill form
    await page.fill('input[name="email"]', 'newuser@example.com');
    await page.fill('input[name="password"]', 'SecurePass123!');
    await page.fill('input[name="confirm"]', 'SecurePass123!');

    // Submit
    await page.click('button[type="submit"]');

    // Verify success message
    await expect(page.locator('.success-message')).toContainText('Check your email');

    // Intercept and verify email request
    const emailPromise = context.waitForEvent('request');
    const request = await emailPromise;
    expect(request.postDataJSON()).toMatchObject({
      to: 'newuser@example.com',
      template: 'verify_email',
    });
  });

  test('should validate form before submission', async ({ page }) => {
    await page.goto('/signup');

    // Leave email empty and submit
    await page.fill('input[name="password"]', 'password');
    await page.click('button[type="submit"]');

    // Verify error shown
    await expect(page.locator('[role="alert"]')).toContainText('Email is required');
  });
});
```

### E2E Anti-Patterns to Avoid

**❌ Testing everything E2E**
```typescript
// DON'T: E2E for every user action
it('should do everything', async ({ page }) => {
  // Navigate, login, create order, checkout, verify...
  // This test is slow, flaky, and hard to debug
});
```
Better: Test critical paths E2E, use unit tests for individual features.

**❌ Depending on existing data**
```typescript
// DON'T: Assume test data already exists
it('should find user Alice', async ({ page }) => {
  await page.goto('/users/alice-id-123'); // What if Alice is deleted?
});
```
Better: Create test data in beforeEach.

**❌ Using sleep/wait**
```typescript
// DON'T: Wait for arbitrary time
await page.waitForTimeout(5000);
```
Better: Use explicit waits.
```typescript
// DO: Wait for element to appear
await expect(page.locator('.order-confirmation')).toBeVisible();
```

**❌ Not cleaning up**
```typescript
// DON'T: Leave test data in database
test('should create order', async () => {
  const order = await api.post('/orders', {...});
  // Order left in database for next test
});
```
Better: Clean up in afterEach.

## E2E vs Integration vs Unit

| Type | Speed | Flakiness | When to Use |
|------|-------|-----------|------------|
| Unit | <10ms | Low | Pure logic, algorithms, domain objects |
| Integration | <5s | Low | API endpoints, database queries, service interactions |
| E2E | >10s | High | Critical user workflows, cross-system flows |

**Pyramid rule**: More unit tests, fewer E2E tests. Don't test the same behavior at multiple levels.
