<p align="center">
<a href="../../README.md">Home</a> |
<a href="../architecture.md">Architecture</a>
</p>

# Canary-Based Recovery Validation Model

## Overview

The framework implements a **canary-based validation model** to verify the correctness of point-in-time recovery operations.

Instead of assuming that a restore operation is successful based solely on execution status, this model introduces **data-level verification** using controlled markers within the transaction log.

This approach transforms recovery from a technical process into a **deterministic and verifiable outcome**.

---

## Conceptual Foundation

The canary validation model is based on a simple but powerful principle:

> A recovery operation is only valid if the resulting data state matches the intended recovery boundary.

To achieve this, the framework introduces **controlled data artifacts** (canaries) that act as reference points before and after the recovery boundary.

---

## Model Definition

The validation model consists of three controlled events:

| Event | Description |
|------|------------|
| BEFORE | Record inserted before the recovery boundary |
| MARK | Named transaction marker used as recovery reference |
| AFTER | Record inserted after the recovery boundary |

---

## Recovery Expectation

When performing a restore using `STOPBEFOREMARK`, the main objective is to search specific records, the expected state is :

|   | BEFORE | MARK | AFTER |
|------|------------|----|-----|
| SOURCE DATABASE | 1 |  1 | 1 |
| TARGET DATABASE  | 1 | 0 | 0 |

This ensures that:
- Data before the boundary is preserved
- The marked transaction is not applied
- No data beyond the boundary is included

## Execution Flow

The model is implemented as follows:
  1. Insert BEFORE canary record
  2. Start a marked transaction (WITH MARK)
  3. Commit transaction → generates MARK in log
  4. Perform a LOG backup (captures the mark)
  5. Insert AFTER canary record
  6. Execute restore using STOPBEFOREMARK
  7. Validate restored data

## Why This Works

SQL Server recovery is based on transaction log replay.
- Each transaction is recorded with an LSN
- Marked transactions are persisted in msdb.dbo.logmarkhistory
- STOPBEFOREMARK ensures recovery stops before that transaction

Therefore:
- Any data inserted after the mark cannot be replayed
- Any data before the mark must exist

This makes the validation deterministic.

## Advantages of the Model
| Feature  | Description |
|----------|-------------|
| **Deterministic Validation** | Provides clear, binary validation results (pass/fail)|
| **Data-Level Assurance** | Validates actual data, not just execution success|
| **Reproducibility** | Scenarios can be executed repeatedly with consistent outcomes|
| **Independence from Environment** | Does not rely on external monitoring tools|
| **Integration with Telemetry** | Validation results are stored and traceable|


## Practical Use Cases
  -  Disaster recovery validation
  -  |Pre-deployment rollback checkpoints
  - Backup integrity verification
  - Audit and compliance scenarios
  - Testing recovery procedures in production-like environments

## Related SQL Server Concepts

The model is grounded in native SQL Server capabilities:

  - Transaction Log Architecture
  - LSN (Log Sequence Number) Continuity
  - Marked Transactions (WITH MARK)
  - Point-in-Time Recovery (STOPAT, STOPBEFOREMARK)
  - Log Backup Chains

## References

The concepts used in this model are based on official SQL Server documentation and established database recovery practices:

  - Microsoft Docs — [*Restore a SQL Server Database to a Point in Time (Full Recovery Model)*](https://learn.microsoft.com/en-us/sql/relational-databases/backup-restore/restore-a-sql-server-database-to-a-point-in-time-full-recovery-model?view=sql-server-ver17)

  - Microsoft Docs — [*The Transaction Log*](https://learn.microsoft.com/en-us/sql/relational-databases/logs/the-transaction-log-sql-server?view=sql-server-ver17)
https://learn.microsoft.com/en-us/sql/relational-databases/sql-server-transaction-log-architecture-and-management-guide
Microsoft Docs — Backup and Restore of SQL Server Databases
https://learn.microsoft.com/en-us/sql/relational-databases/backup-restore/back-up-and-restore-of-sql-server-databases
Summary

The canary-based validation model elevates recovery operations from:

“Restore completed successfully”

to:

“Restore correctness has been proven with data-level evidence”

This ensures that recovery is not assumed, but measured, validated, and trusted.

