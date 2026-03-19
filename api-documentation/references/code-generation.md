# Generating API Documentation from Code

Best practice: Generate OpenAPI specs from code annotations (single source of truth), then enrich with human-written guides, examples, and tutorials.

## NestJS with @nestjs/swagger

NestJS provides decorator-based documentation that automatically generates OpenAPI specs.

### Controller Example

```typescript
import {
  Controller,
  Post,
  Get,
  Param,
  Body,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiHeader, ApiParam } from '@nestjs/swagger';
import { PaymentService } from './payment.service';
import { CreatePaymentDto } from './dto/create-payment.dto';
import { PaymentDto } from './dto/payment.dto';

@ApiTags('Payments')
@Controller('payments')
export class PaymentController {
  constructor(private readonly paymentService: PaymentService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Create a new payment',
    description: 'Initiates a payment processing request. Use Idempotency-Key header to safely retry.',
  })
  @ApiHeader({
    name: 'Idempotency-Key',
    required: true,
    description: 'Unique idempotency key (UUID v4). Valid for 24 hours.',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 201,
    description: 'Payment created successfully',
    type: PaymentDto,
  })
  @ApiResponse({
    status: 400,
    description: 'Validation error',
  })
  @ApiResponse({
    status: 422,
    description: 'Business rule violation (e.g., insufficient funds)',
  })
  @ApiResponse({
    status: 429,
    description: 'Rate limit exceeded',
  })
  async create(
    @Body() createPaymentDto: CreatePaymentDto,
  ): Promise<PaymentDto> {
    return this.paymentService.create(createPaymentDto);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Retrieve a payment by ID' })
  @ApiParam({
    name: 'id',
    description: 'Payment identifier',
    example: 'pay_xyz789',
  })
  @ApiResponse({
    status: 200,
    description: 'Payment details',
    type: PaymentDto,
  })
  @ApiResponse({
    status: 404,
    description: 'Payment not found',
  })
  async findOne(@Param('id') id: string): Promise<PaymentDto> {
    return this.paymentService.findOne(id);
  }
}
```

### DTO Example

Data Transfer Objects define request/response schemas. @ApiProperty decorators automatically generate OpenAPI schemas.

```typescript
import {
  IsInt,
  IsString,
  IsEnum,
  Min,
  MaxLength,
  IsOptional,
  IsObject,
  MinLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreatePaymentDto {
  @ApiProperty({
    description: 'Amount in cents (e.g., 15000 = R$150.00)',
    minimum: 1,
    example: 15000,
  })
  @IsInt()
  @Min(1)
  amount_cents: number;

  @ApiProperty({
    description: 'ISO 4217 currency code',
    enum: ['BRL', 'USD', 'EUR', 'GBP'],
    example: 'BRL',
  })
  @IsEnum(['BRL', 'USD', 'EUR', 'GBP'])
  currency: string;

  @ApiProperty({
    description: 'Payment method',
    enum: ['credit_card', 'debit_card', 'pix', 'boleto'],
    example: 'credit_card',
  })
  @IsEnum(['credit_card', 'debit_card', 'pix', 'boleto'])
  method: string;

  @ApiProperty({
    description: 'Customer identifier',
    minLength: 4,
    maxLength: 50,
    example: 'cus_abc123',
  })
  @IsString()
  @MinLength(4)
  @MaxLength(50)
  customer_id: string;

  @ApiPropertyOptional({
    description: 'Human-readable description',
    maxLength: 255,
    example: 'Order #1234',
  })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  description?: string;

  @ApiPropertyOptional({
    description: 'Arbitrary key-value metadata',
    example: { order_id: 'ord_1234', subscription_id: 'sub_5678' },
  })
  @IsOptional()
  @IsObject()
  metadata?: Record<string, string>;
}

export class PaymentDto {
  @ApiProperty({
    description: 'Payment identifier',
    example: 'pay_xyz789',
  })
  id: string;

  @ApiProperty({
    description: 'Current payment status',
    enum: ['pending', 'processing', 'approved', 'declined', 'refunded', 'cancelled', 'expired'],
    example: 'approved',
  })
  status: string;

  @ApiProperty({ example: 15000 })
  amount_cents: number;

  @ApiProperty({ example: 'BRL' })
  currency: string;

  @ApiProperty({ example: 'credit_card' })
  method: string;

  @ApiProperty({ example: 'cus_abc123' })
  customer_id: string;

  @ApiPropertyOptional()
  description?: string;

  @ApiPropertyOptional()
  metadata?: Record<string, string>;

  @ApiProperty({
    description: 'ISO 8601 creation timestamp',
    example: '2026-03-18T14:30:00Z',
  })
  created_at: string;

  @ApiProperty({
    description: 'ISO 8601 last updated timestamp',
    example: '2026-03-18T14:35:22Z',
  })
  updated_at: string;
}
```

### Bootstrap Configuration

Generate the OpenAPI spec at startup:

```typescript
import { NestFactory } from '@nestjs/core';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  const config = new DocumentBuilder()
    .setTitle('Payment Service API')
    .setDescription(
      'Manages payment processing, refunds, and transaction history.',
    )
    .setVersion('2.1.0')
    .addServer('https://api.company.com/v2', 'Production')
    .addServer('https://api.staging.company.com/v2', 'Staging')
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api', app, document);

  await app.listen(3000);
}

bootstrap();
```

The OpenAPI spec is now available at `GET /api` (Swagger UI) and `GET /api-json` (raw OpenAPI JSON).

## Spring Boot with springdoc-openapi

Spring Boot integrates OpenAPI documentation through Maven/Gradle dependencies.

### Maven Dependency

```xml
<dependency>
    <groupId>org.springdoc</groupId>
    <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
    <version>2.0.2</version>
</dependency>
```

### Controller Example

```java
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

@RestController
@RequestMapping("/payments")
@Tag(name = "Payments", description = "Payment processing and management")
public class PaymentController {

    private final PaymentService paymentService;

    public PaymentController(PaymentService paymentService) {
        this.paymentService = paymentService;
    }

    @PostMapping
    @Operation(
        summary = "Create a new payment",
        description = "Initiates a payment processing request in pending status. "
            + "Use Idempotency-Key header to safely retry without creating duplicates."
    )
    @ApiResponses(value = {
        @ApiResponse(
            responseCode = "201",
            description = "Payment created successfully",
            content = @Content(mediaType = "application/json")
        ),
        @ApiResponse(
            responseCode = "400",
            description = "Validation error"
        ),
        @ApiResponse(
            responseCode = "422",
            description = "Business rule violation"
        ),
        @ApiResponse(
            responseCode = "429",
            description = "Rate limit exceeded"
        )
    })
    public ResponseEntity<PaymentResponse> createPayment(
        @Valid @RequestBody CreatePaymentRequest request,
        @RequestHeader("Idempotency-Key") String idempotencyKey
    ) {
        PaymentResponse response = paymentService.create(request, idempotencyKey);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Retrieve a payment by ID")
    @ApiResponses(value = {
        @ApiResponse(
            responseCode = "200",
            description = "Payment details",
            content = @Content(mediaType = "application/json")
        ),
        @ApiResponse(
            responseCode = "404",
            description = "Payment not found"
        )
    })
    public ResponseEntity<PaymentResponse> getPayment(
        @Parameter(description = "Payment ID", example = "pay_xyz789")
        @PathVariable String id
    ) {
        PaymentResponse response = paymentService.findById(id);
        return ResponseEntity.ok(response);
    }
}
```

### DTO Example (Java Records)

```java
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;

@Schema(description = "Payment creation request")
public record CreatePaymentRequest(
    @Schema(
        description = "Amount in cents (e.g., 15000 = R$150.00)",
        minimum = "1",
        example = "15000"
    )
    @Positive
    Integer amount_cents,

    @Schema(
        description = "ISO 4217 currency code",
        allowableValues = {"BRL", "USD", "EUR", "GBP"},
        example = "BRL"
    )
    @Pattern(regexp = "^(BRL|USD|EUR|GBP)$")
    String currency,

    @Schema(
        description = "Payment method",
        allowableValues = {"credit_card", "debit_card", "pix", "boleto"},
        example = "credit_card"
    )
    String method,

    @Schema(
        description = "Customer identifier",
        minLength = 4,
        maxLength = 50,
        example = "cus_abc123"
    )
    @Size(min = 4, max = 50)
    String customer_id,

    @Schema(
        description = "Human-readable description",
        maxLength = 255,
        example = "Order #1234"
    )
    @Size(max = 255)
    String description,

    @Schema(description = "Arbitrary metadata")
    @Size(max = 50)
    Map<String, String> metadata
) {}

@Schema(description = "Payment resource")
public record PaymentResponse(
    @Schema(description = "Payment identifier", example = "pay_xyz789")
    String id,

    @Schema(
        description = "Current payment status",
        allowableValues = {"pending", "processing", "approved", "declined", "refunded", "cancelled", "expired"},
        example = "approved"
    )
    String status,

    Integer amount_cents,
    String currency,
    String method,
    String customer_id,
    String description,
    Map<String, String> metadata,

    @Schema(description = "ISO 8601 creation timestamp", example = "2026-03-18T14:30:00Z")
    String created_at,

    @Schema(description = "ISO 8601 last updated timestamp", example = "2026-03-18T14:35:22Z")
    String updated_at
) {}
```

### Application Configuration

```yaml
# application.yml
springdoc:
  api-docs:
    path: /api-docs
  swagger-ui:
    path: /api
    operationsSorter: method
    tagsSorter: alpha
  info:
    title: Payment Service API
    description: Manages payment processing, refunds, and transaction history
    version: 2.1.0
    contact:
      name: Platform Team
      email: platform@company.com
```

The OpenAPI spec is available at `GET /api-docs` (JSON) and `GET /api` (Swagger UI).

## Best Practice: Code-Driven with Human Enrichment

**Single source of truth:** Generate OpenAPI specs from code annotations. This ensures specs stay in sync with implementations and reduces documentation debt.

**Add human judgment:**
1. **Guides** — Write narrative documentation explaining architectural patterns, integration flows, and design decisions
2. **Examples** — Provide realistic, copy-pasteable examples with multiple scenarios (happy path, error cases, edge cases)
3. **Tutorials** — Step-by-step integration guides for common use cases
4. **FAQ** — Anticipate and answer developer questions

Keep these human-written assets in separate files (not in code decorators) so they remain readable and maintainable.
