<p align="center">
<a href="README.md">Home</a> |
<a href="../architecture.md">Back</a>
</p>

# Recovery Validation Model

The framework implements a deterministic validation model to verify that a restored database reflects the intended recovery boundary.

Rather than assuming that a successful restore operation guarantees correctness, the framework introduces a data-level validation mechanism based on controlled reference records, known as *canaries*.

---

### Validation Concept

The validation model is based on the controlled insertion of reference records around a recovery boundary.

Three types of canary records are used:

- **`BEFORE`** → inserted before the recovery boundary  
- **`MARK`** → associated with a marked transaction (when applicable)  
- **`AFTER`** → inserted after the recovery boundary  

These records act as validation anchors that allow the system to determine whether the restored database state is consistent with the expected recovery point.

---

### Point-in-Time Validation

In `STOPAT` scenarios, the validation logic evaluates whether:

- Records inserted **before** the recovery point exist in the restored database  
- Records inserted **after** the recovery point are absent  

This confirms that the restore operation correctly reflects the intended timestamp.

---

### Marker-Based Validation

In `STOPBEFOREMARK` scenarios, the validation model uses marked transactions:

- A transaction is explicitly marked during execution  
- The system identifies the corresponding `mark_lsn`  
- The restore operation stops before the marked transaction  

Validation ensures that:

- Records associated with the marked transaction are excluded  
- Records prior to the mark are preserved  

This enables recovery aligned with business events rather than timestamps.

---

### Canary Validation Execution

The validation process is executed by:

- `[cfg].[usp_ValidatePitrCanary]`

This procedure:

- Evaluates the presence or absence of canary records  
- Determines whether the recovery boundary was respected  
- Produces a validation result and diagnostic message  

Canary-related metadata is stored in `log.RestoreTestRun` when validation is executed through the orchestration layer.

---

### Deterministic Validation

The use of canary records transforms restore validation into a deterministic process:

- Recovery correctness is verified using actual data state  
- Validation results are reproducible and traceable  
- The system provides clear evidence of success or failure  

This eliminates ambiguity and ensures that recovery behavior can be trusted.

---

### Diagram (Recovery Timeline)

The following diagram illustrates how canary records are created around a recovery boundary and how they are used during restore validation:

<p align="center">
  <img src="/diagrams/recovery-validation-timeline.png" width="900">
</p>

---

### Summary

The recovery validation model ensures that restore operations are not only technically successful, but also functionally correct.

By validating data state against controlled reference points, the framework provides reliable and evidence-based confirmation of recoverability.
