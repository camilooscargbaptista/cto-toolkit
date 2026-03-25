# Flutter Performance Checklist

## Build Performance

### Widget Rebuilds
- [ ] Use `const` constructors wherever possible
- [ ] Use `BlocBuilder.buildWhen` to limit rebuilds
- [ ] Break large widgets into smaller StatelessWidgets
- [ ] Avoid `setState` at high level — use state management
- [ ] Never build widgets in `build()` method loops without keys

```dart
// ❌ Rebuilds entire list on any change
BlocBuilder<MyCubit, MyState>(
  builder: (context, state) => ListView(
    children: state.items.map((i) => ListTile(title: Text(i.name))).toList(),
  ),
);

// ✅ Only rebuilds when items change
BlocBuilder<MyCubit, MyState>(
  buildWhen: (prev, curr) => prev.items != curr.items,
  builder: (context, state) => ListView.builder(
    itemCount: state.items.length,
    itemBuilder: (context, index) => ItemTile(item: state.items[index]),
  ),
);
```

### List Performance
- [ ] Use `ListView.builder` (not `ListView(children:)`) for large lists
- [ ] Provide `itemExtent` when item height is fixed
- [ ] Use `const` widget constructors for list items
- [ ] Add keys to reorderable lists (`ValueKey`)
- [ ] Use `AutomaticKeepAliveClientMixin` for expensive tabs
- [ ] Consider `SliverList` for mixed scroll views

### Image Performance
- [ ] Use `CachedNetworkImage` for network images
- [ ] Resize images to display size (don't load 4K for 100px thumbnail)
- [ ] Use `Image.asset` for static images (bundled at build)
- [ ] Implement placeholder/error widgets
- [ ] Lazy load images in lists (`cacheExtent`)

```dart
CachedNetworkImage(
  imageUrl: url,
  width: 100,
  height: 100,
  fit: BoxFit.cover,
  placeholder: (_, __) => Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Container(color: Colors.white),
  ),
  errorWidget: (_, __, ___) => Icon(Icons.error),
);
```

## Memory Performance

### Leaks
- [ ] Dispose all controllers in `dispose()` (TextEditingController, ScrollController, AnimationController)
- [ ] Cancel all subscriptions in `dispose()` (StreamSubscription)
- [ ] Close all BLoCs/Cubits properly
- [ ] Remove all listeners in `dispose()`
- [ ] Don't store BuildContext in async gaps

```dart
class _MyState extends State<MyWidget> {
  late final TextEditingController _controller;
  late final StreamSubscription _sub;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _sub = stream.listen((event) { ... });
  }

  @override
  void dispose() {
    _controller.dispose();
    _sub.cancel();
    super.dispose();
  }
}
```

### Heavy Objects
- [ ] Use `compute()` for CPU-intensive work (JSON parsing, image processing)
- [ ] Limit cached items (LRU cache with max size)
- [ ] Release resources when app goes to background

## Network Performance

- [ ] Implement request timeout (10-30s)
- [ ] Retry with exponential backoff (3 attempts max)
- [ ] Cache responses (Hive, shared_preferences, SQLite)
- [ ] Use pagination for large lists (infinite scroll)
- [ ] Compress request bodies (gzip)
- [ ] Batch API calls when possible

## Animation Performance

- [ ] Use `AnimatedContainer` for simple transitions (not raw Animation)
- [ ] Use `RepaintBoundary` around animated widgets
- [ ] Keep animations at 60fps (avoid layout during animation)
- [ ] Use `AnimatedBuilder` with `child` parameter for non-animated subtrees
- [ ] Profile with `flutter run --profile` + DevTools

## DevTools Profiling

```bash
# Run in profile mode (release-like performance, with DevTools)
flutter run --profile

# Open DevTools
flutter pub global activate devtools
dart devtools
```

### What to check:
1. **Widget rebuild count** — high rebuild count = waste
2. **Raster thread** — if janky, GPU is overloaded
3. **UI thread** — if janky, build phase is too heavy
4. **Memory tab** — leaking memory? Growing over time?
5. **Network tab** — excessive API calls?

## Platform-Specific

### Android
- [ ] ProGuard/R8 enabled for release builds
- [ ] Multidex enabled if needed
- [ ] Use Android App Bundle (not APK) for Play Store

### iOS
- [ ] bitcode disabled (not needed for Flutter)
- [ ] Minimum iOS version set appropriately
- [ ] Launch screen configured (no white flash)

## Checklist Summary

| Category | Critical Items |
|----------|---------------|
| Widgets | const constructors, ListView.builder, buildWhen |
| Memory | dispose all controllers/subscriptions |
| Images | CachedNetworkImage, resize to display size |
| Network | timeout, retry, cache, pagination |
| Animation | RepaintBoundary, 60fps target |
| Profiling | Run in --profile mode, use DevTools |
