# ADR-001: Choice of LLM Embedding Model for Item Representations

## Status
Accepted

## Date
2026-04-11

## Context
We need to select an embedding model for generating item representations forANN retrieval.

Options considered:
1. **Two-Tower Model** (PyTorch) - Dual encoder for user/item embeddings
2. **BERT-based** - Sentence-level embeddings from text
3. **Word2Vec + PCA** - Classical approach

## Decision
We will use the **Two-Tower Model** with:
- User tower: MLP on user features → 128-dim embedding
- Item tower: MLP on item features → 128-dim embedding
- Trained with in-batch negatives + hard negatives
- Export to ONNX for inference

## Rationale

### Pros
- Industry standard for retrieval (YouTube, Amazon, Airbnb)
- Efficient inference (single forward pass)
- End-to-end trained for retrieval objective
- Handles cold-start via content features

### Cons
- Requires training data
- Quality depends on negative sampling strategy
- May not capture semantic nuances

### Alternatives Considered

**BERT-based**:
- PRO: Better semantic understanding
- CON: Too slow for 10M items at inference
- VERDICT: Use for cold-start only, not main retrieval

**Word2Vec + PCA**:
- PRO: Simple, fast
- CON: Poor quality
- VERDICT: Rejected

## Consequences

### Positive
- Can serve 50K QPS at <10ms with GPU batching
- Updates continuously with user interactions
- Integrates with Milvus for ANN

### Negative
- Need to retrain weekly
- Cold-start requires separate content-based model

## References
- YouTube DNN (Covington et al., 2016)
- Two-Tower Networks (Zhao et al., 2021)
- Implementation: `ml/models/two_tower/`

---

## Revision History
| Date | Author | Changes |
|------|--------|---------|
| 2026-04-11 | ML Engineer | Initial ADR |