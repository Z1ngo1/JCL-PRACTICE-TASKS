# Task 08 - Swap and Reorder Fields with OUTREC BUILD (SORT)

## Overview

This job reads the employee dataset produced by TASK7 and reorders its fields into a new layout using SORT's `OUTREC BUILD` statement. The original field order LASTNAME + FIRSTNAME + ROLE + SALARY is swapped so SALARY comes first, followed by LASTNAME and ROLE, with pipe delimiters inserted between them. FIRSTNAME is dropped entirely. The output record length changes from 36 to 28 bytes.

---

## Job Details

| Property  | Value     |
|-----------|-----------|
| Job Name  | `TASK8`   |
| Job Class | `A`       |
| MSGCLASS  | `A`       |
| MSGLEVEL  | `(1,1)`   |
| NOTIFY    | `&SYSUID` |

---

## Steps

| Step    | Program | Description                                                                                    |
|---------|---------|------------------------------------------------------------------------------------------------|
| STEP010 | IEFBR14 | Delete existing dataset [`TASK8.SWAP.JCL`](DATA/TASK8.SWAP.JCL.txt) if it exists              |
| STEP020 | SORT    | Read [`TASK7.INPUT.JCL`](DATA/TASK7.INPUT.JCL.txt) and reorder fields using OUTREC BUILD, output LRECL=28 |

---

## COND Logic

| Step    | COND Parameter         | Meaning                   |
|---------|------------------------|---------------------------|
| STEP010 | *(none)*               | Always runs               |
| STEP020 | `COND=(04,LT,STEP010)` | Skip if STEP010 RC > 4    |

---

## Input Data Layout

Record format: `LASTNAME(10) + FIRSTNAME(10) + ROLE(10) + SALARY(6)` - `LRECL=36`, `RECFM=FB`, `DSORG=PS`

| Field     | Position | Length | Format | Description         |
|-----------|----------|--------|--------|---------------------|
| LASTNAME  | 1        | 10     | CH     | Employee last name  |
| FIRSTNAME | 11       | 10     | CH     | Employee first name |
| ROLE      | 21       | 10     | CH     | Job role            |
| SALARY    | 31       | 6      | CH     | Salary (zero-padded)|

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

## OUTREC BUILD Logic

```
SORT FIELDS=COPY
OUTREC BUILD=(31,6,C'|',1,10,C'|',21,10)
```

| Segment | Source        | Length | Description                        |
|---------|---------------|--------|------------------------------------|
| 31,6    | Input pos 31  | 6      | SALARY                             |
| C'\|'   | Literal       | 1      | Pipe delimiter                     |
| 1,10    | Input pos 1   | 10     | LASTNAME                           |
| C'\|'   | Literal       | 1      | Pipe delimiter                     |
| 21,10   | Input pos 21  | 10     | ROLE (FIRSTNAME at 11-20 is skipped)|

Output record length: 6 + 1 + 10 + 1 + 10 = **28 bytes**

---

## Output Statistics from [SYSOUT.txt](OUTPUT/SYSOUT.txt)

```
ICE090I 0 OUTPUT LRECL = 28, BLKSIZE = 27972, TYPE = FB
ICE171I 0 SORTOUT LRECL OF 28 IS DIFFERENT FROM SORTIN(NN) LRECL OF 36 - RC=0
ICE055I 0 INSERT 0, DELETE 0
ICE054I 0 RECORDS - IN: 7, OUT: 7
```

All 7 records reformatted with fields swapped. ICE171I is informational - SORT detected the LRECL change from 36 to 28.

### Swapped Result ([TASK8.SWAP.JCL.txt](DATA/TASK8.SWAP.JCL.txt))

```
005000|IVANOV    |DEVELOPER 
003200|PETROV    |ANALYST   
007800|SIDOROV   |MANAGER   
004500|KOZLOV    |DEVELOPER 
002900|MOROZOV   |ANALYST   
006100|NOVIKOV   |DEVELOPER 
008200|POPOV     |MANAGER   
```

SALARY now leads each record, FIRSTNAME is gone, pipes separate the fields.

---

## Key JCL Concepts Used

- **OUTREC BUILD with field reordering** - unlike TASK6/TASK7 where fields kept their relative order, here SALARY (pos 31) is moved to the front of the output record
- **Cross-task dataset reuse** - SORTIN reads [`TASK7.INPUT.JCL`](DATA/TASK7.INPUT.JCL.txt) directly, no inline data loaded in this job
- **Multiple C'|' literals in OUTREC** - two pipe delimiters inserted at different positions to separate three fields
- **LRECL reduction via OUTREC** - input LRECL=36, output LRECL=28; ICE171I in SYSOUT is informational only

---

## Notes

- `SORT FIELDS=COPY` means no sorting is applied - records keep their original order, only the layout changes.
- FIRSTNAME (bytes 11-20) is not referenced in OUTREC BUILD, so it is silently dropped from the output.
- This task depends on TASK7 having already run and produced [`TASK7.INPUT.JCL`](DATA/TASK7.INPUT.JCL.txt) - no inline data is loaded here.
- ICE171I in SYSOUT is not an error - it is SORT informing that the output LRECL differs from input LRECL due to OUTREC reformatting.
