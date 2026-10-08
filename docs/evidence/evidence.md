<p align="center">
<a href="../../README.md">Home</a> |
<a href="../architecture.md">Architecture</a> |
<a href="../use-cases/use-cases.md">Use cases</a>
</p>

# Evidence

This section contains execution evidence demonstrating how the framework behaves under controlled operational scenarios.

It provides step-by-step proof for:

| Section | What it proves | Link |
|---|---|---|
| Backup Execution | Backup execution, logging, and validation behavior | [Backup execution](backup-execution.md) |
| Restore Validation | Recoverability testing and canary-based validation | [Restore validation](restore-validation.md) |
| Scheduler Behavior | Metadata-driven scheduler decisions under different conditions | [Scheduler behavior](scheduler-behavior.md) |

The evidence package also includes screenshots under `docs/evidence/images/` for backup execution, restore validation, and scheduler scenarios.

The purpose is not to prove that a backup command can run. The purpose is to demonstrate that the framework is **predictable, testable, traceable, and recoverable in practice**.

## Evidence boundary

Execution evidence reflects controlled SQL Server validation scenarios. It does not claim to prove infrastructure-level disaster recovery, storage resiliency, network resiliency, or high-availability behavior outside the framework's documented scope.
