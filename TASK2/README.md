# Task 02 - Include and Omit Records by State and Type (SORT)

## Overview

This job filters employee records using SORT's `INCLUDE` statement - only records where **STATE=NY** and **TYPE=A** are kept. The filtered records are then sorted by employee name in ascending order. Records that do not match both conditions are excluded from the output.

---

## Job Details

| Property  | Value     |
|-----------|-----------|
| Job Name  | `SORT2`   |
| Job Class | `A`       |
| MSGCLASS  | `A`       |
| MSGLEVEL  | `(1,1)`   |
| NOTIFY    | `&SYSUID` |

---

## Steps

| Step  | Program  | Description                                                                            |
|-------|----------|----------------------------------------------------------------------------------------|
| STEP1 | IEFBR14  | Delete existing datasets `Z73460.TASK2.JCL` and `Z73460.TASK2.JCL.SORT` if they exist |
| STEP2 | IEBGENER | Load inline employee records into dataset `Z73460.TASK2.JCL`                           |
| STEP3 | SORT     | Filter records by STATE=NY AND TYPE=A, sort by name ascending                          |

---

## COND Logic

| Step  | COND Parameter       | Meaning                                  |
|-------|----------------------|------------------------------------------|
| STEP1 | *(none)*             | Always runs                              |
| STEP2 | `COND=(04,LT,STEP1)` | Skip if STEP1 RC > 4                     |
| STEP3 | `COND=(04,LT)`       | Skip if any previous step RC > 4         |

---

## Input Data Layout

Record format: `NAME(10) + TYPE(1) + SP + STATE(2) + SP + AMT(6)` - `LRECL=80`, `RECFM=FB`, `DSORG=PS`

[TASK2.JCL.txt](DATA/TASK2.JCL.txt)

| Field | Position | Length | Format | Description                    |
|-------|----------|--------|--------|--------------------------------|
| NAME  | 1        | 10     | CH     | Employee last name             |
| TYPE  | 11       | 1      | CH     | Employee type (A or X)         |
| SP1   | 12       | 1      | -      | Space separator                |
| STATE | 14       | 2      | CH     | State code (NY, CA, TX, FL...) |
| SP2   | 16       | 1      | -      | Space separator                |
| AMT   | 17       | 6      | CH     | Amount (zero-padded)           |

### Sample Input Records (10 total)

```
SMITH     A  NY  001500
JOHNSON   X  NY  002300
WILLIAMS  A  CA  000800
BROWN     A  NY  000500
JONES     X  TX  003000
GARCIA    A  NY  001200
MILLER    A  FL  000900
DAVIS     A  NY  000050
WILSON    X  NY  005000
TAYLOR    A  NY  002100
```

---

## Sort and Filter Control Statements

```
SORT FIELDS=(1,10,CH,A)
INCLUDE COND=(14,2,CH,EQ,C'NY',AND,11,1,CH,EQ,C'A')
```

| Statement | Field | Position | Length | Condition | Value |
|-----------|-------|----------|--------|-----------|-------|
| SORT      | NAME  | 1        | 10     | Ascending | -     |
| INCLUDE   | STATE | 14       | 2      | EQ        | `NY`  |
| INCLUDE   | TYPE  | 11       | 1      | EQ (AND)  | `A`   |

---

## Output

Statistics from [SYSOUT.txt](OUTPUT/SYSOUT.txt):

```
ICE090I 0 OUTPUT LRECL = 80, BLKSIZE = 27920, TYPE = FB  (SDB)
ICE080I 0 IN MAIN STORAGE SORT
ICE055I 0 INSERT 0, DELETE 5
ICE054I 0 RECORDS - IN: 10, OUT: 5
```

5 out of 10 records were excluded by the INCLUDE filter.

### Filtered and Sorted Result ([TASK2.JCL.SORT.txt](DATA/TASK2.JCL.SORT.txt))

```
BROWN     A  NY  000500
DAVIS     A  NY  000050
GARCIA    A  NY  001200
SMITH     A  NY  001500
TAYLOR    A  NY  002100
```

Only TYPE=A records from STATE=NY remain, sorted alphabetically by name.

---

## Key JCL Concepts Used

- **INCLUDE COND** - filters records during sort using multi-condition logic (AND operator between two fields)
- **AND condition** - both STATE=NY and TYPE=A must be true for a record to pass through
- **SORT + INCLUDE together** - filtering and sorting happen in a single SORT step, no extra step needed

---

## Notes

- `DELETE 5` in SYSOUT means 5 records were dropped - JOHNSON (X/NY), WILLIAMS (A/CA), JONES (X/TX), MILLER (A/FL), WILSON (X/NY). Either wrong type or wrong state.
- WILSON has STATE=NY but TYPE=X, so it is excluded - both conditions must be true at the same time.
- The INCLUDE statement is more readable than OMIT for this case since we know exactly what we want to keep.
