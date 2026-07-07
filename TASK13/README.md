# Task 13 - Instream PROC with Symbolic Parameters, SORT and DD Concatenation

## Overview

This job demonstrates an instream catalogued procedure (FILTPROC) with symbolic parameters. FILTPROC filters records by a role value and sorts them by salary descending into a temporary dataset. The main job calls FILTPROC twice - once for DEVELOPER and once for MANAGER - then concatenates both output datasets and prints the result to SYSOUT using IEBGENER.

---

## Job Details

| Property | Value |
|-----------|----------------|
| Job Name | `TASK13` |
| Job Class | `A` |
| MSGCLASS | `A` |
| MSGLEVEL | `(1,1)` |
| NOTIFY | `&SYSUID` |
| EXPORT | `SYMLIST=(ROLE)` |

---

## Instream PROC: FILTPROC

```
//FILTPROC PROC ROLE=,OUTDSN=
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `&ROLE` | *(empty)* | Role value used in INCLUDE filter (e.g. `DEVELOPER ` or `MANAGER `) |
| `&OUTDSN` | *(empty)* | Name of the temporary output dataset to create |

FILTPROC contains one step (STEP1) that runs SORT. It reads `&&ALLIN` (passed from the main job), filters by `&ROLE`, sorts by SALARY descending, and writes results to `&OUTDSN`. The proc ends with `PEND`.

---

## Steps

| Step | Program | Description |
|---------|----------|---------------------------------------------------------------------------------------------------------------|
| STEP010 | SORT | Load 10 inline employee records, copy to temporary dataset `&&ALLIN` using `SORT FIELDS=COPY` |
| STEP020 | FILTPROC | Call FILTPROC with `ROLE='DEVELOPER '`, output to `&&DEVOUT` - filters DEVELOPERs, sorts by SALARY desc |
| STEP030 | FILTPROC | Call FILTPROC with `ROLE='MANAGER '`, output to `&&MGROUT` - filters MANAGERs, sorts by SALARY desc |
| STEP040 | IEBGENER | Concatenate `&&DEVOUT` and `&&MGROUT` via DD concatenation, print to SYSOUT |

---

## COND Logic

| Step | COND Parameter | Meaning |
|---------|----------------------------------------------|----------------------------------------------------------|
| STEP010 | *(none)* | Always runs |
| STEP020 | *(none)* | Always runs |
| STEP030 | *(none)* | Always runs |
| STEP040 | `COND=((00,NE,STEP020.STEP1),(00,NE,STEP030.STEP1))` | Skip if STEP020.STEP1 or STEP030.STEP1 RC != 0 |

---

## Input Data Layout

Record format: `LASTNAME(10) + FIRSTNAME(10) + ROLE(10) + SALARY(6)` - `LRECL=80`, `RECFM=FB`, `DSORG=PS`

| Field | Position | Length | Format | Description |
|-----------|----------|--------|--------|----------------------|
| LASTNAME | 1 | 10 | CH | Employee last name |
| FIRSTNAME | 11 | 10 | CH | Employee first name |
| ROLE | 21 | 10 | CH | Job role |
| SALARY | 31 | 6 | CH | Salary (zero-padded) |

### Sample Input Records (inline in STEP010)

```
IVANOV     IVAN       DEVELOPER  005000
PETROV     PETR       ANALYST    003200
SIDOROV    SERGEY     MANAGER    007800
KOZLOV     ALEXEY     DEVELOPER  004500
MOROZOV    DMITRY     ANALYST    002900
NOVIKOV    OLEG       DEVELOPER  006100
POPOV      ANDREY     MANAGER    008200
SOKOLOV    DENIS      DEVELOPER  005500
LEBEDEV    ROMAN      MANAGER    006800
ORLOV      NIKITA     ANALYST    003100
```

---

## FILTPROC - SORT Control Statements

```
SORT FIELDS=(31,6,CH,D)
INCLUDE COND=(21,10,CH,EQ,C'&ROLE')
```

`//SYSIN DD *,SYMBOLS=JCLONLY` - the `SYMBOLS=JCLONLY` keyword tells the system to substitute JCL symbolic parameters (`&ROLE`) inside the instream SYSIN data before passing it to SORT.

| Statement | Field | Position | Length | Condition | Value |
|-----------|--------|----------|--------|-----------|-------|
| SORT | SALARY | 31 | 6 | Descending (D) | - |
| INCLUDE | ROLE | 21 | 10 | EQ | `&ROLE` (substituted at runtime) |

---

## STEP040 - DD Concatenation

```
//SYSUT1 DD DSN=&&DEVOUT,DISP=(OLD,DELETE)
//       DD DSN=&&MGROUT,DISP=(OLD,DELETE)
```

Two DD statements with the same DD name (`SYSUT1`) form a concatenation. IEBGENER reads them sequentially - first all records from `&&DEVOUT`, then all records from `&&MGROUT` - and writes the combined output to SYSOUT. Both temporary datasets are deleted after reading.

---

## Final Result

7 records (4 DEVELOPER + 3 MANAGER), each group sorted by salary descending, concatenated and printed by STEP040:

```
NOVIKOV    OLEG       DEVELOPER  006100
SOKOLOV    DENIS      DEVELOPER  005500
IVANOV     IVAN       DEVELOPER  005000
KOZLOV     ALEXEY     DEVELOPER  004500
POPOV      ANDREY     MANAGER    008200
SIDOROV    SERGEY     MANAGER    007800
LEBEDEV    ROMAN      MANAGER    006800
```

ANALYST records (PETROV, MOROZOV, ORLOV) are excluded because FILTPROC is never called with `ROLE='ANALYST '`.

---

## Output

| File | Description |
|------|-------------|
| [SYSOUT.STEP010.txt](OUTPUT/SYSOUT.STEP010.txt) | SORT STEP010 sysout - copy all records to `&&ALLIN` |
| [SYSOUT.STEP020.STEP1.txt](OUTPUT/SYSOUT.STEP020.STEP1.txt) | FILTPROC STEP020.STEP1 sysout - filter DEVELOPER, sort by SALARY desc |
| [SYSOUT.STEP030.STEP1.txt](OUTPUT/SYSOUT.STEP030.STEP1.txt) | FILTPROC STEP030.STEP1 sysout - filter MANAGER, sort by SALARY desc |
| [SYSUT2.STEP040.txt](OUTPUT/SYSUT2.STEP040.txt) | Final concatenated output printed by IEBGENER STEP040 |

---

## Key JCL Concepts Used

- **Instream PROC** - a procedure defined inline within the same JCL job between the JOB statement and the first EXEC step; begins with `//procname PROC` and ends with `// PEND`
- **PROC symbolic parameters** - `PROC ROLE=,OUTDSN=` declares parameters with empty defaults; values are passed when calling the proc with `EXEC FILTPROC,ROLE='DEVELOPER ',OUTDSN=&&DEVOUT`
- **`SYMBOLS=JCLONLY`** - DD keyword that enables JCL symbolic substitution inside instream data (SYSIN); without it, `&ROLE` would not be replaced in the SORT control statements
- **`EXPORT SYMLIST=(ROLE)`** - JOB statement keyword that allows the `ROLE` symbol defined outside the proc to be visible inside the proc's SYSIN data
- **Proc step COND reference** - `COND=(00,NE,STEP020.STEP1)` references a specific step inside a proc call using `jobstep.procstep` notation
- **DD concatenation** - multiple DD statements with the same DD name read sequentially as one logical file; used here to combine `&&DEVOUT` and `&&MGROUT` into a single SYSUT1 input for IEBGENER

---

## Notes

- ANALYST records are never extracted because FILTPROC is only called for DEVELOPER and MANAGER roles.
- `ROLE='DEVELOPER '` is padded to 10 characters with trailing spaces to match the fixed-length ROLE field at position 21, length 10.
- `&&ALLIN` is created in STEP010 with `DISP=(NEW,PASS,DELETE)` and consumed in STEP020 and STEP030. In STEP030 the SORTIN DD overrides the proc's default to `DISP=(OLD,DELETE)` so `&&ALLIN` is deleted after STEP030 reads it.
- The PROC step is named `STEP1` inside FILTPROC. When referenced in COND, it uses the compound name `STEP020.STEP1` and `STEP030.STEP1`.
- There is no DATA folder for this task - all input data is provided inline in STEP010 SORTIN.
