# ADR-002: Choice of Vector Database for ANN Retrieval

## Status
Accepted

## Date
2026-04-11

## Context
We need a vector database to store and search item embeddings at scale.

Options considered:
1. **Milvus** - Open-source vector database
2. **Qdrant** - Rust-based vector search
3. **Pinecone** - Managed service
4. **Elasticsearch** - With vector search plugin

## Decision
We will use **Milvus** in cluster mode:
- 8 query nodes for 50K QPS
- HNSW index for recall@100 20%+
- S3 checkpointing for durability
- Integrated with RocksDB state

## Rationale

### Pros
- Designed for billion-scale vector search
- Supports multiple index types (HNSW, IVF, PQ)
- Active community and commercial support
- GPU acceleration available

### Cons
- Requires dedicated infrastructure
- Complex Deployment
- Some stability issues in early versions

### Alternatives Considered

**Pinecone**:
- PRO: Fully managed, easy
- CON: Vendor lock-in, cost
- VERDICT: Consider for future

**Qdrant**:
- PRO: Rust, fast, memory-efficient
- CON: Less mature ecosystem
- VERDICT: Monitor for production

**Elasticsearch**:
- PRO: Already in stack
- CON: Not optimized for vectors
- VERDICT: Use for metadata only

## Consequences

### Positive
- Can search 10M items in <10ms
- Scales with horizontal additions
- Integrates with Flink for real-time updates

### Negative
- Need to manage cluster
- Index building takes time
- Backup/recovery complex

## Implementation

```yaml
# Infrastructure config
queryNode:
  replicas: 8
  resources:
    memory: 16Gi
    cpu: 4000m
index:
  type: HNSW
  params:
    M: 16
    efConstruction: 200
```

## References
- Milvus documentation
- HNSW benchmark: recall 0.95 @ ef=200

---

## Revision History
| Date | Author | Changes |
|------|--------|---------|
| 2026-04-11 | ML Engineer | Initial ADR |