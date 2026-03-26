---
name: swift-review
description: "Review Swift/iOS code: SwiftUI, Combine, UIKit, App Store guidelines and iOS architecture"
category: code-quality
preferred-model: sonnet
min-confidence: 0.4
triggers:
  frameworks: [swiftui, uikit, combine, vapor]
  file-patterns: ["**/*.swift", "**/Package.swift"]
depends-on: []
estimated-tokens: 5000
tags: [swift, ios, swiftui, apple]
---

# Swift / iOS Code Review

## When to Use
- Reviewing Swift/iOS code (SwiftUI, UIKit, Combine)
- Evaluating iOS architecture (MVVM, TCA, VIPER)
- App Store compliance review
- iOS performance and memory review

## Review Checklist

### Architecture
- [ ] MVVM or TCA architecture consistently applied
- [ ] View models don't import UIKit/SwiftUI
- [ ] Protocol-oriented design for dependencies
- [ ] Coordinator pattern for navigation (if UIKit)
- [ ] `@EnvironmentObject` / `@StateObject` used correctly

### Swift Best Practices
- [ ] Value types (`struct`) preferred over reference types (`class`)
- [ ] `let` preferred over `var` (immutability)
- [ ] Guard clauses for early returns
- [ ] `Result<Success, Failure>` for error handling
- [ ] `Codable` for JSON parsing (not manual parsing)
- [ ] `async/await` instead of completion handlers (iOS 15+)
- [ ] Property wrappers for common patterns
- [ ] Access control (`private`, `internal`, `public`) enforced

### SwiftUI
- [ ] Views are small and composable (< 50 lines body)
- [ ] `@State` for local, `@Binding` for parent-child, `@ObservedObject` for injected
- [ ] No heavy computation in `body` (use `.task {}` modifier)
- [ ] Preview providers for all views
- [ ] Accessibility modifiers (`.accessibilityLabel`, `.accessibilityHint`)
- [ ] Dark mode support verified

### Memory & Performance
- [ ] No retain cycles (`[weak self]` in closures)
- [ ] `Instruments` profiled for leaks
- [ ] Images resized to display size (not full resolution)
- [ ] TableView/CollectionView cell reuse
- [ ] Background tasks for heavy work (`DispatchQueue.global()`)
- [ ] Core Data batch operations for large datasets

### App Store Guidelines
- [ ] No private APIs used
- [ ] In-App Purchase for digital goods (not external links)
- [ ] Privacy manifest (`PrivacyInfo.xcprivacy`) included
- [ ] Required device capabilities declared
- [ ] App Transport Security exceptions justified
- [ ] No hardcoded test data in release builds

## Output Format
```markdown
## iOS Review: [Module]
**Health Score**: X/10
### Issues | Improvements | Architecture Notes
```
