<p align="center">
<a href="README.md">Home</a> |
<a href="../architecture.md">Back</a>
</p>

# Restore Chain Planning

The framework implements a deterministic approach to restore chain construction by leveraging SQL Server backup metadata and transaction log analysis.

This process ensures that restore operations are executed using a valid and complete sequence of backup files, aligned with the intended recovery boundary.

---

### Chain Composition

A restore chain is constructed using the following sequence:

1. **FULL backup**  
2. **Optional DIFFERENTIAL backup** (if applicable)  
3. **Transaction LOG backups** (as required)  

The framework dynamically determines which components are required based on the selected recovery scenario.

---

### FULL Backup Selection

The process begins by identifying the most appropriate FULL backup:

- The selected FULL must precede the recovery target (`STOPAT` or `MARK`)  
- It serves as the base for the entire restore chain  
- Its `checkpoint_lsn` is used to validate compatibility with subsequent backups  

This ensures that all subsequent restore steps are anchored to a consistent baseline.

---

### DIFFERENTIAL Backup Alignment

When a DIFFERENTIAL backup is used, it must be aligned with the selected FULL backup.

The framework enforces this relationship using:

- `database_backup_lsn` (from the DIFFERENTIAL backup)  
- `checkpoint_lsn` (from the FULL backup)  

A DIFFERENTIAL backup is only considered valid if:

```sql
database_backup_lsn = FULL.checkpoint_lsn
```
This guarantees that the differential backup is derived from the selected FULL and can be safely applied.

---

### Transaction Log Chain Continuity

Transaction log backups are selected to complete the restore chain up to the desired recovery point.

The framework enforces strict LSN continuity:

```sql
current.first_lsn = previous.last_lsn
```

This validation ensures:

- No gaps in the transaction log sequence
- No overlap or inconsistency in the restore chain
- Reliable reconstruction of database state

---

### Recovery Boundary Resolution

The framework supports two types of recovery boundaries:

Point-in-Time (`STOPAT`)
The system identifies the log backup that contains the target timestamp
Commit time boundaries are analyzed using `sys.fn_dump_dblog`
The appropriate log is selected to ensure the target time is covered

If necessary, the effective recovery point may be adjusted to the nearest valid commit boundary.

---

### Marker-Based (`STOPBEFOREMARK`)
The system uses `msdb.dbo.logmarkhistory` to locate the marked transaction
The corresponding `mark_lsn` is retrieved
The correct log backup containing the mark is selected

This enables deterministic recovery to a specific business event.

---

### Commit Boundary Validation

For point-in-time recovery, the framework evaluates transaction commit boundaries using:

- `MinCommitTime`
- `MaxCommitTime`

These values are derived from `sys.fn_dump_dblog` and allow the system to:

- Confirm that a log backup contains the desired recovery point
- Adjust the effective recovery boundary when necessary
- Avoid invalid or partial restores

---

### Deterministic Chain Construction

By combining metadata and log analysis, the framework ensures that:

- Every restore chain is valid and complete
- Recovery boundaries are respected and verified
- Backup selection is reproducible and consistent

This eliminates ambiguity in restore operations and reduces reliance on manual intervention.

---

### Summary

Restore chain planning is a critical component of the framework, transforming backup metadata into a reliable and executable recovery sequence.

Through strict LSN validation, metadata alignment, and commit boundary analysis, the system guarantees that restore operations are not only possible, but deterministic and verifiable.
