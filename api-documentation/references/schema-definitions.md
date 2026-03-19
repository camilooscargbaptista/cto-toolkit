# Schema Definitions and Reusable Components

Reference for common schema patterns and error responses in OpenAPI 3.1.0.

## Request and Response Schemas

### CreatePaymentRequest

```yaml
CreatePaymentRequest:
  type: object
  required: [amount_cents, currency, method, customer_id]
  properties:
    amount_cents:
      type: integer
      minimum: 1
      description: |
        Payment amount in cents (e.g., 15000 = R$150.00).
        Use integers to avoid floating-point precision issues.
      example: 15000

    currency:
      type: string
      enum: [BRL, USD, EUR, GBP]
      description: ISO 4217 currency code
      example: "BRL"

    method:
      type: string
      enum: [credit_card, debit_card, pix, boleto]
      description: |
        Payment method:
        - `credit_card` — Visa, Mastercard, Amex
        - `debit_card` — Debit card (if stored)
        - `pix` — Brazil instant payment system
        - `boleto` — Brazil bank slip
      example: "credit_card"

    customer_id:
      type: string
      pattern: "^cus_[a-zA-Z0-9_-]+$"
      minLength: 4
      maxLength: 50
      description: Unique customer identifier from the Customer Service
      example: "cus_abc123"

    description:
      type: string
      maxLength: 255
      description: Human-readable description of the payment (e.g., order details, invoice number)
      example: "Order #1234 - March invoice"

    metadata:
      type: object
      additionalProperties:
        type: string
      maxProperties: 50
      description: |
        Arbitrary key-value pairs for your use. Not processed by the API.
        Useful for tracking order IDs, subscription details, user tags, etc.
      example:
        order_id: "ord_1234"
        subscription_id: "sub_5678"
        internal_user_id: "usr_app123"
```

### Payment

Full payment resource with all possible fields.

```yaml
Payment:
  type: object
  required: [id, status, amount_cents, currency, customer_id, created_at, updated_at]
  properties:
    id:
      type: string
      pattern: "^pay_[a-zA-Z0-9_-]+$"
      description: Unique payment identifier (generated server-side)
      example: "pay_xyz789"

    status:
      type: string
      enum: [pending, processing, approved, declined, refunded, cancelled, expired]
      description: |
        Current payment status. Transitions are unidirectional:
        - `pending` — Created, awaiting processing (initial state)
        - `processing` — Being processed by payment provider
        - `approved` — Successfully charged; funds are captured
        - `declined` — Rejected by provider, bank, or fraud detection
        - `refunded` — Fully refunded to customer
        - `cancelled` — Cancelled by merchant or timeout before processing
        - `expired` — Timed out waiting for payment method authorization (e.g., boleto expiry)
      example: "approved"

    amount_cents:
      type: integer
      minimum: 1
      description: Amount in cents
      example: 15000

    currency:
      type: string
      enum: [BRL, USD, EUR, GBP]
      example: "BRL"

    method:
      type: string
      enum: [credit_card, debit_card, pix, boleto]
      example: "credit_card"

    customer_id:
      type: string
      example: "cus_abc123"

    description:
      type: string
      example: "Order #1234"

    metadata:
      type: object
      additionalProperties:
        type: string
      example:
        order_id: "ord_1234"

    error:
      $ref: '#/components/schemas/PaymentError'

    created_at:
      type: string
      format: date-time
      description: ISO 8601 timestamp when payment was created
      example: "2026-03-18T14:30:00Z"

    updated_at:
      type: string
      format: date-time
      description: ISO 8601 timestamp of last status change
      example: "2026-03-18T14:35:22Z"
```

### PaymentError

Details about a declined or failed payment.

```yaml
PaymentError:
  type: object
  properties:
    code:
      type: string
      description: |
        Machine-readable error code:
        - `insufficient_funds` — Card has insufficient balance
        - `card_expired` — Card expiration date has passed
        - `invalid_cvv` — CVV verification failed
        - `fraud_detected` — Blocked by fraud detection
        - `provider_error` — Payment provider returned error
      example: "insufficient_funds"

    message:
      type: string
      description: Human-readable error explanation
      example: "The card ending in 4242 has insufficient funds"

    decline_reason:
      type: string
      description: Decline reason from payment provider (if available)
      example: "nsf"
```

## Problem Detail (RFC 7807)

Standard error response format used across all endpoints.

```yaml
ProblemDetail:
  type: object
  required: [type, title, status]
  properties:
    type:
      type: string
      format: uri
      description: |
        URI identifying the problem type. Use a stable URL that humans can visit
        to learn more about this error. For example:
        https://api.company.com/errors/insufficient-funds
      example: "https://api.company.com/errors/insufficient-funds"

    title:
      type: string
      description: Short human-readable summary (should not change per occurrence)
      example: "Insufficient Funds"

    status:
      type: integer
      description: HTTP status code (for context in non-HTTP contexts)
      example: 422

    detail:
      type: string
      description: |
        Human-readable explanation specific to this occurrence.
        Include actionable information the client can use to resolve the issue.
      example: "The card ending in 4242 has insufficient funds for R$150.00"

    instance:
      type: string
      format: uri
      description: |
        URI identifying this specific occurrence (e.g., link to error logs or request ID).
        Useful for debugging and support requests.
      example: "/errors/req_xyz123"

    errors:
      type: array
      description: Validation errors (used in 400 responses)
      items:
        type: object
        properties:
          field:
            type: string
            example: "amount_cents"
          message:
            type: string
            example: "must be greater than 0"
          constraint:
            type: string
            description: Name of the validation rule that failed
            example: "minimum"
```

## Reusable Response Components

Define error responses once and reference them across all endpoints.

### BadRequest (400)

Invalid request parameters or malformed JSON.

```yaml
BadRequest:
  description: Invalid request parameters
  content:
    application/json:
      schema:
        $ref: '#/components/schemas/ProblemDetail'
      example:
        type: "https://api.company.com/errors/validation"
        title: "Validation Error"
        status: 400
        detail: "One or more fields are invalid"
        instance: "/errors/req_abc123"
        errors:
          - field: "amount_cents"
            message: "must be greater than 0"
            constraint: "minimum"
          - field: "currency"
            message: "must be one of: BRL, USD, EUR, GBP"
            constraint: "enum"
```

### Unauthorized (401)

Missing or invalid authentication token.

```yaml
Unauthorized:
  description: Missing or invalid authentication
  content:
    application/json:
      schema:
        $ref: '#/components/schemas/ProblemDetail'
      example:
        type: "https://api.company.com/errors/unauthorized"
        title: "Unauthorized"
        status: 401
        detail: "Authorization header is missing or token is invalid"
        instance: "/errors/req_def456"
```

### UnprocessableEntity (422)

Request is valid but violates a business rule.

```yaml
UnprocessableEntity:
  description: Request is valid but cannot be processed due to business rule violation
  content:
    application/json:
      schema:
        $ref: '#/components/schemas/ProblemDetail'
      example:
        type: "https://api.company.com/errors/insufficient-funds"
        title: "Insufficient Funds"
        status: 422
        detail: "The card ending in 4242 has insufficient funds for R$150.00"
        instance: "/errors/pay_xyz789"
```

### RateLimited (429)

Too many requests in the rate limit window.

```yaml
RateLimited:
  description: Rate limit exceeded. Retry after the specified duration.
  headers:
    Retry-After:
      schema:
        type: integer
      description: Number of seconds to wait before retrying
      example: 30
    X-RateLimit-Limit:
      schema:
        type: integer
      description: Maximum requests allowed per window
      example: 100
    X-RateLimit-Remaining:
      schema:
        type: integer
      description: Requests remaining in current window
      example: 0
    X-RateLimit-Reset:
      schema:
        type: integer
      description: Unix timestamp when limit resets
      example: 1710768630
  content:
    application/json:
      schema:
        $ref: '#/components/schemas/ProblemDetail'
      example:
        type: "https://api.company.com/errors/rate-limit-exceeded"
        title: "Rate Limit Exceeded"
        status: 429
        detail: "You have exceeded the rate limit of 100 requests per minute. Please retry after 30 seconds."
        instance: "/errors/req_ghi789"
```

## Usage Example

In your endpoint definitions, reference these components:

```yaml
paths:
  /payments:
    post:
      responses:
        '400':
          $ref: '#/components/responses/BadRequest'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '422':
          $ref: '#/components/responses/UnprocessableEntity'
        '429':
          $ref: '#/components/responses/RateLimited'
```

This approach keeps your OpenAPI spec DRY and ensures consistent error handling across all endpoints.
