# Task 11 - Multi-Step Job: OUTFIL Split, ICETOOL Count and SORT Merge

## Overview

This is a multi-step pipeline job that splits employee records into separate DEVELOPER and MANAGER datasets using SORT OUTFIL, counts DEVELOPER records using ICETOOL, merges the two datasets back by salary descending using SORT MERGE, and prints the merged result to SYSOUT. The final print step always runs regardless of previous step outcomes.

---

## Job Details

| Property | Value |
|-----------|----------------|
| Job Name | `TASK11` |
| Job Class | `A` |
| MSGCLASS | `A` |
| MSGLEVEL | `(1,1)` |
| NOTIFY | `&SYSUID` |

---

## Steps

| Step | Program | Description |
|---------|----------|---------------------------------------------------------------------------------------------------------------|
| STEP010 | IEFBR14 | Delete existing datasets [`TASK11.INITIAL.JCL`](DATA/TASK11.INITIAL.JCL.txt), [`TASK11.DEVS.JCL`](DATA/TASK11.DEVS.JCL.txt), [`TASK11.MGRS.JCL`](DATA/TASK11.MGRS.JCL.txt), [`TASK11.DEVSCNT.JCL`](DATA/TASK11.DEVSCNT.JCL.txt), [`TASK11.MERGED.JCL`](DATA/TASK11.MERGED.JCL.txt) if they exist |
| STEP020 | IEBGENER | Load 10 inline employee records into [`TASK11.INITIAL.JCL`](DATA/TASK11.INITIAL.JCL.txt), LRECL=80 |
| STEP030 | SORT | Sort all records by SALARY descending, split into [`TASK11.DEVS.JCL`](DATA/TASK11.DEVS.JCL.txt) (DEVELOPER) and [`TASK11.MGRS.JCL`](DATA/TASK11.MGRS.JCL.txt) (MANAGER) using OUTFIL |
| STEP040 | ICETOOL | Count records in [`TASK11.DEVS.JCL`](DATA/TASK11.DEVS.JCL.txt) and write count to [`TASK11.DEVSCNT.JCL`](DATA/TASK11.DEVSCNT.JCL.txt) |
| STEP050 | SORT | Merge [`TASK11.DEVS.JCL`](DATA/TASK11.DEVS.JCL.txt) and [`TASK11.MGRS.JCL`](DATA/TASK11.MGRS.JCL.txt) by SALARY descending into [`TASK11.MERGED.JCL`](DATA/TASK11.MERGED.JCL.txt) |
| STEP060 | IEBGENER | Print [`TASK11.MERGED.JCL`](DATA/TASK11.MERGED.JCL.txt) to SYSOUT - runs even if previous steps failed (`COND=EVEN`) |

---

## COND Logic

| Step | COND Parameter | Meaning |
|---------|------------------------|------------------------------------------------------|
| STEP010 | *(none)* | Always runs |
| STEP020 | `COND=(04,LT,STEP010)` | Skip if STEP010 RC > 4 |
| STEP030 | `COND=(04,LT,STEP020)` | Skip if STEP020 RC > 4 |
| STEP040 | `COND=(00,NE,STEP030)` | Skip if STEP030 RC is not 0 (run only on clean sort) |
| STEP050 | `COND=(00,NE,STEP040)` | Skip if STEP040 RC is not 0 (run only on clean count) |
| STEP060 | `COND=EVEN` | Always runs - even if any previous step abended |

---

## Input Data Layout

Record format: `LASTNAME(10) + FIRSTNAME(10) + ROLE(10) + SALARY(6)` - `LRECL=80`, `RECFM=FB`, `DSORG=PS`

| Field | Position | Length | Format | Description |
|-----------|----------|--------|--------|----------------------|
| LASTNAME | 1 | 10 | CH | Employee last name |
| FIRSTNAME | 11 | 10 | CH | Employee first name |
| ROLE | 21 | 10 | CH | Job role |
| SALARY | 31 | 6 | CH | Salary (zero-padded) |

### Sample Input Records ([TASK11.INITIALJCL.txt](DATA/TASK11.INITIAL.JCL.txt))

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

## STEP030 - OUTFIL Split and Sort Control Statements

```
SORT FIELDS=(31,6,CH,D)
OUTFIL FNAMES=OUT1,INCLUDE=(21,9,CH,EQ,C'DEVELOPER')
OUTFIL FNAMES=OUT2,INCLUDE=(21,7,CH,EQ,C'MANAGER')
```

| Statement | Output | Condition | Value |
|-----------|--------|-----------|-------|
| SORT | Both | SALARY pos 31, len 6, Descending | - |
| OUTFIL OUT1 | DEVS.JCL | ROLE pos 21, len 9, EQ | `DEVELOPER` |
| OUTFIL OUT2 | MGRS.JCL | ROLE pos 21, len 7, EQ | `MANAGER` |

ANALYST records (PETROV, MOROZOV, ORLOV) are excluded from both output files - they do not match either OUTFIL condition.

---

## STEP040 - ICETOOL Count Control Statements

```
COUNT FROM(IN) WRITE(CNTDD)
```

| Operand | DD Name | Dataset |
|---------|---------|---------|
| FROM | IN | TASK11.DEVS.JCL |
| WRITE | CNTDD | TASK11.DEVSCNT.JCL |

ICETOOL counted **4 DEVELOPER records** and wrote the count to [`TASK11.DEVSCNT.JCL`](DATA/TASK11.DEVSCNT.JCL.txt).

---

## STEP050 - SORT MERGE Control Statements

```
MERGE FIELDS=(31,6,CH,D)
```

Merges `SORTIN01` (DEVS.JCL) and `SORTIN02` (MGRS.JCL) into a single dataset sorted by SALARY descending. ANALYST records were already excluded in STEP030 so they do not appear in the merged output.

---

## Final Result ([TASK11.MERGEDJCL.txt](DATA/TASK11.MERGED.JCL.txt))

7 records (4 DEVELOPER + 3 MANAGER) merged by salary descending, printed by STEP060:

```
POPOV      ANDREY     MANAGER    008200
SIDOROV    SERGEY     MANAGER    007800
LEBEDEV    ROMAN      MANAGER    006800
NOVIKOV    OLEG       DEVELOPER  006100
SOKOLOV    DENIS      DEVELOPER  005500
IVANOV     IVAN       DEVELOPER  005000
KOZLOV     ALEXEY     DEVELOPER  004500
```

Printed to SYSOUT by STEP060 (IEBGENER with COND=EVEN).

---

## Output

| File | Description |
|------|-------------|
| [SYSOUT.STEP030.txt](OUTPUT/SYSOUT.STEP030.txt) | SORT STEP030 sysout - OUTFIL split by DEVELOPER and MANAGER |
| [SYSOUT.STEP050.txt](OUTPUT/SYSOUT.STEP050.txt) | SORT STEP050 sysout - MERGE by SALARY descending |
| [DFSMSG.STEP040.txt](OUTPUT/DFSMSG.STEP040.txt) | ICETOOL STEP040 DFSMSG - data facility messages |
| [TOOLMSG.STEP040.txt](OUTPUT/TOOLMSG.STEP040.txt) | ICETOOL STEP040 TOOLMSG - count result: 4 DEVELOPER records |
| [SYSUT2.STEP060.txt](OUTPUT/SYSUT2.STEP060.txt) | Final merged output printed by IEBGENER STEP060 (COND=EVEN) |

---

## Key JCL Concepts Used

- **SORT OUTFIL** - splits one input dataset into multiple output datasets in a single SORT step; each OUTFIL statement defines a separate output file with its own INCLUDE filter
- **ICETOOL COUNT** - counts records in an input dataset and writes the numeric count to an output dataset; uses `FROM(ddname)` and `WRITE(ddname)` operands
- **SORT MERGE** - combines two or more pre-sorted input datasets (`SORTIN01`, `SORTIN02`) into one sorted output without re-sorting; requires `MERGE FIELDS=` instead of `SORT FIELDS=`
- **`COND=EVEN`** - STEP060 always executes regardless of previous step return codes or abends, ensuring the print step always runs
- **`COND=(00,NE,STEPxxx)`** - chained dependency: each step runs only if the previous step ended with RC=0, creating a clean pipeline

---

## Notes

- ANALYST records (PETROV, MOROZOV, ORLOV) are excluded in STEP030 because neither OUTFIL condition matches ANALYST - they are dropped silently.
- OUTFIL uses `INCLUDE=(21,9,CH,EQ,C'DEVELOPER')` (9 chars) and `INCLUDE=(21,7,CH,EQ,C'MANAGER')` (7 chars) to match exact role name lengths in the fixed-length field.
- STEP050 uses `SORTIN01` and `SORTIN02` DD names instead of `SORTIN` - this is required for SORT MERGE with multiple input files.
- TOOLMSG message ICE628I shows `RECORD COUNT: 00000000000000004` confirming 4 DEVELOPER records counted by ICETOOL.
- STEP060 uses `SYSIN DD DUMMY` meaning IEBGENER does a straight copy from [`TASK11.MERGED.JCL`](DATA/TASK11.MERGED.JCL.txt) to SYSOUT with no editing.
