# Architecture
<p align="center">
<a href="README.md">Home</a> |
<a href="docs/architecture.md">Architecture</a> |
<a href="telemetry.md">Telemetry</a> |
<a href="restore-workflow.md">Restore Workflow</a>
</p>

---

<p align="center">
  <img src="/diagrams/framework-architecture.png" width="900">
</p>

The framework integrates with an existing SQL Server backup ecosystem and performs deterministic restore validation using a modular recovery pipeline composed of four main procedures.

--- 

## a) Ecosystem

It is recomended to use an exclusive Database for this purpose, in wich 

The framework assumes the existence of a **structured backup environment** in which SQL Server backups are generated automatically through scheduled jobs.

These jobs are typically executed through **SQL Server Agent** and invoke specialized stored procedures responsible for generating backups according to the desired backup strategy.

For this project `[cfg].[usp_BackupDatabase]` creates the files in desired path and stores `[dbo].[BackupRun]`


---
 (From dump log)|

---
