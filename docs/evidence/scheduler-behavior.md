<p align="center">
<a href="../../README.md">Home</a> |
<a href="../architecture.md">Architecture</a>
</p>

# Scheduler Behavior

This section demonstrates how the framework behaves under different runtime conditions when executing the policy-driven scheduler:

- [`cfg.usp_RunScheduledBackups`](../../docs/procedures/usp_RunScheduledBackups.md)

The goal is to validate that the system:

- Makes correct decisions based on configuration  
- Adapts dynamically to changing conditions  
- Maintains operational consistency  
- Avoids unnecessary or redundant executions  

---

# Overview

The scheduler operates under a **trigger-based model**:

  - A SQL Server Agent Job runs every 5 minutes  
  - The procedure evaluates all databases  
  - Decisions are made dynamically using:
  - Configuration ([`[cfg].[Tier]`](../../sql/01_Tables/cfg.Tier.md), [`[cfg].[DatabasePolicy]`](../../sql/01_Tables/cfg.DatabasePolicy.md))  
  - Execution history ([`[log].[BackupRun]`](../../sql/01_Tables/log.BackupRun.md))  

### Execution

```sql
EXEC cfg.usp_RunScheduledBackups
    @DryRun = 1,
    @Debug = 1;
```
---
# Scenarios
  - [1 — No Backup Due](scheduler-behavior-1.md)
  - [2 — LOG Backup Due](scheduler-behavior-2.md)
  - [3 — FULL Backup Due](scheduler-behavior-3.md)
  - [4 — DIFF Backup Due](scheduler-behavior-4.md)
  - [5 — Recovery Model Constraint](scheduler-behavior-5.md)
  - [6 — FULL Does Not Reset LOG Cadence](scheduler-behavior-6.md)
  - [7 — Multiple Databases, Independent Decisions](scheduler-behavior-7.md)
  - [8 — Correlation Across Execution](scheduler-behavior-8.md)
  - [9 — Backup Already in Progress](scheduler-behavior-9.md)
  - [10 — Dynamic Policy Change](scheduler-behavior-10.md)

--- 

# Key Observations
  - Decisions are made at runtime, not predefined
  - Backup execution is demand-driven
  - System adapts instantly to configuration changes
  - Operational cadence is preserved
  - Concurrency and integrity constraints are enforced

# Conclusion

The scheduler behaves as a dynamic decision engine, not a static job executor.

It ensures that:

  - Backups are executed only when required
  - Policies are consistently enforced
  - System behavior remains predictable and traceable

This transforms backup scheduling into an adaptive, policy-driven system aligned with real operational needs.
