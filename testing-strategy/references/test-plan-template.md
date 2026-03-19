# QA Test Plan Template

## Test Plan: [Feature Name]

Use this template to structure QA testing for a feature. Fill in each section based on the feature scope.

### Scope

**What's being tested:**
- List the features and user flows included in this test plan
- Example: User registration flow, email verification, login

**What's NOT being tested:**
- Out of scope items, known limitations
- Example: Third-party email provider availability

### Test Scenarios

Organize tests into categories: happy paths, edge cases, error cases, performance, and security.

#### 1. Happy Path (Main Success Scenario)

```
Scenario 1.1: User completes registration with valid data
  Steps:
    1. Navigate to /signup
    2. Enter email: test@example.com
    3. Enter password: ValidPass123!
    4. Click "Create Account"
  Expected: User account created, verification email sent, redirect to "Check Email" page

Scenario 1.2: User verifies email and logs in
  Steps:
    1. Click verification link in email
    2. Navigate to /login
    3. Enter email: test@example.com
    4. Enter password: ValidPass123!
    5. Click "Log In"
  Expected: User logged in successfully, redirected to dashboard
```

#### 2. Edge Cases (Boundary Conditions)

```
Scenario 2.1: Email at maximum valid length (254 characters)
  Input: 240-char-local-part@14-char-domain.com
  Expected: Account created successfully

Scenario 2.2: Password with special characters
  Input: P@$$w0rd!#%^&*
  Expected: Password accepted and hashed correctly

Scenario 2.3: Registration with existing email
  Steps:
    1. Create account with email@example.com
    2. Attempt second signup with same email
  Expected: Error message: "Email already registered"

Scenario 2.4: Multiple verification link clicks
  Steps:
    1. Click verification link
    2. Click same link again (before/after verification)
  Expected: First click verifies; second click shows "Already verified" or error
```

#### 3. Error Cases (Negative Testing)

```
Scenario 3.1: Invalid email format
  Input: notanemail
  Expected: Inline error: "Please enter a valid email address"

Scenario 3.2: Password too short
  Input: Pass1! (6 chars, min is 8)
  Expected: Error: "Password must be at least 8 characters"

Scenario 3.3: Passwords don't match
  Input: Password1, Password2
  Expected: Error: "Passwords must match"

Scenario 3.4: Submit form with JavaScript disabled
  Steps:
    1. Disable JavaScript in browser dev tools
    2. Fill form with valid data
    3. Click submit
  Expected: Form submits via standard POST, no client-side validation

Scenario 3.5: Network timeout during registration
  Expected: Show retry button, don't create duplicate account on retry
```

#### 4. Performance & Load

```
Scenario 4.1: Response time for registration
  Expected: Form submission responds within 2 seconds
  Tool: Chrome DevTools Network tab or load testing tool (k6, JMeter)

Scenario 4.2: Email delivery time
  Expected: Verification email arrives within 5 minutes
  Measurement: Time from submit to email received

Scenario 4.3: Load test: 100 concurrent registrations
  Expected: System handles without errors, no database deadlocks
  Tool: k6, Apache JMeter, or Locust
```

#### 5. Security Testing

```
Scenario 5.1: SQL Injection in email field
  Input: admin'--
  Expected: Input treated as literal string, no database errors

Scenario 5.2: XSS in email field
  Input: <script>alert('xss')</script>@example.com
  Expected: Script not executed, email validation rejects malformed string

Scenario 5.3: Password transmitted over HTTPS
  Steps:
    1. Use browser dev tools Network tab
    2. Submit registration
  Expected: All requests use HTTPS, password never visible in plain text

Scenario 5.4: CSRF protection
  Expected: Form includes CSRF token, POST without token is rejected

Scenario 5.5: Account enumeration
  Steps:
    1. Try registration with existing email
    2. Try login with non-existent email
  Expected: Both show generic message "Error occurred" (don't reveal if email exists)
```

### Environment

**Test Environment Details:**

- **URL**: staging.example.com or test.example.com
- **Database**: Fresh database reset before each test cycle
- **External Dependencies**:
  - Email service: SendGrid (staging API key)
  - Auth provider: OAuth provider staging endpoints
  - Payment gateway: Stripe test mode (test credit cards provided)
- **Browser/Devices**:
  - Chrome 120+ (Windows, Mac, Linux)
  - Firefox latest
  - Safari latest
  - Mobile: iPhone 14, Android 12+
- **Test Data**:
  - Valid email domain: test-domain.example.com
  - Test credit card: 4242-4242-4242-4242 (Stripe)
  - Valid phone numbers: +1-555-0100 to +1-555-0199

### Exit Criteria

**Testing is complete when:**

- All scenarios in sections 1-5 are executed
- Pass rate: ≥95% (allow for environment-specific flakes)
- All critical bugs (Severity 1-2) are fixed and re-tested
- Security scan results are reviewed and approved
- Performance benchmarks met or documented
- Regression test suite passes

**Definition of Done:**

- Test results documented with pass/fail status
- Bug report filed for any failures (linked to test case)
- Sign-off from QA lead and product owner
- Release notes include any known limitations

### Test Execution Log

| Date | Tester | Scenario | Result | Notes |
|------|--------|----------|--------|-------|
| 2025-03-18 | Alice | 1.1 | PASS | |
| 2025-03-18 | Alice | 1.2 | FAIL | Verification email not received; bug #1234 filed |
| 2025-03-18 | Bob | 2.1 | PASS | |
| ... | ... | ... | ... | ... |

## Test Plan Checklist

- [ ] Scope clearly defined (in/out of scope)
- [ ] Test scenarios cover happy path, edge cases, errors, performance, security
- [ ] Environment documented (URLs, credentials, test data)
- [ ] Clear expected results for each scenario
- [ ] Tester(s) assigned
- [ ] Entry criteria met (feature code ready, test env available)
- [ ] Exit criteria defined (pass rate, critical bug count)
- [ ] Browser/device coverage identified
- [ ] Security testing planned
- [ ] Load/performance testing identified
- [ ] Regression risks assessed
- [ ] Timeline and schedule communicated
