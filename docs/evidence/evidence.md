<p align="center">
<a href="../../README.md">Home</a> |
<a href="../architecture.md">Architecture</a> |
<a href="../use-cases/use-cases.md">Use Cases</a>
</p>

# Evidence

This section contains **execution evidence** demonstrating how the framework operates under real conditions.

It provides step-by-step validation of:

| Section | Description | Link |
|---------|-------------|------|
| Backup Execution | Demonstrates how backups are generated and validated through a complete execution flow. | [here](./backup-execution.md) |
| Restore Validation | Validates that backups are recoverable and consistent, using canary-based testing. | [here](./restore-validation.md) |
| Scheduling Behavior |Shows how the scheduler behaves under different operational conditions. | [here](./schedule-behavior.md) |

The goal is to prove that the framework is not only designed correctly, but **works deterministically in practice** proving the framework is predictable, testable and auditable, capable of supporting **real-world backup and recovery operations**.
