# Automated SQL Server Recovery Validation Framework

A SQL Server framework designed to automatically validate **backup recoverability** and **point-in-time restore scenarios** using deterministic restore chain construction and canary-based verification.

This project demonstrates a production-grade approach to ensuring that SQL Server backups are not only successful but **actually recoverable**.

---

# The Problem

Many organizations rely on successful backup jobs as proof of recoverability.

However:

- A successful backup **does not guarantee** a successful restore.
- Recovery chains may be broken.
- Transaction log coverage may be incomplete.
- STOPAT recovery may fail silently if not validated.

This framework focuses on solving that problem by **automatically executing restore validation tests**.

---

# Key Capabilities

- Automatic restore chain construction (FULL / DIFF / LOG)
- Point-in-time recovery validation
- Mark-based restore validation
- Deterministic restore verification using canary records
- Detailed restore telemetry logging
- Automated restore testing across multiple databases

---

# Framework Architecture

The framework is composed of four main stored procedures:

| Procedure | Responsibility |
|-----------|---------------|
| `cfg.usp_GetLatestBackupFiles` | Determines the correct restore chain |
| `cfg.usp_RestorePointInTime` | Executes the restore workflow |
| `cfg.usp_ValidatePitrCanary` | Validates recovery correctness |
| `cfg.usp_RunRestoreTests` | Orchestrates restore validation tests |

---

# Restore Validation Workflow

1. Generate deterministic canary records
2. Create a marked transaction boundary
3. Produce required transaction log backups
4. Execute restore workflow
5. Apply STOPAT or STOPBEFOREMARK
6. Validate restored state using canary verification
7. Persist telemetry and execution evidence

---

# Repository Structure
| Folder | Description |
|-----------|---------------|
| `docs/` | Architecture documentation |
| `diagrams/` | Visual architecture diagrams |
| `sql/` | Database objects |
| `examples/` | Execution outputs and evidence |


---

# Example Execution

Example restore validation output:
Processing database: AdventureWorks2022

Creating PITR canaries
Generating marked transaction

Executing restore chain
FULL restore completed
DIFF restore completed
LOG restore applied
STOPAT applied successfully

Validating canary records

Validation result: PASSED

---

# Why This Project Matters

Backup success does not equal recoverability.

This framework demonstrates how to implement **automated recovery validation**, which is a critical component of resilient data platform engineering.

---

# Author

Dan Levi Menchaca Bedolla  
SQL Server DBA | Data Infrastructure & Reliability Engineering
