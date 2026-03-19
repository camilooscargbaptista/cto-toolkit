# Java Patterns & Anti-Patterns Reference

## Critical Checks for Java

### 1. Exception Handling
**Why it matters:** Broad exception catching masks real bugs and makes debugging impossible.

**What to check:**
- No catching `Exception` or `Throwable` broadly; catch specific exceptions
- No swallowing exceptions with empty catch blocks
- Checked exceptions properly declared in method signature or wrapped
- Logging includes exception stack trace, not just message
- Recovery logic is correct (don't retry on non-recoverable errors)

### 2. Thread Safety in Spring Beans
**Why it matters:** Spring beans are singletons by default. Mutable state = data races.

**What to check:**
- Shared mutable fields have proper synchronization
- Service beans are stateless or use ThreadLocal carefully
- Database connections from pool are used in try-finally/try-with-resources
- Race conditions in lazy initialization checked (e.g., double-checked locking)
- No storing request-scoped data in bean fields

### 3. Resource Management
**Why it matters:** Unclosed streams, connections, and file handles exhaust system resources.

**What to check:**
- All `Closeable` resources use try-with-resources or try-finally
- No manual `.close()` calls that might be skipped on exception
- Connection pooling properly configured (HikariCP recommended)
- File/stream operations don't leak on early return

### 4. Null Safety
**Why it matters:** NPE crashes are the most common production failure.

**What to check:**
- `Optional<T>` used instead of returning null
- `@Nullable` / `@NonNull` annotations present and respected
- No dereferencing without null check
- Factory methods return `Optional` not null
- Proper use of `.orElse()`, `.orElseThrow()`, not `.get()`

### 5. Transaction Boundaries
**Why it matters:** Transactions in wrong layer = lost data or deadlocks.

**What to check:**
- `@Transactional` at service layer, not controller
- Read-only transactions marked with `readOnly = true`
- Lazy-loading collection access protected by transaction
- No nested service calls that both start transactions
- Proper rollback on exception (Spring rolls back by default)

### 6. Spring Dependency Injection Correctness
**Why it matters:** Wrong injection style = hidden dependencies and hard-to-test code.

**What to check:**
- Constructor injection preferred (easier testing, immutable)
- No `@Autowired` field injection (untestable, NullPointerException risk)
- No setter injection mixing with constructor
- Circular dependencies resolved or eliminated
- Optional dependencies marked with `required = false`

---

## Code Examples

### Anemic Domain Model vs Rich Domain Model

```java
// ❌ ANTI-PATTERN: Anemic domain model
public class Order {
    private BigDecimal total;
    private List<LineItem> items;

    public BigDecimal getTotal() { return total; }
    public void setTotal(BigDecimal total) { this.total = total; }
    public List<LineItem> getItems() { return items; }
    public void setItems(List<LineItem> items) { this.items = items; }
}

@Service
public class OrderService {
    public void applyDiscount(Order order, BigDecimal discount) {
        if (discount.compareTo(order.getTotal()) > 0) {
            throw new InvalidDiscountException();
        }
        // Business logic leaks into service
        order.setTotal(order.getTotal().subtract(discount));
    }

    public void addItem(Order order, LineItem item) {
        order.getItems().add(item);
        order.setTotal(order.getTotal().add(item.getPrice()));
    }
}

// ✅ PATTERN: Rich domain model
public class Money {
    private final BigDecimal amount;
    private final Currency currency;

    public Money(BigDecimal amount, Currency currency) {
        if (amount.scale() != currency.getDefaultFractionDigits()) {
            throw new InvalidMoneyException("Currency scale mismatch");
        }
        this.amount = amount;
        this.currency = currency;
    }

    public Money subtract(Money other) {
        if (!this.currency.equals(other.currency)) {
            throw new CurrencyMismatchException();
        }
        return new Money(this.amount.subtract(other.amount), this.currency);
    }

    public boolean greaterThanOrEqual(Money other) {
        return this.amount.compareTo(other.amount) >= 0;
    }
}

public class Discount {
    private final Money amount;
    private final String code;

    public Money applyTo(Money orderTotal) {
        if (!orderTotal.greaterThanOrEqual(this.amount)) {
            throw new InsufficientBalanceException();
        }
        return orderTotal.subtract(this.amount);
    }
}

public class Order {
    private final List<LineItem> items = new ArrayList<>();
    private Money total;

    public void addItem(LineItem item) {
        items.add(item);
        this.total = total.add(item.getPrice());
    }

    public void applyDiscount(Discount discount) {
        this.total = discount.applyTo(this.total); // Domain logic encapsulated
    }

    public Money getTotal() { return total; } // Immutable return
}
```

### Exception Handling

```java
// ❌ ANTI-PATTERN: Swallowing exceptions, broad catches
try {
    database.executeQuery(sql);
} catch (Exception e) {
    // Lost the exception!
}

try {
    paymentGateway.charge(amount);
} catch (Throwable t) {
    // Catches everything, including OutOfMemoryError
}

// ❌ ANTI-PATTERN: Retrying on non-recoverable errors
try {
    validateCreditCard(card);
} catch (InvalidCardException e) {
    Thread.sleep(1000);
    validateCreditCard(card); // Invalid card won't become valid
}

// ✅ PATTERN: Specific exceptions with proper recovery
try {
    database.executeQuery(sql);
} catch (SQLException e) {
    logger.error("Database error during query", e);
    throw new DataAccessException("Failed to execute query", e);
} catch (TimeoutException e) {
    logger.warn("Query timeout, retrying...");
    // Retry with backoff for timeout only
    return retryWithBackoff(() -> database.executeQuery(sql), 3);
}

try {
    paymentGateway.charge(amount);
} catch (PaymentGatewayException e) {
    logger.error("Payment gateway error", e);
    throw new PaymentProcessingException(e.getMessage(), e);
} catch (InvalidCardException e) {
    // Don't retry—validation failed
    throw new InvalidPaymentMethodException("Card invalid", e);
}
```

### Thread Safety in Spring Beans

```java
// ❌ ANTI-PATTERN: Mutable state in singleton bean
@Service
public class UserService {
    private Map<Integer, User> cache = new HashMap<>(); // Data race!

    public User findById(int id) {
        if (!cache.containsKey(id)) {
            cache.put(id, loadFromDb(id)); // Non-atomic
        }
        return cache.get(id);
    }
}

// ❌ ANTI-PATTERN: Field injection + request scope in singleton
@Service
public class ReportService {
    @Autowired
    private HttpServletRequest request; // Wrong scope!

    public String generateReport() {
        return request.getHeader("X-User-Id"); // May be wrong user's request
    }
}

// ✅ PATTERN: Use ConcurrentHashMap or inject into method
@Service
public class UserService {
    private final ConcurrentHashMap<Integer, User> cache = new ConcurrentHashMap<>();

    public User findById(int id) {
        return cache.computeIfAbsent(id, k -> loadFromDb(k)); // Atomic
    }
}

// ✅ PATTERN: Request scope via method parameter
@Service
public class ReportService {
    public String generateReport(HttpServletRequest request) {
        return request.getHeader("X-User-Id");
    }
}

// ✅ PATTERN: Use RequestScope bean or ThreadLocal carefully
@Service
public class AuditService {
    private static final ThreadLocal<String> userId = new ThreadLocal<>();

    public void setUserId(String id) {
        userId.set(id);
    }

    public String getUserId() {
        String id = userId.get();
        if (id == null) throw new AuditContextException("userId not set");
        return id;
    }

    public void clear() {
        userId.remove(); // Must clear in filter after request
    }
}
```

### Resource Management

```java
// ❌ ANTI-PATTERN: File not closed on exception
public String readFile(String path) throws IOException {
    FileReader reader = new FileReader(path);
    BufferedReader br = new BufferedReader(reader);
    StringBuilder result = new StringBuilder();
    String line;
    while ((line = br.readLine()) != null) {
        result.append(line);
    }
    br.close(); // Never reached if readLine() throws
    return result.toString();
}

// ✅ PATTERN: Try-with-resources
public String readFile(String path) throws IOException {
    try (BufferedReader br = new BufferedReader(new FileReader(path))) {
        StringBuilder result = new StringBuilder();
        String line;
        while ((line = br.readLine()) != null) {
            result.append(line);
        }
        return result.toString();
    } // AutoCloseable.close() called automatically
}

// ❌ ANTI-PATTERN: Connection not properly pooled
public User findUser(int id) {
    Connection conn = DriverManager.getConnection("jdbc:mysql://...", user, pass);
    PreparedStatement stmt = conn.prepareStatement("SELECT * FROM users WHERE id = ?");
    stmt.setInt(1, id);
    ResultSet rs = stmt.executeQuery();
    // No cleanup!
    return mapResult(rs);
}

// ✅ PATTERN: Connection pooling (HikariCP)
@Configuration
public class DataSourceConfig {
    @Bean
    public DataSource dataSource() {
        HikariConfig config = new HikariConfig();
        config.setJdbcUrl("jdbc:mysql://...");
        config.setMaximumPoolSize(20);
        config.setConnectionTimeout(30000);
        return new HikariDataSource(config);
    }
}

@Service
public class UserService {
    @Autowired
    private DataSource dataSource;

    public User findUser(int id) {
        try (Connection conn = dataSource.getConnection();
             PreparedStatement stmt = conn.prepareStatement("SELECT * FROM users WHERE id = ?")) {
            stmt.setInt(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                return mapResult(rs);
            }
        } catch (SQLException e) {
            throw new DataAccessException("Failed to find user", e);
        }
    }
}
```

### Null Safety with Optional

```java
// ❌ ANTI-PATTERN: Returning null
public User findById(int id) {
    return userRepository.findById(id).orElse(null);
}

// Caller must check for null
User user = findById(123);
if (user != null) {
    System.out.println(user.getName());
}

// ❌ ANTI-PATTERN: Using .get() without checking
User user = userRepository.findById(123).get(); // NPE if not found

// ✅ PATTERN: Return Optional
public Optional<User> findById(int id) {
    return userRepository.findById(id);
}

// Caller handles absence explicitly
userRepository.findById(123)
    .ifPresentOrElse(
        user -> logger.info("Found: " + user.getName()),
        () -> logger.warn("User not found")
    );

// ✅ PATTERN: Use orElseThrow for required values
public User findByIdOrThrow(int id) {
    return userRepository.findById(id)
        .orElseThrow(() -> new UserNotFoundException("User not found: " + id));
}
```

---

## Spring-Specific Patterns & Anti-Patterns

| Anti-Pattern | Risk | Fix |
|---|---|---|
| Field injection with `@Autowired` | Hard to test, NPE risk | Use constructor injection |
| `@Transactional` in controller | Transaction commits before response sent | Move to service layer |
| Lazy loading without transaction | LazyInitializationException | Fetch collections in service with active transaction |
| No `readOnly = true` on queries | Unnecessary write locks | Mark read-only methods with `readOnly = true` |
| Catching `Exception` broadly | Lost debugging info | Catch specific exceptions |
| Manual try-finally instead of try-with-resources | Resources leak on exception | Use try-with-resources for Closeable |
| No circuit breaker on external calls | Cascading failures | Use Spring Cloud Circuit Breaker |
| Missing `@Transactional` boundary | Lost atomicity | Add explicit transaction boundaries |
| Optional `.get()` without check | NPE crash | Use `.orElse()`, `.orElseThrow()`, or `.ifPresent()` |
