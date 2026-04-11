# ADR-003: Choice of Streaming Framework for Real-Time Features

## Status
Accepted

## Date
2026-04-11

## Context
We need a streaming framework for real-time feature computation.

Options considered:
1. **Apache Flink** (Java/Scala) - Production standard
2. **Kafka Streams** - Lightweight
3. **Apache Spark Streaming** - Micro-batch
4. **Custom Python** - Simpler but less robust

## Decision
We will use **Apache Flink** with Java:
- Flink 1.18+ with DataStream API
- RocksDB state backend
- S3 checkpointing
- Exactly-once for critical events

## Rationale

### Pros
- Industry standard for streaming at scale
- Exactly-once semantics
- Complex windowing support
- Checkpointing and fault tolerance

### Cons
- Steep learning curve
- Complex deployment
- Debugging challenges

### Alternatives Considered

**Kafka Streams**:
- PRO: Simple, embedded in Kafka
- CON: Limited windowing, less mature
- VERDICT: Rejected for complex features

**Spark Streaming**:
- PRO: Unified batch/stream
- CON: Higher latency (micro-batch)
- VERDICT: Rejected for real-time

**Python Custom**:
- PRO: Simple development
- CON: Poor fault tolerance at scale
- VERDICT: Use for prototyping only

## Consequences

### Positive
- Exactly-once state
- Flexible windowing (session, sliding, tumbling)
- Handles 100K+ events/sec
- Integration with Kafka, Redis, Milvus

### Negative
- Requires Java/Scala expertise
- Complex job management
- State TTL needs tuning

## Implementation Notes

```java
// Flink job structure
StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
env.enableCheckpointing(60000);
env.getCheckpointConfig().setCheckpointStorage("s3://rec-system/checkpoints");

// Session window
.events
  .keyBy(UserEvent::getUserId)
  .window(EventTimeSessionWindows.withGap(Time.minutes(30)))
  .process(new SessionFeatureProcessFunction());
```

## References
- Flink documentation
- RocksDB state backend tuning

---

## Revision History
| Date | author | Changes |
|------|--------|---------|
| 2026-04-11 | Backend Engineer | Initial ADR |