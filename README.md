<p align="center">
  <img src="diagrams/banner.png" width="900"/>
</p>

<p align="center">
  <h1>SQL Server Recovery & Validation Framework</h1><br/>
  Deterministic recovery for real-world data incidents
</p>

---

## The problem

In most environments:

- backups are successfully generated  
- recovery is assumed and rarely tested  
- incident response relies on guesswork  

When failure occurs, teams often cannot answer:

- Is the backup chain valid?  
- Can we recover to the exact required point?  
- How do we restore data without breaking the system?  

---

## The idea

A backup is only valuable if it can be **recovered with certainty**.

This framework transforms backup operations into:

- deterministic recovery processes  
- testable validation scenarios  
- evidence-driven workflows  

---

## What this Framework solves

This project focuses on **real recovery problems**, not just backup execution.

It provides solutions for:

- 🔍 **Forensic Recovery (STOPAT)**  
  Recover data when the exact incident time is unknown, using iterative validation  

- 🎯 **Deterministic Rollback (STOPBEFOREMARK)**  
  Restore systems to a precise logical boundary aligned with business events  

- 📊 **Recovery Validation**  
  Prove that backups are not only created, but **recoverable and consistent**  

---

## Technical Scope

This framework operates on:

- SQL Server transaction log (LSN-based recovery)  
- Backup chain validation (FULL / DIFF / LOG)  
- `msdb` metadata analysis  
- Deterministic restore orchestration  

---

## Repository Structure

| Section | Description |
|--------|------------|
| [Architecture](docs/architecture.md) | Framework design and recovery strategies |
| [Evidence](docs/evidence/evidence.md) | Execution proof (backups, restores, validation) |
| [Use cases](docs/use-cases/use-cases.md) | Real-world recovery scenarios |
| [Procedures](sql/02_Procedures.md) | Core implementation stored procedures |
| [Tables](sql/01_Tables.md) | Core implementation tables |

---

## Design Principles

- Deterministic recovery over best-effort approaches  
- Example of Non-destructive repair strategies  
- Evidence-driven validation  
- Alignment with operational workflows  

---

## Philosophy

Recovery should not depend on:

- assumptions  
- timestamps provided by users  
- or untested backup chains  

Recovery must be:

- predictable  
- verifiable  
- aligned with real-world system behavior  

---

## Summary

This project focuses on improving recovery strategies by minimizing the time required to determine the correct recovery point after a failure.

Restore chain construction should not rely on manual effort or guesswork. It can be deterministic, reliable, and fully automated.
