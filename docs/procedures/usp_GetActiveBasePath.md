<p align="center">
<a href="/README.md">Home</a> |
<a href="../../sql/01_Tables.md">Tables</a> |
<a href="../../sql/02_Procedures.md">Procedures</a>
</p>

---

# cfg.usp_GetActiveBasePath

> *Storage Layer - Resolution*
> 
## Overview

`cfg.usp_GetActiveBasePath` resolves the effective base path used by the framework for backup and restore operations.

In addition to resolving the active storage path based on configuration, the procedure performs early validation to ensure that the selected path exists and is usable as a directory.

This approach centralizes path resolution and validation logic, allowing downstream components to operate with a consistent and reliable storage reference.

## Responsibilities

- Resolve the active base path for a given path type  
- Normalize the returned storage path  
- Validate that the resolved path exists and is a directory  
- Fail early when storage configuration is invalid  
- Provide a deterministic storage reference to backup and restore components  

## Parameters

| Parameter | Type | Description |
|----------|------|-------------|
| @PathType | VARCHAR(30) | Logical path type to resolve (for example `PRIMARY`, `SECONDARY`, or `RESTORE_TEST`). |
| @BasePath | NVARCHAR(260) OUTPUT | Resolved and validated base path returned by the procedure. |

## Execution Flow

The procedure follows a simple but deterministic resolution pattern:

1. Normalize the input `@PathType`  
2. Retrieve the active base path from [`[cfg].[BackupPaths]`](../../sql/01_Tables/cfg.BackupPaths.md)
3. Validate that a configuration entry exists  
4. Validate that the path is not empty  
5. Normalize the path to ensure trailing separator consistency  
6. Validate that the resolved path exists and is a valid directory  
7. Return the resolved base path  

## Example Usage

```sql
DECLARE @BasePath NVARCHAR(260);

EXEC cfg.usp_GetActiveBasePath
    @PathType = 'RESTORE_TEST',
    @BasePath = @BasePath OUTPUT;

SELECT @BasePath AS ResolvedBasePath;
```
## Outputs

The procedure returns a single resolved value through the output parameter.

## Related Components
- [`[cfg].[BackupPaths]`](../../sql/01_Tables/cfg.BackupPaths.md) → Stores active path configuration
- [`[cfg].[usp_BackupDatabase]`](../../docs/procedures/usp_BackupDatabase.md) → Backup execution engine
- [`[cfg].[usp_GetRestoreTestBasePath]`](../../docs/procedures/usp_GetRestoreTestBasePath.md) → Restore test path resolution
- [`[cfg].[usp_GetLatestBackupFiles]`](../../docs/procedures/usp_GetLatestBackupFiles.md) → Restore planning engine

## Design Notes

This procedure combines path resolution and early path validation in order to keep the framework cohesive and easier to navigate.

In larger enterprise implementations, validation logic could be separated into a dedicated infrastructure validation component. In this project, it is intentionally integrated here to reduce complexity and improve readability without sacrificing reliability.

## Source Code
[View full implementation](../../sql/cfg/usp_GetActiveBasePath.sql)

---

<p align="center">
<a href="/README.md">Home</a> |
<a href="../../sql/01_Tables.md">Tables</a> |
<a href="../../sql/02_Procedures.md">Procedures</a>
</p>
