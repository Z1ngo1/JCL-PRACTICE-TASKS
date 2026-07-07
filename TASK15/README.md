# Task 15 - Inner Join Two Files Using SORT JOINKEYS

## Overview

This job demonstrates SORT JOINKEYS to perform an inner join between two separate datasets. An employee file (ID + NAME) and a salary file (ID + SALARY) are created from inline data, then joined by the common ID field using SORT JOINKEYS. The output contains only records where a matching ID exists in both files. Employee ID 004 (KOZLOV) has no salary record and does not appear in the output.

---

## Job Details

| Property | Value |
|-----------|----------------|
| Job Name | `TASK15` |
| Job Class | `A` |
| MSGCLASS | `A` |
| MSGLEVEL | `(1,1)` |
| NOTIFY | `&SYSUID` |

---

## Steps

| Step | Program | Description |
|---------|----------|---------------------------------------------------------------------------------------------------------------|
| STEP010 | IEFBR14 | Delete existing datasets [`TASK15.EMPLS.JCL`](DATA/TASK15.EMPLS.JCL.txt), [`TASK15.SALARY.JCL`](DATA/TASK15.SALARY.JCL.txt), [`TASK15.JOIN.JCL`](DATA/TASK15.JOIN.JCL.txt) if they exist |
| STEP020 | IEBGENER | Load 6 inline employee records (ID + NAME) into [`TASK15.EMPLS.JCL`](DATA/TASK15.EMPLS.JCL.txt), LRECL=20 |
| STEP030 | IEBGENER | Load 5 inline salary records (ID + SALARY) into [`TASK15.SALARY.JCL`](DATA/TASK15.SALARY.JCL.txt), LRECL=9 |
| STEP040 | SORT | Inner join [`TASK15.EMPLS.JCL`](DATA/TASK15.EMPLS.JCL.txt) and [`TASK15.SALARY.JCL`](DATA/TASK15.SALARY.JCL.txt) by ID (pos 1-3), output to [`TASK15.JOIN.JCL`](DATA/TASK15.JOIN.JCL.txt), LRECL=25 |

---

## COND Logic

| Step | COND Parameter | Meaning |
|---------|--------------------------------------|----------------------------------------------------------|
| STEP010 | *(none)* | Always runs |
| STEP020 | `COND=(04,LT,STEP010)` | Skip if STEP010 RC > 4 |
| STEP030 | `COND=(04,LT,STEP010)` | Skip if STEP010 RC > 4 |
| STEP040 | `COND=((00,NE,STEP020),(00,NE,STEP030))` | Skip if STEP020 RC != 0 OR STEP030 RC != 0 |

---

## Input File Layouts

### File 1 - Employee File ([TASK15.EMPLS.JCL.txt](DATA/TASK15.EMPLS.JCL.txt))

Format: `ID(3) + NAME(17)` - `LRECL=20`, `RECFM=FB`, `DSORG=PS`

| Field | Position | Length | Description |
|-------|----------|--------|-------------|
| ID | 1 | 3 | Employee ID (zero-padded) |
| NAME | 4 | 17 | Employee name (last + first, space-padded) |

```
001IVANOV   IVAN
002PETROV   PETR
003SIDOROV  SERG
004KOZLOV   ALEX
005MOROZOV  DIMA
006NOVIKOV  OLEG
```

### File 2 - Salary File ([TASK15.SALARY.JCL.txt](DATA/TASK15.SALARY.JCL.txt))

Format: `ID(3) + SALARY(6)` - `LRECL=9`, `RECFM=FB`, `DSORG=PS`

| Field | Position | Length | Description |
|-------|----------|--------|-------------|
| ID | 1 | 3 | Employee ID (matches File 1) |
| SALARY | 4 | 6 | Salary (zero-padded) |

```
001005000
002003200
003007800
005002900
006006100
```

Note: ID 004 (KOZLOV) is present in the employee file but absent from the salary file.

---

## STEP040 - JOINKEYS Control Statements

```
JOINKEYS FILE=F1,FIELDS=(1,3,A)
JOINKEYS FILE=F2,FIELDS=(1,3,A)
REFORMAT FIELDS=(F1:1,3,F1:4,10,F2:4,6)
SORT FIELDS=COPY
```

| Statement | Description |
|-----------|-------------|
| `JOINKEYS FILE=F1,FIELDS=(1,3,A)` | Sort File 1 (SORTJNF1 = EMPLS) by ID at position 1, length 3, ascending |
| `JOINKEYS FILE=F2,FIELDS=(1,3,A)` | Sort File 2 (SORTJNF2 = SALARY) by ID at position 1, length 3, ascending |
| `REFORMAT FIELDS=(F1:1,3,F1:4,10,F2:4,6)` | Build output record from both files |
| `SORT FIELDS=COPY` | No additional sorting after join - preserve join order |

### REFORMAT Output Record Layout

| Segment | Source | Position in source | Length | Output position | Description |
|---------|--------|--------------------|--------|-----------------|-------------|
| F1:1,3 | EMPLS | 1 | 3 | 1 | Employee ID |
| F1:4,10 | EMPLS | 4 | 10 | 4 | Employee NAME (first 10 chars) |
| F2:4,6 | SALARY | 4 | 6 | 14 | SALARY |

Output record length: 3 + 10 + 6 = **19 bytes** (padded to LRECL=25)

---

## DD Names for JOINKEYS

| DD Name | Description |
|---------|-------------|
| `SORTJNF1` | File 1 input - replaces `SORTIN` for the first join file |
| `SORTJNF2` | File 2 input - replaces `SORTIN` for the second join file |
| `SORTOUT` | Output dataset for joined records |

---

## Final Result ([TASK15.JOIN.JCL.txt](DATA/TASK15.JOIN.JCL.txt))

5 records joined by ID (ID 004 KOZLOV excluded - no salary match):

```
001IVANOV   005000
002PETROV   003200
003SIDOROV  007800
005MOROZOV  002900
006NOVIKOV  006100
```

ICE421I in SYSOUT confirms: `JOINED RECORDS: COUNT=5`

---

## Output

| File | Description |
|------|-------------|
| [SYSOUT.STEP040.txt](OUTPUT/SYSOUT.STEP040.txt) | SORT STEP040 sysout - join statistics including ICE421I JOINED RECORDS: COUNT=5 |
| [JNF1JMSG.STEP040.txt](OUTPUT/JNF1JMSG.STEP040.txt) | JOINKEYS File 1 (EMPLS) sort messages |
| [JNF2JMSG.STEP040.txt](OUTPUT/JNF2JMSG.STEP040.txt) | JOINKEYS File 2 (SALARY) sort messages |

---

## Key JCL Concepts Used

- **SORT JOINKEYS** - performs a join operation between two input files; `JOINKEYS FILE=F1` and `JOINKEYS FILE=F2` specify the join key position and sort direction for each file independently
- **REFORMAT FIELDS** - defines the output record layout by selecting fields from both files using `F1:pos,len` and `F2:pos,len` notation; only fields explicitly listed are written to the output
- **Inner join behavior** - by default JOINKEYS performs an inner join: only records with matching key values in both files appear in the output; records with no match in either file are dropped silently
- **`SORTJNF1` / `SORTJNF2` DD names** - required DD names when using JOINKEYS; replace the usual `SORTIN` DD; each DD points to one of the two files being joined
- **IEBGENER GENERATE / RECORD** - `GENERATE MAXFLDS=1` and `RECORD FIELD=(len,input_pos,,output_pos)` control the exact byte layout when loading inline data into a fixed-length dataset
- **`ICE421I JOINED RECORDS: COUNT=n`** - SORT message in SYSOUT that reports the number of output records produced by the join operation

---

## Notes

- ID 004 (KOZLOV, ALEX) appears in the employee file but has no entry in the salary file. Because this is an inner join, KOZLOV is excluded from the output entirely.
- `JOINKEYS FIELDS=(1,3,A)` sorts both files by the ID field before joining. The files do not need to be pre-sorted - SORT handles sorting internally as part of the join process.
- `REFORMAT FIELDS=(F1:1,3,F1:4,10,F2:4,6)` takes 3 bytes from F1 position 1 (ID), 10 bytes from F1 position 4 (NAME truncated to 10), and 6 bytes from F2 position 4 (SALARY). Total = 19 bytes written into LRECL=25 dataset.
- STEP020 and STEP030 both depend only on STEP010 (`COND=(04,LT,STEP010)`) and run independently of each other - they can both create their files in parallel if STEP010 succeeds.
- `JNF1JMSG` and `JNF2JMSG` DD names in the OUTPUT are JOINKEYS diagnostic message DDs automatically allocated by SORT during the join operation.
