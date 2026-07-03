# Task 01 - Sort Employees by Date of Birthday (DFSORT)

## Overview

This job sorts a list of employees by their date of birth in **ascending order** using DFSORT. The sort key is broken into three components - **year, month, and day** to ensure correct chronological ordering. Input data is loaded inline via IEBGENER, and the sorted result is written to a separate output dataset.

---

## Job Details

| Property     | Value                     |
|--------------|---------------------------|
| Job Name     | `SORT1`                   |
| Job Class    | `A`                       |
| MSGCLASS     | `A`                       |
| MSGLEVEL     | `(1,1)`                   |
| NOTIFY       | `&SYSUID`                 |

---

## Steps

| Step     | Program    | Description                                                      |
|----------|------------|------------------------------------------------------------------|
| STEP005  | IEFBR14    | Delete existing datasets `Z73460.TASK1.JCL` and `Z73460.TASK1.JCL.SORT` if they exist |
| STEP010  | IEBGENER   | Load inline employee records into dataset `Z73460.TASK1.JCL`     |
| STEP020  | SORT       | Sort employee records by year, month, day of birth (ascending)   |

---

## COND Logic

| Step     | COND Parameter         | Meaning                                              |
|----------|------------------------|------------------------------------------------------|
| STEP005  | *(none)*               | Always runs                                          |
| STEP010  | `COND=(04,LT,STEP005)` | Skip if STEP005 RC > 4                               |
| STEP020  | `COND=(04,LT)`         | Skip if any previous step RC > 4                     |

---

## Input Data Layout

Record format: `NAME(10) + DDMMYYYY(8)` — `LRECL=80`, `RECFM=FB`, `DSORG=PS`

| Field  | Position | Length | Format   | Description           |
|--------|----------|--------|----------|-----------------------|
| NAME   | 1        | 10     | CH       | Employee last name    |
| DAY    | 11       | 2      | CH       | Day of birth (DD)     |
| MONTH  | 13       | 2      | CH       | Month of birth (MM)   |
| YEAR   | 15       | 4      | CH       | Year of birth (YYYY)  |

### Sample Input Records

```
DMITRIEV  06122007
SHERSHUN  30012008
DEMENTIEV 25042007
BOGDANOV  03072008
```

---

## Sort Control Statement

```
SORT FIELDS=(15,4,CH,A,13,2,CH,A,11,2,CH,A)
```

| Key | Position | Length | Type | Order     | Field |
|-----|----------|--------|------|-----------|-------|
| 1st | 15       | 4      | CH   | Ascending | YEAR  |
| 2nd | 13       | 2      | CH   | Ascending | MONTH |
| 3rd | 11       | 2      | CH   | Ascending | DAY   |

---

## Datasets

| DD Name   | DSN                       | DISP              | RECFM | LRECL | Description          |
|-----------|---------------------------|-------------------|-------|-------|----------------------|
| DELDD1    | Z73460.TASK1.JCL          | MOD,DELETE,DELETE | -     | -     | Deleted in STEP005   |
| DELDD2    | Z73460.TASK1.JCL.SORT     | MOD,DELETE,DELETE | -     | -     | Deleted in STEP005   |
| SYSUT2    | Z73460.TASK1.JCL          | NEW,CATLG,DELETE  | FB    | 80    | Input dataset loaded by IEBGENER |
| SORTIN    | Z73460.TASK1.JCL          | SHR               | FB    | 80    | Input to SORT        |
| SORTOUT   | Z73460.TASK1.JCL.SORT     | NEW,CATLG,DELETE  | *     | *     | Sorted output (DCB=*.SORTIN) |

---

## Output

statistics from `OUTPUT/SYSOUT.txt`:

```
ICE090I 0 OUTPUT LRECL = 80, BLKSIZE = 27920, TYPE = FB  (SDB)
ICE080I 0 IN MAIN STORAGE SORT
ICE055I 0 INSERT 0, DELETE 0
ICE054I 0 RECORDS - IN: 4, OUT: 4
```

### Sorted Result (DATA/TASK1.JCL.SORT.txt)

```
DEMENTIEV 25042007
DMITRIEV  06122007
SHERSHUN  30012008
BOGDANOV  03072008
```

Employees born in **2007** appear before those born in **2008**. Within the same year, sorted by month then day.

---

## Key JCL Concepts Used

- **IEFBR14** - Dummy program used to allocate or delete datasets via DD statements
- **IEBGENER** - Utility to copy inline data (SYSUT1 DD *) into a sequential dataset
- **DFSORT / SORT** - sort utility with `SORT FIELDS` control statement
- **COND parameter** - Conditional step execution based on return codes from prior steps
- **DCB=\*.SORTIN** - Referback: SORTOUT inherits DCB attributes from SORTIN
- **DISP=(MOD,DELETE,DELETE)** - Safe dataset deletion pattern (no ABEND if dataset does not exist, thanks to SPACE parameter)
- **SPACE=(TRK,(1,0))** - Minimal space allocation used with IEFBR14 for safe delete

---

## Notes

- The date in input records is stored in **DDMMYYYY** format (European style), but the sort keys are applied in **YYYY → MM → DD** order to achieve correct chronological sorting.
- `SYSIN DD DUMMY` in STEP010 tells IEBGENER to copy the entire input without any editing control.
- `DCB=*.SORTIN` in SORTOUT means the output dataset inherits all DCB attributes (LRECL, RECFM, BLKSIZE) from the SORTIN DD — no need to repeat them.
