# Task 05 - Filter Employees by Role: DEVELOPER Only (SORT)

## Overview

This job loads a list of employees and filters out all records where the role is not DEVELOPER. It uses `SORT FIELDS=COPY` with an `INCLUDE` condition - no reordering happens, records are simply copied straight through if they match, and dropped if they do not.

---

## Job Details

| Property  | Value     |
|-----------|-----------|
| Job Name  | `TASK5`   |
| Job Class | `A`       |
| MSGCLASS  | `A`       |
| MSGLEVEL  | `(1,1)`   |
| NOTIFY    | `&SYSUID` |

---

## Steps

| Step    | Program  | Description                                                                                   |
|---------|----------|-----------------------------------------------------------------------------------------------|
| STEP005 | IEFBR14  | Delete existing datasets [`TASK5.INPUT.JCL`](DATA/TASK5.INPUT.JCL.txt) and [`TASK5.SORT.JCL`](DATA/TASK5.SORT.JCL.txt) if they exist  |
| STEP010 | IEBGENER | Load inline data, trim records to LRECL=30 using GENERATE/RECORD FIELD                        |
| STEP015 | SORT     | Filter records: keep only those where ROLE=DEVELOPER, copy order unchanged                    |

---

## COND Logic

| Step    | COND Parameter         | Meaning                        |
|---------|------------------------|--------------------------------|
| STEP005 | *(none)*               | Always runs                    |
| STEP010 | `COND=(04,LT,STEP005)` | Skip if STEP005 RC > 4         |
| STEP015 | `COND=(04,LT,STEP010)` | Skip if STEP010 RC > 4         |

---

## Input Data Layout

Record format: `NAME(10) + FIRSTNAME(10) + ROLE(10)` - `LRECL=30`, `RECFM=FB`, `DSORG=PS`

| Field     | Position | Length | Format | Description         |
|-----------|----------|--------|--------|---------------------|
| NAME      | 1        | 10     | CH     | Employee last name  |
| FIRSTNAME | 11       | 10     | CH     | Employee first name |
| ROLE      | 21       | 9      | CH     | Job role            |

### Sample Input Records ([TASK5.INPUT.JCL.txt](DATA/TASK5.INPUT.JCL.txt))

```
IVANOV    IVAN      DEVELOPER 
PETROV    PETR      ANALYST   
SIDOROV   SERGEY    MANAGER   
KOZLOV    ALEXEY    DEVELOPER 
MOROZOV   DMITRY    ANALYST   
NOVIKOV   OLEG      DEVELOPER 
POPOV     ANDREY    MANAGER   
```

---

## Sort and Filter Control Statements

```
SORT FIELDS=COPY
INCLUDE COND=(21,9,CH,EQ,C'DEVELOPER')
```

| Statement | Field | Position | Length | Condition | Value       |
|-----------|-------|----------|--------|-----------|-------------|
| SORT      | -     | -        | -      | COPY (no reorder) | -   |
| INCLUDE   | ROLE  | 21       | 9      | EQ        | `DEVELOPER` |

---

## Output

Statistics from [SYSOUT.txt](OUTPUT/SYSOUT.txt):

```
ICE090I 0 OUTPUT LRECL = 30, BLKSIZE = 27990, TYPE = FB
ICE055I 0 INSERT 0, DELETE 4
ICE054I 0 RECORDS - IN: 7, OUT: 3
```

4 out of 7 records were excluded - only DEVELOPER employees passed through.

### Filtered Result ([TASK5.SORT.JCL.txt](DATA/TASK5.SORT.JCL.txt))

```
IVANOV    IVAN      DEVELOPER 
KOZLOV    ALEXEY    DEVELOPER 
NOVIKOV   OLEG      DEVELOPER 
```

Only the 3 DEVELOPER records remain, in their original input order.

---

## Key JCL Concepts Used

- **SORT FIELDS=COPY** - tells SORT not to reorder records at all, only apply the INCLUDE filter
- **INCLUDE on ROLE field** - filters records by matching a 9-byte character value at position 21
- **GENERATE/RECORD FIELD in STEP010** - trims inline data to exact LRECL=30 before the sort step reads it

---

## Notes

- `SORT FIELDS=COPY` is the correct way to use SORT purely as a filter - using an actual sort key here would work too, but COPY makes the intent clear: no ordering needed, just filter.
- PETROV, SIDOROV, MOROZOV, POPOV are dropped because their ROLE is ANALYST or MANAGER - not DEVELOPER.
- The INCLUDE check is 9 bytes (pos 21, len 9) to match `DEVELOPER` exactly - the 10th byte in the ROLE field is a trailing space.
