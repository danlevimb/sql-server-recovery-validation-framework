<p align="center">
<a href="README.md">Home</a> |
<a href="../architecture.md">Back</a>
</p>

# Ecosystem Context

The framework operates on top of an existing SQL Server backup ecosystem and assumes the presence of a structured environment where backup generation, storage, and metadata tracking are already in place.

Rather than introducing a new backup mechanism, the solution integrates with these existing components to perform restore validation and recoverability analysis.

### SQL Server Instance

The framework is designed to work with one or more SQL Server instances hosting databases of different criticality levels, such as:

- Production databases  
- Critical business databases  
- Test or staging environments  

These databases are the source of backup generation and the origin of restore validation scenarios.

---

### Backup Generation (SQL Server Agent Jobs)

Backups are assumed to be generated automatically through scheduled jobs, typically implemented using SQL Server Agent.

These jobs execute backup procedures that produce:

- FULL backups (`.bak`)  
- DIFFERENTIAL backups (`.bak`)  
- TRANSACTION LOG backups (`.trn`)  

The framework does not depend on a specific implementation, but it can integrate seamlessly with standardized procedures such as `[cfg].[usp_BackupDatabase]` or `[cfg].[usp_BackupByTierAndType]`, which also provide execution traceability.

---

### Backup Storage

Backup files are written to predefined storage locations that are logically separated by purpose. A typical configuration includes:

- **PRIMARY** → main backup storage location  
- **SECONDARY** → optional mirrored or redundant storage  
- **RESTORE_TEST** → isolated location used for restore validation scenarios  

These paths are abstracted through the configuration layer (`cfg.BackupPaths`), allowing the framework to dynamically resolve storage locations without hardcoded dependencies.

---

### System Metadata

The framework relies heavily on SQL Server system metadata to reconstruct restore chains and determine recovery boundaries.

Key sources include:

- `msdb.dbo.backupset`  
- `msdb.dbo.backupmediafamily`  
- `msdb.dbo.logmarkhistory`  
- `sys.fn_dump_dblog`  

These components provide:

- Backup history and file locations  
- LSN continuity and chain validation  
- Marked transaction metadata  
- Transaction-level commit time boundaries  

This metadata-driven approach enables deterministic selection of backup files and precise point-in-time recovery.

---

### Execution Context

The framework is typically deployed within a dedicated database (e.g., `DBAFramework`) that contains:

- Configuration tables (`cfg.*`)  
- Stored procedures for orchestration and execution  
- Logging and telemetry tables (`log.*`)  

However, validation artifacts such as canary records (`dbo.PitrCanary`) are created within the source databases being tested, allowing the framework to validate recovery behavior directly at the data level.

---

### Summary

In this ecosystem, the framework acts as a **non-intrusive validation layer** that leverages existing backup processes, storage, and metadata to continuously verify that recovery objectives can be met in practice.

It does not generate backups by itself; instead, it ensures that existing backups are **usable, consistent, and recoverable to the desired point in time**.
