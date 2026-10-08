# Visual Package

This directory contains the visual layer for the SQL Server Recovery & Validation Framework.

## Assets

```text
diagrams/
├── banner.png
├── framework-architecture.png
├── recovery-validation-timeline.png
└── scheduling_model.png
```

| Asset | Role |
|---|---|
| `banner.png` | README hero / project identity |
| `framework-architecture.png` | Framework architecture and component relationships |
| `recovery-validation-timeline.png` | Point-in-time / marker-based recovery validation timeline |
| `scheduling_model.png` | Metadata-driven backup scheduling model |

## Visual discipline

The diagrams support the implemented SQL Server reliability story:

- FULL / DIFF / LOG backup behavior;
- metadata-driven scheduling;
- restore-chain planning;
- `STOPAT` and `STOPBEFOREMARK`;
- canary-based validation;
- operational telemetry.

They must not imply capabilities outside the documented scope, such as infrastructure-level disaster recovery, storage/network remediation, or HA/replication orchestration.

Screenshots and execution proof remain under `docs/evidence/`.
