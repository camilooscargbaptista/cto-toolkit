# JVM Profiling Deep Dive

## CPU & Thread Analysis

### Java Flight Recorder (JFR)
Most powerful JVM profiling tool. Production-safe, low overhead (~2%).

```bash
java -XX:+FlightRecorder \
     -XX:StartFlightRecording=duration=60s,filename=recording.jfr \
     -jar app.jar
```

Analyze with:
- **JDK Mission Control** (bundled with JDK 11+)
- **IntelliJ IDEA** (built-in analyzer)
- **jfr` CLI** (parse recordings)

Records: CPU samples, allocations, I/O, GC events, thread contention, exceptions.

### Thread Dumps
Instant snapshot of every thread's state.

```bash
jstack <pid> > thread_dump.txt
```

**What to look for:**
- `BLOCKED` threads: waiting on lock (contention)
- `WAITING` on `Object.wait()`: might be stuck waiting for signal
- `TIMED_WAITING`: normal, waiting for timeout
- Thread pools exhausted: many WAITING threads doing nothing
- Deadlock detection: JVM prints deadlock summary at end

### Async-Profiler
Generates flame graphs without needing Java flags.

```bash
./profiler.sh -d 30 -f flame.html <pid>
# Produces flame.html showing CPU hot spots
```

Works even on already-running JVMs. Excellent for production diagnosis.

---

## GC Analysis

### Enable GC Logging
```bash
java -Xlog:gc*:file=gc.log:time,uptime:filecount=5,filesize=10m -jar app.jar
```

Logs all GC events. Supports rotation to keep file size bounded.

### Key GC Metrics to Monitor

| Metric | What It Means | Good Range | Bad Sign |
|--------|---------------|-----------|----------|
| **GC pause time** | How long app pauses | <100ms p99 | >500ms: users perceive freeze |
| **GC frequency** | How often GC runs | < 1/minute at baseline | Every 5 sec: over-allocating |
| **Heap after GC** | Heap usage post-collection | Steady state | Growing: memory leak |
| **Promotion rate** | Objects moved young→old gen | <1% of allocation | >10%: premature tenuring |
| **Full GC frequency** | Stop-the-world collections | Never in production | Once per hour: troubling |

### Analyzing GC Logs
```
2024-03-18T10:15:42.123+0000: 15.432: [GC (G1 Evacuation Pause)
    1024M->512M(2048M), 0.0234 secs]
```
Means: 1GB heap → 512MB heap, 23ms pause. Healthy.

Concerning: 2048M→2040M heap after full GC = leak.

---

## JVM Memory

### Heap Dump
Snapshot of entire heap at moment of capture.

```bash
jmap -dump:format=b,file=heap.hprof <pid>
```

Analyze with:
- **Eclipse MAT** (Memory Analyzer Tool): Free, powerful
- **VisualVM**: Built-in GUI
- **JProfiler**: Commercial but comprehensive

Look for:
- Retained objects by type (top 10 by count)
- GC roots preventing cleanup
- Circular references
- Duplicate large collections

### Live Monitoring
```bash
jstat -gcutil <pid> 1000    # GC stats every 1 second
# S0  S1   E    O    M     CCS   YGC   FGC
# 0.0 0.0  25.3 10.1 95.2  90.0  1234  2
```

Columns:
- **S0/S1**: Survivor space usage %
- **E**: Eden space usage %
- **O**: Old generation usage %
- **M**: Metaspace usage %
- **YGC/FGC**: Young/Full GC count

### GC Algorithm Selection

**G1GC** (default Java 9+): Good default, self-tuning.
```bash
java -XX:+UseG1GC -jar app.jar
```

**ZGC** (low latency, requires Java 11+): Sub-millisecond pauses.
```bash
java -XX:+UseZGC -jar app.jar
```

**Shenandoah** (alternative low-latency): Sub-10ms pauses.
```bash
java -XX:+UseShenandoahGC -jar app.jar
```

Choose ZGC or Shenandoah if GC pauses are blocking SLA.
