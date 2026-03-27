<p align="center">
<a href="README.md">Home</a> |
<a href="../architecture.md">Back</a>
</p>

# Modular Usage Scenarios

Although the framework is designed as an integrated recovery validation solution, its components can also be used independently to address specific operational, recovery, and governance needs.

This modular design allows the same architecture to support multiple use cases beyond end-to-end validation, increasing its practical value in real-world environments.

---

### Point-in-Time Recovery (Operational Incidents)

The restore engine (`cfg.usp_RestorePointInTime`) can be used independently to recover a database to a precise moment in time.

Typical scenarios include:

- Accidental data modification (e.g., `UPDATE` or `DELETE` without proper filtering)  
- Logical corruption caused by application errors  
- Recovery prior to unintended data changes  

Key benefits:

- Precise recovery using `STOPAT`  
- Reduced incident response time  
- Controlled restoration into isolated environments for analysis  

---

### Marker-Based Recovery (Controlled Rollback Points)

The framework supports recovery using marked transactions, enabling controlled rollback to meaningful business events.

Typical scenarios include:

- Creating recovery points before major releases  
- Marking boundaries before bulk data operations  
- Establishing safe checkpoints during critical business processes  

Key benefits:

- Recovery aligned with business events instead of timestamps  
- Deterministic rollback using `STOPBEFOREMARK`  
- Support for controlled testing and release validation  

---

### Canary-Based Validation (Recovery Assurance)

When used through the orchestration layer (`cfg.usp_RunRestoreTests`), the framework enables data-level validation using canary records.

Typical scenarios include:

- Validating that a restore operation reflects the intended recovery boundary  
- Testing recovery behavior before production releases  
- Verifying correctness of recovery strategies  

Key benefits:

- Functional validation beyond technical restore success  
- Deterministic verification of recovery boundaries  
- Clear evidence of correct or incorrect recovery behavior  

---

### Enterprise Backup Standardization

Backup procedures such as `cfg.usp_BackupDatabase` or `cfg.usp_BackupByTierAndType` can be institutionalized as standard mechanisms for backup execution.

Typical scenarios include:

- Enforcing consistent backup policies across environments  
- Standardizing compression, checksum, and mirroring options  
- Ensuring traceability of backup operations  

Key benefits:

- Centralized and consistent backup strategy  
- Improved auditability and forensic traceability  
- Reduced operational variability across teams  

---

### Recovery Testing and Auditability

The orchestration and telemetry layers enable systematic recovery testing and evidence collection.

Typical scenarios include:

- Periodic validation of backup recoverability  
- Internal or external audit requirements  
- Measurement of actual recovery performance  

Key benefits:

- Evidence-based validation of recovery capability  
- Traceable execution logs and outcomes  
- Measurement of practical recovery times (RTO)  

---

### Metadata-Driven Restore Planning

The restore chain planner (`cfg.usp_GetLatestBackupFiles`) can be used independently to analyze and construct valid restore sequences.

Typical scenarios include:

- Identifying the correct backup chain for a given recovery point  
- Validating LSN continuity across backup sets  
- Supporting manual or complex restore operations  

Key benefits:

- Deterministic restore planning  
- Reduced human error in chain reconstruction  
- Improved understanding of backup coverage and gaps  

---

### Summary

The framework is designed as a set of composable capabilities rather than a single rigid workflow.

Each component can operate independently or as part of an integrated pipeline, enabling the solution to support incident recovery, release management, auditability, and enterprise backup standardization.

This modularity transforms the framework from a validation tool into a **reusable recovery platform**.
