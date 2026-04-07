<p align="center">
<a href="/README.md">Home</a> |
<a href="../docs/architecture.md">Architecture</a>
</p>

# Examples

This section demonstrates practical usage scenarios of the framework across its main operational stages:

- Backup Execution  
- Restore Operations  
- Recovery Validation  

Each example reflects real-world situations where the framework can be applied independently or as part of an integrated workflow.

---

# Backup Stage

### 1. Batch Backup Execution by Tier

Execute backups for all databases within a specific Tier.

```sql
EXEC cfg.usp_BackupByTierAndType
    @BackupType = 'FULL',
    @TierID = 1,
    @PathType = 'PRIMARY',
    @WithCompression = 1,
    @WithChecksum = 1;
