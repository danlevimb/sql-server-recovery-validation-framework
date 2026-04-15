<p align="center">
<a href="../../README.md">Home</a> |
<a href="../architecture.md">Architecture</a>
</p>

# Use Cases

## Overview

This section presents a set of **real-world recovery scenarios** designed to demonstrate how the framework handles different types of data incidents and operational requirements.

Each case reflects a common situation faced in production environments, including:

- human error  
- release failures  
- data inconsistency  
- recovery under uncertainty  

The goal is to showcase not only how backups are taken, but how they are **used effectively to recover, validate, and repair data**.

---

## Purpose

These use cases demonstrate the framework’s ability to:

- recover data using point-in-time strategies  
- restore environments aligned with business events  
- apply deterministic recovery methods  
- support operational and release processes  

---

## Recovery Approaches Covered

| Approach | Description | Use Case |
|--------|------------|--------|
| STOPAT | Time-based recovery using iterative analysis | [Recover data after accidental update](stopat-restore.md) |
| STOPBEFOREMARK | Marker-based recovery aligned with logical events | [Release rollback using transaction mark](stopbeforemark-restore.md) |

---
