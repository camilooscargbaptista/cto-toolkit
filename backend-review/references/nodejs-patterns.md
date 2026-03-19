# Node.js Patterns & Anti-Patterns Reference

## Critical Checks for Node.js

### 1. Async/Await Error Handling
**Why it matters:** Unhandled promise rejections crash the process silently or with a deprecation warning.

**What to check:**
- All promises have `.catch()` or are awaited in try/catch
- Error handlers in routes/endpoints call `next(error)` not `res.send()`
- No silent failures like `promise.catch(() => {})`

### 2. Event Loop Blocking
**Why it matters:** CPU-intensive operations freeze the entire server for all requests.

**What to check:**
- Heavy computations (crypto, compression, parsing large files) use worker threads
- No synchronous operations like `fs.readFileSync()` in request handlers
- Long-running loops have `setImmediate()` to yield control
- No blocking operations in middleware executed on every request

### 3. Memory Leaks
**Why it matters:** Production servers slowly consume memory until OOM kill.

**Common sources:**
- Unbounded caches without TTL or eviction
- Event listeners not cleaned up on object destruction
- Stream backpressure ignored (readable → writable pipe without handling pause/resume)
- Circular references in cached objects
- Connection pools that don't properly close idle connections

### 4. N+1 Query Patterns
**Why it matters:** One logical request triggers O(n) database queries, killing performance.

**ORM-specific patterns:**
- **Sequelize:** Using `.include()` or `.populate()` incorrectly; lazy-loading in loops
- **TypeORM:** Eager loading not configured; lazy relations in findOne
- **Prisma:** Missing `include` / `select` on relations

### 5. Connection Pool Management
**Why it matters:** Unpooled connections exhaust server resources; misconfigured pools cause hangs.

**What to check:**
- Pool size reasonable for workload (not too large, not too small)
- Pool min/max settings match expected concurrency
- Idle timeout configured to clean up stale connections
- Connection errors properly propagated, not silently ignored
- Pool metrics logged/monitored

### 6. Environment Variable Validation
**Why it matters:** Runtime errors in production when config is missing.

**What to check:**
- Validation happens on startup, not at first use
- All required vars checked with clear error messages
- Type coercion validated (PORT should be a number, not string)
- Sensitive values not logged

---

## Code Examples

### Callback Hell vs Clean Async

```javascript
// ❌ ANTI-PATTERN: Callback hell, mixed error handling
app.get('/users/:id', (req, res) => {
  db.query('SELECT * FROM users WHERE id = ?', [req.params.id], (err, user) => {
    if (err) res.status(500).send(err); // Missing return—will execute below
    res.json(user);

    // This still executes even on error!
    logger.info('User fetched');
  });
});

// ❌ ANTI-PATTERN: Unhandled promise rejection
app.get('/posts', async (req, res) => {
  const posts = await postService.findAll(); // If this throws, res is never sent
  res.json(posts);
});

// ✅ PATTERN: Clean async with centralized error handling
app.get('/users/:id', async (req, res, next) => {
  try {
    const user = await userService.findById(req.params.id);
    res.json(user);
  } catch (error) {
    next(error); // Delegates to centralized error handler middleware
  }
});

// ✅ PATTERN: Async/await throughout the stack
const userService = {
  async findById(id) {
    const user = await db.users.findUnique({ where: { id } });
    if (!user) throw new UserNotFoundError(id);
    return user;
  }
};

// ✅ Centralized error handler
app.use((error, req, res, next) => {
  if (error instanceof UserNotFoundError) {
    return res.status(404).json({ error: error.message });
  }
  res.status(500).json({ error: 'Internal Server Error' });
});
```

### Proper Error Handling with Centralized Handler

```javascript
// ❌ ANTI-PATTERN: No error handler, errors logged in random places
router.post('/payments', async (req, res) => {
  try {
    const charge = await stripe.charges.create(...);
  } catch (error) {
    console.log('Stripe error:', error); // No response sent!
    // Request hangs
  }
});

// ✅ PATTERN: Consistent error handling via middleware
class PaymentError extends Error {
  constructor(message, code) {
    super(message);
    this.code = code;
  }
}

router.post('/payments', async (req, res, next) => {
  try {
    const charge = await stripe.charges.create(req.body.charge);
    res.json({ id: charge.id });
  } catch (error) {
    // All errors bubble to middleware
    next(new PaymentError(error.message, 'STRIPE_ERROR'));
  }
});

// Centralized handler
app.use((error, req, res, next) => {
  if (error instanceof PaymentError) {
    logger.warn('Payment failed', { code: error.code, message: error.message });
    return res.status(400).json({ error: error.code });
  }

  logger.error('Unhandled error', { error: error.message, stack: error.stack });
  res.status(500).json({ error: 'Internal Server Error' });
});
```

### Event Loop Blocking & Worker Threads

```javascript
// ❌ ANTI-PATTERN: CPU-intensive work blocks event loop
app.post('/hash', (req, res) => {
  const hash = bcrypt.hashSync(req.body.password, 10); // Blocks for 100ms+
  res.json({ hash });
});

// ✅ PATTERN: Offload to worker thread
const { Worker } = require('worker_threads');

app.post('/hash', async (req, res, next) => {
  try {
    const hash = await hashInWorker(req.body.password);
    res.json({ hash });
  } catch (error) {
    next(error);
  }
});

function hashInWorker(password) {
  return new Promise((resolve, reject) => {
    const worker = new Worker('./hash-worker.js');
    worker.on('message', resolve);
    worker.on('error', reject);
    worker.postMessage(password);
  });
}
```

### Memory Leak: Unbounded Cache

```javascript
// ❌ ANTI-PATTERN: Cache grows forever
const userCache = new Map();

app.get('/users/:id', async (req, res, next) => {
  if (!userCache.has(req.params.id)) {
    userCache.set(req.params.id, await db.users.findUnique(...));
  }
  res.json(userCache.get(req.params.id));
});

// ✅ PATTERN: TTL-based cache with eviction
const NodeCache = require('node-cache');
const userCache = new NodeCache({ stdTTL: 600 }); // 10 min TTL

app.get('/users/:id', async (req, res, next) => {
  const cached = userCache.get(req.params.id);
  if (cached) return res.json(cached);

  const user = await db.users.findUnique(...);
  userCache.set(req.params.id, user);
  res.json(user);
});
```

### N+1 Query Pattern

```javascript
// ❌ ANTI-PATTERN: N+1 queries with Sequelize
const users = await User.findAll(); // 1 query
for (const user of users) {
  const posts = await user.getPosts(); // N queries (one per user)
}

// ✅ PATTERN: Eager loading
const users = await User.findAll({
  include: [{ association: 'posts' }] // 1 query with JOIN
});

// ✅ PATTERN: Batch loading fallback
const users = await User.findAll();
const userIds = users.map(u => u.id);
const postsByUserId = await Post.findAll({
  where: { userId: userIds }
}).then(posts =>
  posts.reduce((acc, p) => {
    acc[p.userId] = acc[p.userId] || [];
    acc[p.userId].push(p);
    return acc;
  }, {})
);
```

---

## Common Node.js Anti-Patterns & Fixes

| Anti-Pattern | Risk | Fix |
|---|---|---|
| Unhandled promise rejections | Process crash | Always `await` in try/catch or `.catch()` |
| Blocking crypto in middleware | Slow all requests | Use `bcrypt.hash()` (async), not `hashSync()` |
| No environment validation | Runtime failures | Validate all env vars on startup with schema |
| Unbounded caches | Memory leak | Use node-cache or Redis with TTL |
| Stream backpressure ignored | Buffer overflow | Handle `pipe('readable')` and `drain()` events |
| Sequelize `.include()` in a loop | O(n) queries | Eager load in parent query |
| Connection not closed on error | Resource leak | Use try/finally or connection pooling |
| `catch () => {}` silently fails | Lost errors | Log or rethrow in catch blocks |
| No correlation IDs | Hard to debug | Add request ID middleware |
| Blocking loops | Event loop stall | Use `setImmediate()` for long loops |
