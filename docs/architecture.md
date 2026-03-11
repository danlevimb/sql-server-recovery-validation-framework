# Framework Architecture

This project implements a modular restore validation framework for SQL Server.

The architecture separates recovery logic into four main components:

## Restore Chain Builder

`cfg.usp_GetLatestBackupFiles`

Responsible for determining the correct restore chain.

It identifies:

- the latest FULL backup
- optional DIFF backup
- required LOG backups
- STOPAT or STOPBEFOREMARK target log

---

## Restore Execution Engine

`cfg.usp_RestorePointInTime`

Responsible for executing the restore process.

Capabilities:

- executes FULL / DIFF / LOG restores
- supports STOPAT and STOPBEFOREMARK
- records execution telemetry
- persists restore results

---

## PITR Validation Engine

`cfg.usp_ValidatePitrCanary`

Validates restore correctness using deterministic canary records.

This ensures that the restore actually stopped at the intended logical boundary.

---

## Restore Test Orchestrator

`cfg.usp_RunRestoreTests`

Coordinates the entire validation process:

- generates canaries
- creates marked transactions
- executes restore
- validates results
- stores execution evidence

---

## Logging Model

Execution results are persisted using two tables:

- `log.RestoreTestRun`
- `log.RestoreStepExecution`

These tables provide:

- restore telemetry
- execution diagnostics
- forensic recovery evidence
