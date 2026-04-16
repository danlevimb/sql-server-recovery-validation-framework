<p align="center">
  <h1 align="center">SQL Server Data Recovery Framework</h1>
  <p align="center">
    Deterministic recovery, validation, and repair for real-world data incidents.
  </p>
</p>

---

## The problem

In most environments:

- backups are successfully generated  
- recovery is rarely tested  
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

## Real-World Scenarios

The framework is validated through practical [use cases](/docs/use-cases/use-cases.md):

- Accidental data corruption (UPDATE without WHERE)  
- Release rollback using transaction marks  
- Recovery under uncertainty and delayed detection  

These scenarios simulate **real production incidents**, not theoretical examples.

---

## Repository Structure

| Section | Description |
|--------|------------|
| [`Architecture`](docs/architecture.md) | Framework design and recovery strategies |
| [`Evidence`]() | Execution proof (backups, restores, validation) |
| [`Use cases`]() | Real-world recovery scenarios |
| [`Procedures`]() | Core implementation stored procedures |
| [`Tables`]() | Core implementation tables |

---

## Design Principles

- Deterministic recovery over best-effort approaches  
- Non-destructive repair strategies  
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

This project demonstrates how to move from:

❌ “We have backups”  
to  
✔ “We can recover — reliably, precisely, and safely”  

---

## Final Thought

Reliable systems are not defined by how often they fail,  
but by how predictably they recover.
