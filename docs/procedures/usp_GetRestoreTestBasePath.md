<p align="center">
<a href="/README.md">Home</a> |
<a href="../../sql/01_Tables.md">Tables</a> |
<a href="../../sql/02_Procedures.md">Procedures</a>
</p>

---

# cfg.usp_GetRestoreTestBasePath

> Restore Layer - Planning

## Overview

`cfg.usp_GetRestoreTestBasePath` resolves the active base path used for restore test operations.

It acts as a thin wrapper around [`[cfg].[usp_GetActiveBasePath]`](../../docs/procedures/usp_GetActiveBasePath.md), providing a simplified and intention-revealing interface for components that need to work specifically with the `RESTORE_TEST` path type.

This keeps restore test workflows easier to read while preserving centralized path resolution and validation logic.

## Responsibilities

- Resolve the active restore test base path  
- Delegate storage resolution and validation to [`[cfg].[usp_GetActiveBasePath]`](../../docs/procedures/usp_GetActiveBasePath.md)
- Provide a simplified interface for restore test workflows  
- Improve readability of restore-related procedures  

## Parameters

| Parameter | Type | Description |
|----------|------|-------------|
| @BasePath | NVARCHAR(260) OUTPUT | Resolved and validated restore test base path returned by the procedure. |

## Execution Flow

The procedure follows a minimal execution pattern:

1. Invoke [`[cfg].[usp_GetActiveBasePath]`](../../docs/procedures/usp_GetActiveBasePath.md)
2. Request the `RESTORE_TEST` path type  
3. Return the resolved and validated base path through the output parameter  

## Example Usage

```sql
DECLARE @BasePath NVARCHAR(260);

EXEC cfg.usp_GetRestoreTestBasePath
    @BasePath = @BasePath OUTPUT;

SELECT @BasePath AS RestoreTestBasePath;
```
## Outputs

The procedure returns a single resolved value through the output parameter.

## Related Components
- [`[cfg].[usp_GetActiveBasePath]`](../../docs/procedures/usp_GetActiveBasePath.md) → Storage resolution and validation engine
- [`[cfg].[usp_RestorePointInTime]`](../../docs/procedures/usp_RestorePointInTime.md) → Restore execution engine

## Design Notes

This procedure intentionally wraps [`[cfg].[usp_GetActiveBasePath]`](../../docs/procedures/usp_GetActiveBasePath.md) to make restore test path resolution more explicit and easier to consume.

Although the logic is minimal, the procedure improves readability by expressing intent directly in the calling code.

## Source Code

[View full implementation](../../sql/cfg/usp_GetRestoreTestBasePath.sql)

---

<p align="center">
<a href="/README.md">Home</a> |
<a href="../../sql/01_Tables.md">Tables</a> |
<a href="../../sql/02_Procedures.md">Procedures</a>
</p>
