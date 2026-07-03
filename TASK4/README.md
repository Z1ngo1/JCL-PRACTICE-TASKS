# Task 04 - Sort TASK3 Output by Last Name (SORT)

## Overview

This job sorts the output dataset produced by TASK3 by employee last name in ascending order. It reuses [`TASK3.OUTPUT.JCL`](DATA/TASK3.OUTPUT.JCL.txt) directly as input without reloading any inline data, demonstrating how jobs can chain together across tasks.

---

## Job Details

| Property  | Value     |
|-----------|-----------|
| Job Name  | `TASK4`   |
| Job Class | `A`       |
| MSGCLASS  | `A`       |
| MSGLEVEL  | `(1,1)`   |
| NOTIFY    | `&SYSUID` |

---

## Steps

| Step    | Program | Description                                                              |
|---------|---------|--------------------------------------------------------------------------|
| STEP005 | IEFBR14 | Delete existing dataset [`TASK4.SORT.JCL`](DATA/TASK4.SORT.JCL.txt) if it exists            |
| STEP010 | SORT    | Sort [`TASK3.OUTPUT.JCL`](DATA/TASK3.OUTPUT.JCL.txt) by last name (pos 1-10) ascending        |

---

## COND Logic

| Step    | COND Parameter         | Meaning                        |
|---------|------------------------|--------------------------------|
| STEP005 | *(none)*               | Always runs                    |
| STEP010 | `COND=(04,LT,STEP005)` | Skip if STEP005 RC > 4         |

---

## Input Data Layout

Record format: `NAME(10) + FIRSTNAME(10) + ROLE(10)` - `LRECL=30`, `RECFM=FB`, `DSORG=PS`

| Field     | Position | Length | Format | Description         |
|-----------|----------|--------|--------|---------------------|
| NAME      | 1        | 10     | CH     | Employee last name  |
| FIRSTNAME | 11       | 10     | CH     | Employee first name |
| ROLE      | 21       | 10     | CH     | Job role            |

### Input Dataset ([TASK3.OUTPUT.JCL.txt](DATA/TASK3.OUTPUT.JCL.txt))

```
IVANOV    IVAN      DEVELOPER 
PETROV    PETR      ANALYST   
SIDOROV   SERGEY    MANAGER   
KOZLOV    ALEXEY    DEVELOPER 
MOROZOV   DMITRY    ANALYST   
```

---

## Sort Control Statement

```
SORT FIELDS=(1,10,CH,A)
```

| Key | Position | Length | Type | Order     | Field |
|-----|----------|--------|------|-----------|-------|
| 1st | 1        | 10     | CH   | Ascending | NAME  |

---

## Output

Statistics from [SYSOUT.txt](OUTPUT/SYSOUT.txt):

```
ICE090I 0 OUTPUT LRECL = 30, BLKSIZE = 27990, TYPE = FB
ICE080I 0 IN MAIN STORAGE SORT
ICE055I 0 INSERT 0, DELETE 0
ICE054I 0 RECORDS - IN: 5, OUT: 5
```

### Sorted Result ([TASK4.SORT.JCL.txt](DATA/TASK4.SORT.JCL.txt))

```
IVANOV    IVAN      DEVELOPER 
KOZLOV    ALEXEY    DEVELOPER 
MOROZOV   DMITRY    ANALYST   
PETROV    PETR      ANALYST   
SIDOROV   SERGEY    MANAGER   
```

All 5 records sorted alphabetically by last name.

---

## Key JCL Concepts Used

- **Cross-task dataset reuse** - SORTIN reads [`TASK3.OUTPUT.JCL`](DATA/TASK3.OUTPUT.JCL.txt) directly, linking TASK4 to the output of TASK3
- **SORT FIELDS on NAME** - single-key sort on a character field at position 1, length 10
- **DCB specified on SORTOUT** - LRECL=30 explicitly set because SORTOUT is a new dataset with no existing DCB to inherit

---

## Notes

- This task has no inline data - it depends on TASK3 having already run and produced [`TASK3.OUTPUT.JCL`](DATA/TASK3.OUTPUT.JCL.txt).
- STEP005 only deletes the SORT output dataset, not the TASK3 input - that belongs to TASK3 to manage.
- LRECL=30 on SORTOUT matches the record length established in TASK3, keeping the chain consistent.
