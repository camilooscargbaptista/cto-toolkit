# OpenAPI 3.1.0 Specification Example

Complete OpenAPI specification with realistic examples for a Payment Service API.

## OpenAPI Structure and Info Section

```yaml
openapi: 3.1.0
info:
  title: Payment Service API
  description: |
    Manages payment processing, refunds, and transaction history.

    ## Authentication
    All endpoints require a Bearer token in the Authorization header.
    Tokens are obtained via the Auth Service (`POST /auth/token`).

    Example:
    ```
    Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
    ```

    ## Rate Limiting
    - Standard: 100 requests/minute per API key
    - Burst: 200 requests/minute (10-second window)
    - Rate limit info in response headers:
      - `X-RateLimit-Limit`: Maximum requests allowed
      - `X-RateLimit-Remaining`: Requests remaining in current window
      - `X-RateLimit-Reset`: Unix timestamp when limit resets

    ## Pagination
    List endpoints use cursor-based pagination:
    - `cursor`: Pagination cursor (opaque string, provided in previous response)
    - `limit`: Number of items per page (1–100, default 20)

    Example:
    ```
    GET /payments?limit=20&cursor=eyJvZmZzZXQiOjIwfQ==
    ```

    ## Error Format
    All errors follow RFC 7807 (Problem Details for HTTP APIs).
    See schema definitions for `ProblemDetail` object structure.

  version: 2.1.0
  contact:
    name: Platform Team
    email: platform@company.com
    url: https://docs.company.com/support

servers:
  - url: https://api.company.com/v2
    description: Production
  - url: https://api.staging.company.com/v2
    description: Staging
  - url: http://localhost:3000/v2
    description: Local development

tags:
  - name: Payments
    description: Payment processing and management
  - name: Refunds
    description: Refund processing and management
  - name: Transactions
    description: Transaction history and reporting
  - name: Customers
    description: Customer profile management
```

## Endpoint Documentation Example: POST /payments

Complete example of a fully documented endpoint with idempotency, multiple request examples, and all response codes.

```yaml
paths:
  /payments:
    post:
      operationId: createPayment
      tags: [Payments]
      summary: Create a new payment
      description: |
        Initiates a payment processing request. The payment is created in `pending` status and processed asynchronously.

        **Processing Flow:**
        1. Request is validated
        2. Payment created in `pending` status
        3. Payment provider is contacted asynchronously
        4. Status updates via webhook or poll with `GET /payments/{id}`

        **Idempotency:** Include an `Idempotency-Key` header to safely retry requests without creating duplicate payments. Keys are valid for 24 hours after first use.

        **Webhooks:** Subscribe to `payment.created`, `payment.approved`, `payment.declined` events via the Webhooks API.

      parameters:
        - name: Idempotency-Key
          in: header
          required: true
          description: |
            Unique key for idempotent requests. Use a UUID v4 or any unique string.
            If a request with the same key is replayed, the original response is returned.
            Keys are valid for 24 hours.
          schema:
            type: string
            format: uuid
            example: "550e8400-e29b-41d4-a716-446655440000"

      requestBody:
        required: true
        description: Payment details and method-specific configuration
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreatePaymentRequest'
            examples:
              credit_card:
                summary: Credit card payment (happy path)
                value:
                  amount_cents: 15000
                  currency: "BRL"
                  method: "credit_card"
                  customer_id: "cus_abc123"
                  description: "Order #1234"
                  metadata:
                    order_id: "ord_1234"
                    subscription_id: "sub_5678"

              pix:
                summary: PIX payment (Brazil instant payment)
                value:
                  amount_cents: 5000
                  currency: "BRL"
                  method: "pix"
                  customer_id: "cus_xyz789"
                  description: "Instant transfer"

              recurring:
                summary: Recurring subscription charge
                value:
                  amount_cents: 29900
                  currency: "BRL"
                  method: "credit_card"
                  customer_id: "cus_rec001"
                  metadata:
                    subscription_id: "sub_monthly_pro"
                    billing_cycle: 1

      responses:
        '201':
          description: Payment created successfully. Check webhooks or poll `GET /payments/{id}` for processing result.
          headers:
            Location:
              schema:
                type: string
              description: URL of the created payment resource
              example: "/payments/pay_xyz789"
            X-Request-Id:
              schema:
                type: string
              description: Unique request identifier for debugging
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Payment'
              example:
                id: "pay_xyz789"
                status: "pending"
                amount_cents: 15000
                currency: "BRL"
                method: "credit_card"
                customer_id: "cus_abc123"
                description: "Order #1234"
                created_at: "2026-03-18T14:30:00Z"
                updated_at: "2026-03-18T14:30:00Z"

        '400':
          $ref: '#/components/responses/BadRequest'

        '401':
          $ref: '#/components/responses/Unauthorized'

        '409':
          description: Idempotency conflict — a different request was made with the same `Idempotency-Key` header
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ProblemDetail'
              example:
                type: "https://api.company.com/errors/idempotency-conflict"
                title: "Idempotency Conflict"
                status: 409
                detail: "A different request was made with the same Idempotency-Key. Please use a new key."
                instance: "/payments"

        '422':
          $ref: '#/components/responses/UnprocessableEntity'

        '429':
          $ref: '#/components/responses/RateLimited'

        '500':
          description: Internal server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ProblemDetail'
              example:
                type: "https://api.company.com/errors/internal-error"
                title: "Internal Server Error"
                status: 500
                detail: "An unexpected error occurred. Please contact support with request ID xyz123."
                instance: "/payments"

  /payments/{id}:
    get:
      operationId: getPayment
      tags: [Payments]
      summary: Retrieve a payment by ID
      description: Returns the current state of a payment, including status and any error information.
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
            pattern: "^pay_[a-zA-Z0-9]+$"
          example: "pay_xyz789"
      responses:
        '200':
          description: Payment details
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Payment'
        '404':
          description: Payment not found
```

## Common Patterns

### Pagination Response
```yaml
components:
  schemas:
    PaymentList:
      type: object
      properties:
        items:
          type: array
          items:
            $ref: '#/components/schemas/Payment'
        cursor:
          type: string
          description: Cursor for next page (null if no more results)
          example: "eyJvZmZzZXQiOjIwfQ=="
        limit:
          type: integer
          example: 20
```

### Webhook Event
```yaml
    WebhookEvent:
      type: object
      properties:
        id:
          type: string
          example: "evt_abc123"
        type:
          type: string
          enum: [payment.created, payment.approved, payment.declined, payment.refunded]
        timestamp:
          type: string
          format: date-time
        data:
          $ref: '#/components/schemas/Payment'
```
