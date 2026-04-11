# ADR-004: Choice of Ranking Model for CTR Prediction

## Status
Accepted

## Date
2026-04-11

## Context
We need a ranking model to predict CTR and re-rank retrieved candidates.

Options considered:
1. **DLRM** (Deep Learning Recommendation Model) - Meta platform
2. **DCN V2** (Deep & Cross Network) - Google
3. **xDeepFM** - Implicit
4. **XGBoost** - Gradient boosted trees

## Decision
We will use **DLRM** as primary with **XGBoost** as fallback:
- DLRM: GPU-accelerated with TensorRT INT8
- XGBoost: CPU fallback for GPU failure
- Platt scaling for calibration

## Rationale

### Pros (DLRM)
- Industry proven (Meta production)
- Handles mixed dense/sparse features
- GPU acceleration with TensorRT
-Interpretable sub-scores

### Cons (DLRM)
- Complex to train
- Requires GPU infrastructure
- May overfit with limited data

### Alternatives Considered

**DCN V2**:
- PRO: Automatic feature crosses
- CON: Less proven at scale
- VERDICT: Monitor as alternative

**XGBoost**:
- PRO: Robust, interpretable
- CON: Lower capacity
- VERDICT: Use as fallback only

## Consequences

### Positive
- DLRM captures complex interactions
- TensorRT gives 2x+ speedup
- Graceful degradation to XGBoost

### Negative
- Need regular retraining
- Calibration required
- GPU cost

## Implementation

```python
# DLRM architecture
model = DLRM(
    dense_features=26,
    sparse_features=50,
    embedding_dim=128,
    bottom_mlp=[512, 256, 128],
    top_mlp=[256, 128, 1],
)

# TensorRT export
model.export(
    input_shapes={"dense": (None, 26), "sparse": (None, 50)},
    output_path="/models/dlrm.rank",
    quantization="int8",
    calibration_dataset="/data/calibration.npz",
)
```

## Performance Targets

| Model | AUC | Latency | GPU |
|-------|-----|---------|-----|
| DLRM (INT8) | > 0.75 | < 5ms | T4 |
| XGBoost | > 0.70 | < 15ms | CPU |

## References
- DLRM paper (Naumov et al., 2019)
- TensorRT optimization guide
- Implementation: `ml/models/dlrm/`

---

## Revision History
| Date | Author | Changes |
|------|--------|---------|
| 2026-04-11 | ML Engineer | Initial ADR |