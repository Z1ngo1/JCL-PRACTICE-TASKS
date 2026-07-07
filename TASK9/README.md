# Task 09 - Filter by Role and Reformat with INCLUDE + OUTREC BUILD (SORT)

## Overview

This job reads the employee dataset from TASK7, filters out only MANAGER records using the `INCLUDE` statement, and then reformats each matching record into a new layout using `OUTREC BUILD`. The output record contains FIRSTNAME, a space separator, SALARY, and the literal suffix `RUB`. All non-MANAGER records are dropped. The output record length changes from 36 to 20 bytes.

---

## Job Details

| Property  | Value     |
|-----------|-----------|
| Job Name  | `TASK9`   |
| Job Class | `A`       |
| MSGCLASS  | `A`       |
| MSGLEVEL  | `(1,1)`   |
| NOTIFY    | `&SYSUID` |

---

## Steps

| Step    | Program | Description                                                                                             |
|---------|---------|----------------------------------------------------------------------------------------------------------|
| STEP010 | IEFBR14 | Delete existing dataset [`TASK9.INCLOUTR.JCL`](DATA/TASK9.INCLOUTR.JCL.txt) if it exists                |
| STEP020 | SORT    | Read [`TASK7.INPUT.JCL`](DATA/TASK7.INPUT.JCL.txt), filter MANAGERs, reformat with OUTREC BUILD, output LRECL=20 |

---

## COND Logic

| Step    | COND Parameter         | Meaning                   |
|---------|------------------------|---------------------------|
| STEP010 | *(none)*               | Always runs               |
| STEP020 | `COND=(04,LT,STEP010)` | Skip if STEP010 RC > 4    |

---

## Input Data Layout

Record format: `LASTNAME(10) + FIRSTNAME(10) + ROLE(10) + SALARY(6)` - `LRECL=36`, `RECFM=FB`, `DSORG=PS`

| Field     | Position | Length | Format | Description          |
|-----------|----------|--------|--------|----------------------|
| LASTNAME  | 1        | 10     | CH     | Employee last name   |
| FIRSTNAME | 11       | 10     | CH     | Employee first name  |
| ROLE      | 21       | 10     | CH     | Job role             |
| SALARY    | 31       | 6      | CH     | Salary (zero-padded) |

### Input Dataset ([TASK7.INPUT.JCL.txt](DATA/TASK7.INPUT.JCL.txt))

```
IVANOV    IVAN      DEVELOPER 005000
PETROV    PETR      ANALYST   003200
SIDOROV   SERGEY    MANAGER   007800
KOZLOV    ALEXEY    DEVELOPER 004500
MOROZOV   DMITRY    ANALYST   002900
NOVIKOV   OLEG      DEVELOPER 006100
POPOV     ANDREY    MANAGER   008200
```

---

## Sort, Filter and Reformat Control Statements

```
SORT FIELDS=COPY
INCLUDE COND=(21,7,CH,EQ,C'MANAGER')
OUTREC BUILD=(11,10,C' ',31,6,C'RUB')
```

| Statement | Field     | Position | Length | Condition | Value       |
|-----------|-----------|----------|--------|-----------|-------------|
| SORT      | -         | -        | -      | COPY (no reorder) | -   |
| INCLUDE   | ROLE      | 21       | 7      | EQ        | `MANAGER`   |
| OUTREC    | FIRSTNAME | 11       | 10     | -         | output pos 1|
| OUTREC    | C' '      | literal  | 1      | -         | space separator |
| OUTREC    | SALARY    | 31       | 6      | -         | output pos 12|
| OUTREC    | C'RUB'    | literal  | 3      | -         | currency suffix |

Output record length: 10 + 1 + 6 + 3 = **20 bytes**

---

## Output Statistics from [SYSOUT.txt](OUTPUT/SYSOUT.txt)

```
ICE090I 0 OUTPUT LRECL = 20, BLKSIZE = 27980, TYPE = FB
ICE171I 0 SORTOUT LRECL OF 20 IS DIFFERENT FROM SORTIN(NN) LRECL OF 36 - RC=0
ICE055I 0 INSERT 0, DELETE 5
ICE054I 0 RECORDS - IN: 7, OUT: 2
```

5 out of 7 records were excluded - only MANAGER employees passed through.

### Filtered and Reformatted Result ([TASK9.INCLOUTR.JCL.txt](DATA/TASK9.INCLOUTR.JCL.txt))

```
SERGEY    007800RUB
ANDREY    008200RUB
```

Only SIDOROV (SERGEY) and POPOV (ANDREY) matched ROLE=MANAGER. LASTNAME and ROLE are dropped, salary is shown with `RUB` suffix.

---

## Key JCL Concepts Used

- **INCLUDE + OUTREC in a single SORT step** - filtering and reformatting happen together: only matching records are passed to OUTREC BUILD
- **INCLUDE COND on 7 bytes** - `MANAGER` is 7 characters, so length 7 is used to match exactly without trailing space issues
- **C'RUB' literal suffix in OUTREC** - appends a currency label directly to each output record
- **LRECL reduction via OUTREC** - input LRECL=36, output LRECL=20; ICE171I in SYSOUT is informational only

---

## Notes

- `SORT FIELDS=COPY` means no sorting is applied - records keep their original order, only filtering and reformatting.
- LASTNAME (bytes 1-10) and ROLE (bytes 21-30) are not referenced in OUTREC BUILD, so they are silently dropped.
- This task depends on TASK7 having already run and produced [`TASK7.INPUT.JCL`](DATA/TASK7.INPUT.JCL.txt) - no inline data is loaded here.
- ICE171I in SYSOUT is not an error - it is SORT informing that the output LRECL differs from input LRECL due to OUTREC reformatting.
