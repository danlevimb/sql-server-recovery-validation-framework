## Scheduling Model

The framework uses a **lightweight, trigger-based scheduling model** powered by SQL Server Agent.

A single job executes [`[cfg].[usp_RunScheduledBackups]`](../docs/procedures/usp_RunScheduledBackups.md) at a fixed interval (typically every 5 minutes).

### Key Principle

The SQL Server Agent job does **not contain any scheduling logic**.

Instead, it acts purely as a **heartbeat trigger**, periodically invoking the orchestration engine.

All decision-making is performed dynamically inside the procedure based on metadata and execution history.

---

## Example Usage

```sql
EXEC cfg.usp_RunScheduledBackups
      @UseMirrorToSecondary = 1,
      @WithVerify = 0,
      @DryRun = 0,
      @Debug = 0;
```
---

### Execution Flow

```text
SQL Server Agent Job (every 5 minutes)
        ↓
cfg.usp_RunScheduledBackups   ← Decision Engine
        ↓
Decision Matrix (#Decision)
        ↓
Execution Queue (#Execution)
        ↓
cfg.usp_BackupDatabase        ← Execution Layer
        ↓
log.BackupRun                 ← Telemetry
```
### Behavior Model

At each execution cycle:
- The procedure evaluates all eligible databases
- Determines whether a backup is required
- Executes only the necessary operations

If no backups are due, the procedure exits without performing any action.

### Design Characteristics

This scheduling approach provides several advantages:
| Feature | Description |
|---------|-------------|
| Policy-driven execution | Backup behavior is controlled entirely by configuration (cfg.Tier, cfg.DatabasePolicy) |
| Dynamic adaptability | Changes in frequency or inclusion rules take effect immediately without modifying jobs |
| Deterministic behavior | Decisions are based on actual execution history (log.BackupRun), not static schedules |
| Reduced operational complexity | A single job replaces multiple scheduled backup jobs |
| Efficient execution | Backups run only when required, avoiding redundant operations |

### Operational Cadence

The execution interval (e.g. every 5 minutes) enables:

- Stable transaction log backup rhythm aligned with RPO targets
- Fast reaction to missed or delayed backups
- Continuous evaluation without overloading the system

### Example Job Configuration

**Job Name**: SCH_BackupScheduler
**Frequency**: Every 5 minutes

Step:

```sql
EXEC cfg.usp_RunScheduledBackups
    @UseMirrorToSecondary = 1,
    @WithVerify = 0,
    @DryRun = 0,
    @Debug = 0;
```
### Summary

The scheduling layer is intentionally simple and decoupled from decision logic.

The job triggers execution, but the framework itself determines:
- **what to run**
- **when to run it**
- **and why**

This separation enables a fully metadata-driven, self-adjusting backup system.
