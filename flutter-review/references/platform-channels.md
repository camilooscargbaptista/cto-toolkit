# Platform Channels — Flutter ↔ Native

## Arquitetura

```
┌──────────────────┐         ┌──────────────────┐
│   Flutter (Dart)  │◄──────►│  Native (Kotlin/  │
│                    │  JSON  │  Swift)            │
│  MethodChannel    │◄──────►│  FlutterPlugin     │
│  EventChannel     │◄──────►│  EventSink         │
│  BasicMessage     │◄──────►│  Handler           │
└──────────────────┘         └──────────────────┘
```

## MethodChannel — Request/Response

### Dart Side
```dart
class NfcService {
  static const _channel = MethodChannel('com.zeca.app/nfc');

  Future<String?> readNfcTag() async {
    try {
      final result = await _channel.invokeMethod<String>('readTag');
      return result;
    } on PlatformException catch (e) {
      debugPrint('NFC error: ${e.message}');
      return null;
    } on MissingPluginException {
      debugPrint('NFC not available on this platform');
      return null;
    }
  }

  Future<bool> isNfcAvailable() async {
    try {
      return await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } catch (_) {
      return false;
    }
  }
}
```

### Kotlin Side (Android)
```kotlin
class NfcPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.zeca.app/nfc")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "readTag" -> {
                val tagData = readNfcTag()
                if (tagData != null) {
                    result.success(tagData)
                } else {
                    result.error("NFC_ERROR", "Could not read NFC tag", null)
                }
            }
            "isAvailable" -> result.success(nfcAdapter?.isEnabled == true)
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
```

### Swift Side (iOS)
```swift
public class NfcPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.zeca.app/nfc",
            binaryMessenger: registrar.messenger()
        )
        let instance = NfcPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "readTag":
            readNfcTag { tagData in
                if let data = tagData {
                    result(data)
                } else {
                    result(FlutterError(code: "NFC_ERROR", message: "Could not read", details: nil))
                }
            }
        case "isAvailable":
            result(NFCNDEFReaderSession.readingAvailable)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
```

## EventChannel — Continuous Streams

### Dart Side
```dart
class LocationService {
  static const _eventChannel = EventChannel('com.zeca.app/location');

  Stream<Position> get positionStream {
    return _eventChannel.receiveBroadcastStream().map((data) {
      final map = Map<String, dynamic>.from(data);
      return Position(
        latitude: map['latitude'] as double,
        longitude: map['longitude'] as double,
      );
    });
  }
}
```

### Kotlin Side
```kotlin
class LocationPlugin : FlutterPlugin, EventChannel.StreamHandler {
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        eventChannel = EventChannel(binding.binaryMessenger, "com.zeca.app/location")
        eventChannel.setStreamHandler(this)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        startLocationUpdates()
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        stopLocationUpdates()
    }

    private fun onLocationUpdate(lat: Double, lng: Double) {
        eventSink?.success(mapOf("latitude" to lat, "longitude" to lng))
    }
}
```

## Best Practices

- [ ] Use reverse domain notation for channel names (`com.company.app/feature`)
- [ ] Always handle `PlatformException` and `MissingPluginException`
- [ ] Return `result.notImplemented()` for unknown methods
- [ ] Clean up handlers in `onDetachedFromEngine`
- [ ] Use `EventChannel` for continuous data (GPS, sensors, BLE)
- [ ] Use `MethodChannel` for request/response (NFC read, biometrics)
- [ ] Test on both platforms (Android + iOS)
- [ ] Keep platform code minimal — business logic in Dart
