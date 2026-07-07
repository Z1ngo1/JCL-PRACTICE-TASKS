# Task 16 - Left Outer Join Two Files Using SORT JOINKEYS (UNPAIRED F1)

## Overview

This job demonstrates SORT JOINKEYS to perform a left outer join between two separate datasets. An employee file (ID + NAME) and a salary file (ID + SALARY) are created from inline data, then joined by the common ID field using SORT JOINKEYS with the UNPAIRED,F1 option. The output contains all records from the employee file. Records with no matching salary entry are included with the salary field filled with `000000`. Employees 004 (KOZLOV) and 007 (SMIRNOV) have no salary record and appear in the output with salary `000000`.

---

## Job Details

| Property | Value |
|-----------|----------------|
| Job Name | `TASK16` |
| Job Class | `A` |
| MSGCLASS | `A` |
| MSGLEVEL | `(1,1)` |
| NOTIFY | `&SYSUID` |

---

## Steps

| Step | Program | Description |
|---------|----------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| STEP010 | IEFBR14 | Delete existing datasets [`TASK16.EMPLLIST.JCL`](DATA/TASK16.EMPLLIST.JCL.txt), [`TASK16.SALARY.JCL`](DATA/TASK16.SALARY.JCL.txt), [`TASK16.RESULT.JCL`](DATA/TASK16.RESULT.JCL.txt) if they exist |
| STEP020 | IEBGENER | Load 7 inline employee records (ID + NAME) into [`TASK16.EMPLLIST.JCL`](DATA/TASK16.EMPLLIST.JCL.txt), LRECL=20 |
| STEP030 | IEBGENER | Load 6 inline salary records (ID + SALARY) into [`TASK16.SALARY.JCL`](DATA/TASK16.SALARY.JCL.txt), LRECL=9 |
| STEP040 | SORT | Left outer join [`TASK16.EMPLLIST.JCL`](DATA/TASK16.EMPLLIST.JCL.txt) and [`TASK16.SALARY.JCL`](DATA/TASK16.SALARY.JCL.txt) by ID (pos 1-3), output to [`TASK16.RESULT.JCL`](DATA/TASK16.RESULT.JCL.txt), LRECL=26 |

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

### File 1 - Employee File ([TASK16.EMPLLIST.JCL.txt](DATA/TASK16.EMPLLIST.JCL.txt))

Format: `ID(3) + NAME(17)` - `LRECL=20`, `RECFM=FB`, `DSORG=PS`

| Field | Position | Length | Description |
|-------|----------|--------|-------------|
| ID | 1 | 3 | Employee ID (zero-padded) |
| NAME | 4 | 17 | Employee name (last + first, space-padded) |

```
001IVANOV    IVAN
002PETROV    PETR
003SIDOROV   SERG
004KOZLOV    ALEX
005MOROZOV   DIMA
006NOVIKOV   OLEG
007SMIRNOV   PAVL
```

### File 2 - Salary File ([TASK16.SALARY.JCL.txt](DATA/TASK16.SALARY.JCL.txt))

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
008004400
```

Note: IDs 004 (KOZLOV) and 007 (SMIRNOV) are present in the employee file but absent from the salary file. ID 008 exists only in the salary file and will be excluded from the output.

---

## STEP040 - JOINKEYS Control Statements

```
SORT FIELDS=COPY
JOINKEYS FILE=F1,FIELDS=(1,3,A)
JOINKEYS FILE=F2,FIELDS=(1,3,A)
JOIN UNPAIRED,F1
REFORMAT FIELDS=(F1:1,20,F2:4,6),FILL=C'0'
```

| Statement | Description |
|-----------|-------------|
| `JOINKEYS FILE=F1,FIELDS=(1,3,A)` | Sort File 1 (SORTJNF1 = EMPLLIST) by ID at position 1, length 3, ascending |
| `JOINKEYS FILE=F2,FIELDS=(1,3,A)` | Sort File 2 (SORTJNF2 = SALARY) by ID at position 1, length 3, ascending |
| `JOIN UNPAIRED,F1` | Left outer join - keep all F1 records even if no match exists in F2 |
| `REFORMAT FIELDS=(F1:1,20,F2:4,6),FILL=C'0'` | Build output record from both files; fill missing F2 salary with `000000` |
| `SORT FIELDS=COPY` | No additional sorting after join - preserve join order |

### REFORMAT Output Record Layout

| Segment | Source | Position in source | Length | Output position | Description |
|---------|--------|--------------------|--------|-----------------|-------------|
| F1:1,20 | EMPLLIST | 1 | 20 | 1 | Full employee record (ID + NAME) |
| F2:4,6 | SALARY | 4 | 6 | 21 | SALARY (or `000000` if no match) |

Output record length: 20 + 6 = **26 bytes** (LRECL=26)

---

## DD Names for JOINKEYS

| DD Name | Description |
|---------|-------------|
| `SORTJNF1` | File 1 input - replaces `SORTIN` for the first join file |
| `SORTJNF2` | File 2 input - replaces `SORTIN` for the second join file |
| `SORTOUT` | Output dataset for joined records |

---

## Final Result ([TASK16.RESULT.JCL.txt](DATA/TASK16.RESULT.JCL.txt))

7 records - all employees included; missing salaries filled with `000000`:

```
001IVANOV    IVAN  005000
002PETROV    PETR  003200
003SIDOROV   SERG  007800
004KOZLOV    ALEX  000000
005MOROZOV   DIMA  002900
006NOVIKOV   OLEG  006100
007SMIRNOV   PAVL  000000
```

ICE421I in SYSOUT confirms: `JOINED RECORDS: COUNT=7`

---

## Output

| File | Description |
|------|-------------|
| [SYSOUT.STEP040.txt](OUTPUT/SYSOUT.STEP040.txt) | SORT STEP040 sysout - join statistics including ICE421I JOINED RECORDS: COUNT=7 |
| [JNF1JMSG.STEP040.txt](OUTPUT/JNF1JMSG.STEP040.txt) | JOINKEYS File 1 (EMPLLIST) sort messages - 7 records in, LRECL=20 |
| [JNF2JMSG.STEP040.txt](OUTPUT/JNF2JMSG.STEP040.txt) | JOINKEYS File 2 (SALARY) sort messages - 6 records in, LRECL=9 |

---

## Key JCL Concepts Used

- **SORT JOINKEYS with UNPAIRED,F1** - performs a left outer join between two input files; all records from F1 are written to output regardless of whether a matching key exists in F2; unmatched F2 records are silently discarded
- **REFORMAT FIELDS with FILL** - defines the output record layout by selecting fields from both files using `F1:pos,len` and `F2:pos,len` notation; when no F2 match exists, the F2 portion is replaced by the character specified in `FILL=C'0'`
- **Left outer join behavior** - `JOIN UNPAIRED,F1` causes all F1 records to appear in output; records in F1 with no F2 match get their F2 fields filled with the FILL value; F2 records with no F1 match are dropped
- **`SORTJNF1` / `SORTJNF2` DD names** - required DD names when using JOINKEYS; replace the usual `SORTIN` DD; each DD points to one of the two files being joined
- **IEBGENER GENERATE / RECORD** - `GENERATE MAXFLDS=1` and `RECORD FIELD=(len,input_pos,,output_pos)` control the exact byte layout when loading inline data into a fixed-length dataset
- **`ICE421I JOINED RECORDS: COUNT=n`** - SORT message in SYSOUT that reports the number of output records produced by the join operation

---

## Notes

- IDs 004 (KOZLOV, ALEX) and 007 (SMIRNOV, PAVL) appear in the employee file but have no entry in the salary file. Because this is a left outer join, both are included in the output with salary field `000000`.
- ID 008 exists in the salary file only. Because this is a left outer join (`UNPAIRED,F1`), unmatched F2 records are discarded - ID 008 does not appear in the output.
- `JOINKEYS FIELDS=(1,3,A)` sorts both files by the ID field before joining. The files do not need to be pre-sorted - SORT handles sorting internally as part of the join process.
- `REFORMAT FIELDS=(F1:1,20,F2:4,6),FILL=C'0'` takes 20 bytes from F1 position 1 (full employee record) and 6 bytes from F2 position 4 (SALARY). Total = 26 bytes written into LRECL=26 dataset.
- `SPACE=(TRK,(1,0))` in STEP010 prevents the step from failing when a dataset to be deleted does not yet exist.
- `JNF1JMSG` and `JNF2JMSG` DD names in the OUTPUT are JOINKEYS diagnostic message DDs automatically allocated by SORT during the join operation.
- `ICE054I 0 RECORDS - IN: 0, OUT: 7` in SYSOUT is expected for JOINKEYS output - the IN counter reflects direct SORTIN records; joined output flows through the join pipeline separately.
