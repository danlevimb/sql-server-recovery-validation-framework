<p align="center">
<a href="/README.md">Home</a> |
<a href="../../sql/01_Tables.md">Tables</a> |
<a href="../../sql/02_Procedures.md">Procedures</a>
</p>

---

# cfg.usp_RunScheduledBackups

> ***Orchestration Layer***

## Overview

`cfg.usp_RunScheduledBackups` is the central orchestration procedure responsible for evaluating backup policies and determining which backup operations must be executed in the current cycle.

It analyzes database state, tier configuration, and historical backup activity to make **deterministic, policy-driven decisions** about FULL, DIFF, and LOG execution.

This procedure acts as the **decision engine** of the framework and executes backups at a **per-database level** by invoking [`[cfg].[usp_BackupDatabase]`](../../docs/procedures/usp_BackupDatabase.md).

If you want to see how this procedure behaves in real time go [here](../evidence/scheduler-behavior.md).

## Responsibilities

- Evaluate backup requirements per database based on policy and timing
- Determine whether FULL, DIFF, or LOG backups are due
- Respect database recovery model constraints (e.g. SIMPLE vs FULL)
- Maintain consistent backup cadence aligned with RPO/RTO definitions
- Prevent overlapping executions using application locks
- Skip databases with backups already in progress
- Execute backups individually using [`[cfg].[usp_BackupDatabase]`](../../docs/procedures/usp_BackupDatabase.md)
- Support dry-run mode for safe validation

## Parameters

| Parameter | Type | Description |
|----------|------|-------------|
| @UseMirrorToSecondary | BIT | Indicates whether backups should also be written to the secondary path |
| @WithVerify | BIT | Indicates whether backup verification should be performed |
| @DryRun | BIT | If set to `1`, evaluates and returns decisions without executing backups |
| @Debug | BIT | Enables detailed output for troubleshooting and validation |

## Execution Flow

The procedure follows a structured decision pipeline:

1. Acquire execution lock using `sp_getapplock` to prevent concurrent runs  
2. Load database configuration from [`[cfg].[DatabasePolicy]`](../../sql/01_Tables/cfg.DatabasePolicy.md)  
3. Join with [`[cfg].[Tier]`](../../sql/01_Tables/cfg.Tier.md) to obtain RPO/RTO and frequency rules  
4. Retrieve last successful backup timestamps from [`[log].[BackupRun]`](../../sql/01_Tables/log.BackupRun.md)  
5. Detect databases with backups currently in progress  
6. Evaluate backup requirements:
   - FULL due based on `Full_Freq_Minutes`
   - DIFF due based on `LastDiffEffectiveAt`
   - LOG due based on `LastLogAt`
7. Apply recovery model constraints:
   - Skip LOG backups for `SIMPLE` databases  
8. Assign a `SelectedBackupType` per database using precedence:
   - FULL > DIFF > LOG  
9. Build execution queue ordered by priority (RPO and backup type)  
10. Execute backups individually by invoking [`[cfg].[usp_BackupDatabase]`](../../docs/procedures/usp_BackupDatabase.md)  
11. Capture execution results from [`[log].[BackupRun]`](../../sql/01_Tables/log.BackupRun.md)  
12. Release application lock  

## Decision Logic

Backup selection follows a priority-based model:

- FULL has highest precedence  
- DIFF is evaluated relative to the last effective baseline (FULL or DIFF)  
- LOG is evaluated independently to preserve a stable cadence  

Transaction log backups are evaluated against the last successful log backup, ensuring a consistent interval aligned with the configured RPO, regardless of recent FULL operations.

## Example Usage

### Dry Run (Validation Mode)
```sql
EXEC cfg.usp_RunScheduledBackups
    @DryRun = 1,
    @Debug = 1;
```

### Production Execution
```sql
EXEC cfg.usp_RunScheduledBackups
    @UseMirrorToSecondary = 1,
    @WithVerify = 0,
    @DryRun = 0,
    @Debug = 0;
```

## Outputs
### Dry Run Mode

Returns a decision matrix including:
- DatabaseName
- Tier
- Recovery Model
- Last backup timestamps
- Due flags (FullDue, DiffDue, LogDue)
- SelectedBackupType
- DecisionReason

### Execution Mode

Executes backups per database and generates telemetry records in:
- [`[log].[BackupRun]`](../../sql/01_Tables/log.BackupRun.md)

All executions are correlated via a shared CorrelationID.

## Related Components
- [`[cfg].[DatabasePolicy]`](../../sql/01_Tables/cfg.DatabasePolicy.md)
 → Defines inclusion and backup rules
- [`[cfg].[Tier]`](../../sql/01_Tables/cfg.Tier.md)
 → Defines frequency and RPO/RTO targets
- [`[cfg].[usp_BackupDatabase]`](../../docs/procedures/usp_BackupDatabase.md)
 → Executes individual database backups
- [`[log].[BackupRun]`](../../sql/01_Tables/log.BackupRun.md)
 → Stores execution telemetry

## Source Code
[View full implementation](../../sql/cfg/usp_RunScheduledBackups.sql)

---

<p align="center"> 
<a href="/README.md">Home</a> | 
<a href="../../sql/01_Tables.md">Tables</a> | 
<a href="../../sql/02_Procedures.md">Procedures</a> 
</p>


