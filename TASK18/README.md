# Task 18 - IDCAMS Dataset Management (DELETE, ALLOCATE, REPRO)

## Overview

This job demonstrates IDCAMS dataset management operations: deleting a non-VSAM dataset with SCRATCH PURGE, allocating a new sequential file via IEFBR14, and loading inline employee records using IDCAMS REPRO. The job includes conditional execution logic to skip steps based on previous step return codes.

---

## Job Details

| Property | Value |
|-----------|----------------|
| Job Name | `TASK18` |
| Job Class | `A` |
| MSGCLASS | `A` |
| MSGLEVEL | `(1,1)` |
| NOTIFY | `&SYSUID` |

---

## Steps

| Step | Program | Description |
|---------|----------|---------------------------------------------------------------------------------------------------------------|
| STEP010 | IDCAMS | Delete dataset [`TASK18.JCL.EMPFILE`](DATA/TASK18.JCL.EMPFILE.txt) if it exists (NONVSAM SCRATCH PURGE); set MAXCC=0 if RC <= 8 |
| STEP020 | IEFBR14 | Allocate new sequential file [`TASK18.JCL.EMPFILE`](DATA/TASK18.JCL.EMPFILE.txt), LRECL=80; skip if STEP010 RC > 8 |
| STEP030 | IDCAMS | Load 5 inline employee records into [`TASK18.JCL.EMPFILE`](DATA/TASK18.JCL.EMPFILE.txt) via REPRO; skip if STEP020 RC != 0 |

---

## COND Logic

| Step | COND Parameter | Meaning |
|---------|----------------------|----------------------------------------------------------|
| STEP010 | *(none)* | Always runs |
| STEP020 | `COND=(08,LT,STEP010)` | Skip if STEP010 RC > 8 |
| STEP030 | `COND=(00,NE,STEP020)` | Skip if STEP020 RC != 0 |

---

## STEP010 - IDCAMS DELETE

**SYSIN control statements:**
```
DELETE Z73460.TASK18.JCL.EMPFILE NONVSAM SCRATCH PURGE
IF LASTCC <= 8 THEN SET MAXCC = 0
```

| Statement | Description |
|-----------|-------------|
| `DELETE ... NONVSAM` | Delete a non-VSAM dataset |
| `SCRATCH` | Remove dataset entry from VTOC (Volume Table of Contents) |
| `PURGE` | Override expiration date protection - delete immediately even if dataset is not expired |
| `IF LASTCC <= 8 THEN SET MAXCC = 0` | If RC <= 8, override MAXCC to 0; RC=8 (dataset not found) is acceptable |

---

## STEP030 - IDCAMS REPRO

`COND=(00,NE,STEP020)` - Skip if STEP020 RC != 0

Loads inline employee data into the target dataset using IDCAMS REPRO.

**Inline Data (INDD):**

| Last Name | First Name | Position | Salary |
|-----------|------------|----------|--------|
| IVANOV | IVAN | DEVELOPER | 005000 |
| PETROV | PETR | ANALYST | 003200 |
| SIDOROV | SERGEY | MANAGER | 007800 |
| KOZLOV | ALEXEY | DEVELOPER | 004500 |
| MOROZOV | DMITRY | ANALYST | 002900 |

**SYSIN control statements:**
```
REPRO INFILE(INDD) -
     OUTFILE(OUTDD)
```

| Statement | Description |
|-----------|-------------|
| `REPRO` | Copy records from input to output |
| `INFILE(INDD)` | Input DD name - references inline data |
| `OUTFILE(OUTDD)` | Output DD name - references target dataset |

---

## Final Result ([TASK18.JCL.EMPFILE.txt](DATA/TASK18.JCL.EMPFILE.txt))

5 employee records loaded into the dataset:

```
IVANOV     IVAN       DEVELOPER  005000
PETROV     PETR       ANALYST    003200
SIDOROV    SERGEY     MANAGER    007800
KOZLOV     ALEXEY     DEVELOPER  004500
MOROZOV    DMITRY     ANALYST    002900
```

---

## Output

| File | Description |
|------|-------------|
| [SYSOUT.STEP010.txt](OUTPUT/SYSOUT.STEP010.txt) | IDCAMS DELETE messages - dataset deleted or not found (RC=8) |
| [SYSOUT.STEP030.txt](OUTPUT/SYSOUT.STEP030.txt) | IDCAMS REPRO messages - 5 records copied |

---

## Key JCL Concepts Used

- **IDCAMS DELETE NONVSAM** - Deletes a non-VSAM dataset; commonly used to clean up old datasets before creating new ones
- **SCRATCH PURGE** - `SCRATCH` removes the dataset entry from the VTOC; `PURGE` bypasses expiration date protection to force immediate deletion
- **IF LASTCC <= 8 THEN SET MAXCC = 0** - Conditional IDCAMS statement that resets the maximum condition code; RC=8 (dataset not found) is treated as success since the goal is to ensure the dataset does not exist
- **IEFBR14** - A null program (no operation) commonly used to allocate or delete datasets via DD statements without processing data
- **IDCAMS REPRO** - Copies records from one dataset to another; supports inline data via INFILE(DD) and OUTFILE(DD) references
- **COND parameter** - Controls conditional step execution based on previous step return codes; prevents wasted processing when prerequisites fail

---

## Notes

- STEP010 uses `IF LASTCC <= 8 THEN SET MAXCC = 0` to treat RC=8 (dataset not found) as success. This is a best practice when deleting datasets that may or may not exist.
- `COND=(08,LT,STEP010)` in STEP020 means "skip if 8 is less than STEP010's RC", i.e., skip if RC > 8. This prevents file allocation if STEP010 encountered an unexpected error (RC > 8).
- STEP030 uses IDCAMS REPRO instead of IEBGENER. Both utilities can copy data, but REPRO is part of the IDCAMS toolkit and supports VSAM datasets in addition to sequential files.
- The inline data in STEP030 is space-aligned but not explicitly formatted with IEBGENER control statements. REPRO copies the data as-is from the input DD.
- `SPACE=(TRK,(1,1))` allocates 1 primary track with 1 secondary track for expansion. Tracks are physical allocation units on disk.
- `DISP=(NEW,CATLG,DELETE)` in STEP020 ensures the dataset is cataloged (registered in the system catalog) on successful completion, making it accessible by dataset name in future jobs.
