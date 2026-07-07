# Task 12 - Multi-Step Job: SET Symbolic Variables, PARM and SORT OUTREC Report Header

## Overview

This is a multi-step pipeline job that demonstrates the use of JCL SET symbolic variables, PARM parameter passing, and SORT OUTREC BUILD to generate a formatted report. Employee records are loaded into a dataset referenced by symbolic variable [`&INFILE`](DATA/TASK12.INPUT.JCL.txt), filtered by salary greater than 004000 and sorted descending into [`&TMPFILE`](DATA/TASK12.TEMP.JCL.txt), then reformatted with a report date header and printed to SYSOUT.

---

## Job Details

| Property | Value |
|-----------|----------------|
| Job Name | `TASK12` |
| Job Class | `A` |
| MSGCLASS | `A` |
| MSGLEVEL | `(1,1)` |
| NOTIFY | `&SYSUID` |

---

## SET Symbolic Variables

| Variable | Value |
|------------|------------------------------|
| `&INFILE` | [`TASK12.INPUT.JCL`](DATA/TASK12.INPUT.JCL.txt) |
| `&TMPFILE` | [`TASK12.TEMP.JCL`](DATA/TASK12.TEMP.JCL.txt) |
| `&RPTFILE` | [`TASK12.REPORT.JCL`](DATA/TASK12.REPORT.JCL.txt) |

All DD statements in the job reference these symbolic names instead of hardcoded dataset names. Changing one SET statement updates all steps automatically.

---

## Steps

| Step | Program | Description |
|---------|----------|---------------------------------------------------------------------------------------------------------------|
| STEP010 | IEFBR14 | Delete existing datasets [`&INFILE`](DATA/TASK12.INPUT.JCL.txt), [`&RPTFILE`](DATA/TASK12.REPORT.JCL.txt), [`&TMPFILE`](DATA/TASK12.TEMP.JCL.txt) if they exist |
| STEP020 | IEBGENER | Load 10 inline employee records into [`&INFILE`](DATA/TASK12.INPUT.JCL.txt), LRECL=80 |
| STEP030 | SORT | Filter records with SALARY > 004000, sort by SALARY descending, save to [`&TMPFILE`](DATA/TASK12.TEMP.JCL.txt) |
| STEP040 | IEFBR14 | Practice PARM passing (`PARM='REPORT,20260525'`), create empty [`&RPTFILE`](DATA/TASK12.REPORT.JCL.txt) as placeholder |
| STEP050 | SORT | Reformat records from [`&TMPFILE`](DATA/TASK12.TEMP.JCL.txt) with OUTREC BUILD report header, print to SYSOUT |

---

## COND Logic

| Step | COND Parameter | Meaning |
|---------|--------------------------------------|----------------------------------------------------------|
| STEP010 | *(none)* | Always runs |
| STEP020 | `COND=(04,LT,STEP010)` | Skip if STEP010 RC > 4 |
| STEP030 | `COND=(04,LT,STEP020)` | Skip if STEP020 RC > 4 |
| STEP040 | `COND=(04,LT,STEP030)` | Skip if STEP030 RC > 4 |
| STEP050 | `COND=((00,NE,STEP030),(00,NE,STEP040))` | Skip if STEP030 RC != 0 OR STEP040 RC != 0 |

---

## Input Data Layout

Record format: `LASTNAME(10) + FIRSTNAME(10) + ROLE(10) + SALARY(6)` - `LRECL=80`, `RECFM=FB`, `DSORG=PS`

| Field | Position | Length | Format | Description |
|-----------|----------|--------|--------|----------------------|
| LASTNAME | 1 | 10 | CH | Employee last name |
| FIRSTNAME | 11 | 10 | CH | Employee first name |
| ROLE | 21 | 10 | CH | Job role |
| SALARY | 31 | 6 | CH | Salary (zero-padded) |

### Sample Input Records ([TASK12.INPUT.JCL.txt](DATA/TASK12.INPUT.JCL.txt))

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

## STEP030 - Filter and Sort Control Statements

```
SORT FIELDS=(31,6,CH,D)
INCLUDE COND=(31,6,CH,GT,C'004000')
```

| Statement | Field | Position | Length | Condition | Value |
|-----------|--------|----------|--------|-----------|-------|
| SORT | SALARY | 31 | 6 | Descending (D) | - |
| INCLUDE | SALARY | 31 | 6 | GT (greater than) | `004000` |

Records with SALARY <= 004000 are excluded: PETROV (003200), MOROZOV (002900), ORLOV (003100). KOZLOV (004500) is included because 004500 > 004000.

**Note:** SALARY is a character field. Character comparison works correctly here because all values are zero-padded to 6 digits, so lexicographic order matches numeric order.

---

## STEP040 - PARM Parameter

```
EXEC PGM=IEFBR14,COND=(04,LT,STEP030),PARM='REPORT,20260525'
```

IEFBR14 is a do-nothing program that immediately returns RC=0. The `PARM='REPORT,20260525'` string is passed to the program but ignored. This step demonstrates the PARM syntax and creates an empty `&RPTFILE` dataset as a report output placeholder.

---

## STEP050 - OUTREC BUILD Report Header Control Statements

```
SORT FIELDS=COPY
OUTREC BUILD=(C'REPORT DATE: 20260525 ',1,10,31,6)
```

| Segment | Source | Length | Description |
|---------|--------------|--------|-------------------------------------|
| C'REPORT DATE: 20260525 ' | Literal | 22 | Report date header prefix |
| 1,10 | Input pos 1 | 10 | LASTNAME |
| 31,6 | Input pos 31 | 6 | SALARY |

Output record length: 22 + 10 + 6 = **38 bytes**

---

## Final Result ([TASK12.TEMP.JCL.txt](DATA/TASK12.TEMP.JCL.txt))

7 records with SALARY > 004000, sorted descending, then reformatted with report header by STEP050:

```
REPORT DATE: 20260525 POPOV      008200
REPORT DATE: 20260525 SIDOROV    007800
REPORT DATE: 20260525 LEBEDEV    006800
REPORT DATE: 20260525 NOVIKOV    006100
REPORT DATE: 20260525 SOKOLOV    005500
REPORT DATE: 20260525 IVANOV     005000
REPORT DATE: 20260525 KOZLOV     004500
```

Printed to SYSOUT by STEP050 (SORT with OUTREC BUILD).

---

## Output

| File | Description |
|------|-------------|
| [SYSOUT.STEP030.txt](OUTPUT/SYSOUT.STEP030.txt) | SORT STEP030 sysout - filter SALARY > 004000 and sort descending |
| [SYSOUT.STEP050.txt](OUTPUT/SYSOUT.STEP050.txt) | SORT STEP050 sysout - OUTREC BUILD reformat messages |
| [SORTOUT.STEP050.txt](OUTPUT/SORTOUT.STEP050.txt) | Final formatted report with REPORT DATE header printed by STEP050 |

---

## Key JCL Concepts Used

- **SET symbolic variables** - `SET VAR='value'` at the JOB level defines symbols reused as `&VAR` in all DD statements throughout the job; changing one SET line updates all references
- **PARM parameter** - `EXEC PGM=pgmname,PARM='string'` passes a character string to the program at execution time; IEFBR14 ignores PARM but the syntax is valid and useful to practice
- **Character INCLUDE with GT** - `INCLUDE COND=(31,6,CH,GT,C'004000')` filters records where the 6-byte character field at position 31 is lexicographically greater than `004000`; works correctly for zero-padded numeric strings
- **OUTREC BUILD with literal** - `OUTREC BUILD=(C'text',pos,len,...)` prepends a literal string to each output record, used here to add a report date prefix to every line
- **Multi-condition COND** - `COND=((00,NE,STEP030),(00,NE,STEP040))` skips STEP050 if either STEP030 or STEP040 did not return RC=0

---

## Notes

- PETROV (003200), MOROZOV (002900), and ORLOV (003100) are excluded in STEP030 because their salary is not greater than 004000.
- KOZLOV (004500) passes the INCLUDE filter because character `004500` > character `004000` when all values are zero-padded to the same length.
- [`&RPTFILE`](DATA/TASK12.REPORT.JCL.txt) dataset created in STEP040 is empty - IEFBR14 only allocates the dataset but writes nothing to it. It serves as a placeholder for a real report writer program.
- STEP050 uses `SORTOUT DD SYSOUT=*` instead of a dataset DD - this sends the reformatted records directly to the system output class instead of saving to disk.
- The OUTREC literal `C'REPORT DATE: 20260525 '` is 22 characters (including trailing space) to align the name field at position 23 in the output record.
