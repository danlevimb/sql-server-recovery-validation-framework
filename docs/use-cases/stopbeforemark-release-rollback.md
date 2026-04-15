<p align="center">
<a href="../../README.md">Home</a> |
<a href="../architecture.md">Architecture</a> |
<a href="../examples/examples.md">Examples</a>
</p>

# STOPBEFOREMARK Restore for Release Rollback

---

## Overview

This use case demonstrates a **deterministic rollback strategy** using transaction marks (`STOPBEFOREMARK`) to recover a database to a precise logical point.

Unlike time-based recovery (`STOPAT`), this approach enables:

- exact rollback to a known business event  
- deterministic recovery without approximation  
- alignment with release management processes  

---

## Business context

The QA team is preparing a **major release deployment** in a pre-production environment.

As part of the release process:

- deployment scripts are executed  
- data transformations are applied  
- validation scenarios are tested  

To ensure recoverability, a **transaction mark** is created before deployment.

---

## Incident Ticket

```text
🎫
Incident ID:   REL-2026-0415-ROLLBACK
Date/Hour:     14-Apr-26 06:45 pm
Environment:   Pre-Production  
Service:       Order Management System  
Requested by:  QA Team  
Severity:      High  

SUMMARY:
  Request to rollback test environment to pre-release state.

DETAILED DESCRIPTION:
  A major release deployment was executed in an incorrect sequence, causing inconsistencies in the test environment.

  The QA team reports:
    - data inconsistencies after deployment  
    - failed validation scenarios  
    - unstable environment for testing  

MARKER INFO:
  The deployment process included a transaction mark: Release_2026_04

REQUESTED ACTION:
  Restore the database to the exact state before the marked transaction, ensuring:
    - complete rollback of release changes
    - preservation of pre-release data state
    - deterministic recovery
```

### Problem Statement

The system must:

- rollback all changes introduced after the release
- avoid time-based approximation
- ensure exact recovery aligned with the release boundary

### Recovery Strategy

This scenario uses `STOPBEFOREMARK` instead of: `STOPAT`

| Method | Precision | Use Case |
|--------|-----------|----------|
| STOPAT |	Approximate |	Incident recovery|
| STOPBEFOREMARK |	Exact|	Controlled events (releases, deployments)|

### Execution Timeline
|Time |	Event |
|-----|-------|
|10:00|	System stable|
|15:43|	Transaction mark created|
|16:00|	Release scripts executed|
|17:00|	Data inconsistencies appear|
|18:00|	QA reports issue|

### Timeline Visualization
```text 
TIME ─────────────────────────────────────────▶

VALID STATE ───▶ [MARK] ───▶ RELEASE ───▶ BROKEN STATE
                     ▲
                     │
              STOPBEFOREMARK
Marker Creation (Simulated)
```
### Mark creation
```sql
BEGIN TRAN Release_2026_04 WITH MARK N'Release_2026_04';

-- Simulated release changes
UPDATE app.Orders
SET Amount = Amount * 1;

COMMIT;
```
### Verify mark
<p align="center">
  <img src="images/Mark_Creation.JPG" width="900">
</p>


Restore Execution
EXEC cfg.usp_RestorePointInTime
    @SourceDatabase = 'LabCriticalDB',
    @TargetDatabase = 'LabCriticalDB_StopBeforeMark',
    @StopBeforeMark = 'Release_2026_04',
    @DoCheckDB = 1,
    @ReplaceTarget = 1;

📸 [INSERT SCREENSHOT]

Evidence — Restored State

📸 [INSERT SCREENSHOT]

SELECT TOP (50)
    OrderID,
    Amount,
    OrderCreatedAt
FROM LabCriticalDB_StopBeforeMark.app.Orders
ORDER BY OrderCreatedAt DESC;
Validation Logic

The restored database must satisfy:

DATA BEFORE MARK → EXISTS ✅
MARK TRANSACTION → NOT APPLIED ❌
POST-RELEASE DATA → NOT PRESENT ❌
Validation Queries
Compare Production vs Restored
SELECT 
    p.OrderID,
    p.Amount AS ProductionAmount,
    r.Amount AS RestoredAmount
FROM LabCriticalDB.app.Orders p
JOIN LabCriticalDB_StopBeforeMark.app.Orders r
    ON p.OrderID = r.OrderID
WHERE ISNULL(p.Amount,0) <> ISNULL(r.Amount,0);

📸 [INSERT SCREENSHOT]

Key Insights
Transaction marks provide logical recovery boundaries
STOPBEFOREMARK eliminates ambiguity present in time-based recovery
This approach aligns database recovery with business events
It is ideal for release rollback scenarios
Why STOPBEFOREMARK Was Required

Time-based recovery introduces approximation and uncertainty.

Transaction mark-based recovery allows:

deterministic rollback
exact alignment with deployment boundaries
safer recovery in controlled operations
Integration with Release Process

Transaction marks can be integrated into deployment workflows:

pre-release mark creation
deployment execution
rollback capability via STOPBEFOREMARK

This enables a robust and auditable release strategy.

Summary

This use case demonstrates:

precise recovery using transaction marks
rollback of release changes
alignment of database recovery with release engineering

It highlights the importance of combining:

backup strategy
transaction marking
deterministic restore logic

to achieve reliable and predictable recovery outcomes.

Final Outcome

✔ Release rollback successfully executed
✔ Environment restored to pre-release state
✔ No ambiguity in recovery boundary
✔ Data integrity preserved

