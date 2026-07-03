# Task 01 - Sort Employees by Date of Birthday (SORT)

## Overview

This job sorts a list of employees by their date of birth in **ascending order** using SORT. The sort key is broken into three components - **year, month, and day** - to ensure correct chronological ordering. Input data is loaded inline via IEBGENER, and the sorted result is written to a separate output dataset.

---

## Job Details

| Property  | Value        |
|-----------|--------------|
| Job Name  | `SORT1`      |
| Job Class | `A`          |
| MSGCLASS  | `A`          |
| MSGLEVEL  | `(1,1)`      |
| NOTIFY    | `&SYSUID`    |

---

## Steps

| Step     | Program    | Description                                                                         |
|----------|------------|----------------------------------------------------------------------------------|
| STEP005  | IEFBR14    | Delete existing datasets `Z73460.TASK1.JCL` and `Z73460.TASK1.JCL.SORT` if they exist |
| STEP010  | IEBGENER   | Load inline employee records into dataset `Z73460.TASK1.JCL`                     |
| STEP020  | SORT       | Sort employee records by year, month, day of birth (ascending)                   |

---

## COND Logic

| Step     | COND Parameter           | Meaning                                           |
|----------|--------------------------|---------------------------------------------------|
| STEP005  | *(none)*                 | Always runs                                       |
| STEP010  | `COND=(04,LT,STEP005)`   | Skip if STEP005 RC > 4                            |
| STEP020  | `COND=(04,LT)`           | Skip if any previous step RC > 4                  |

---

## Input Data Layout

Record format: `NAME(10) + DDMMYYYY(8)` - `LRECL=80`, `RECFM=FB`, `DSORG=PS`

[TASK1.JCL.txt](DATA/TASK1.JCL.txt)

| Field  | Position | Length | Format | Description          |
|--------|----------|--------|--------|----------------------|
| NAME   | 1        | 10     | CH     | Employee last name   |
| DAY    | 11       | 2      | CH     | Day of birth (DD)    |
| MONTH  | 13       | 2      | CH     | Month of birth (MM)  |
| YEAR   | 15       | 4      | CH     | Year of birth (YYYY) |

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

## Output

Statistics from [SYSOUT.txt](OUTPUT/SYSOUT.txt):

```
ICE090I 0 OUTPUT LRECL = 80, BLKSIZE = 27920, TYPE = FB  (SDB)
ICE080I 0 IN MAIN STORAGE SORT
ICE055I 0 INSERT 0, DELETE 0
ICE054I 0 RECORDS - IN: 4, OUT: 4
```

### Sorted Result ([TASK1.JCL.SORT.txt](DATA/TASK1.JCL.SORT.txt))

```
DEMENTIEV 25042007
DMITRIEV  06122007
SHERSHUN  30012008
BOGDANOV  03072008
```

Employees born in **2007** appear before those born in **2008**. Within the same year, sorted by month then day.

---

## Key JCL Concepts Used

- **SORT FIELDS** - multi-key sort with positional key definitions (position, length, type, order)
- **SORT on DDMMYYYY** - date stored in European format, keys applied in YYYY/MM/DD order to sort correctly
- **DCB=*.SORTIN** - referback: SORTOUT inherits DCB attributes directly from SORTIN DD
- **DISP=(MOD,DELETE,DELETE) + SPACE** - safe delete pattern with IEFBR14, no ABEND if dataset does not exist

---

## Notes

- Input date is in **DDMMYYYY** format but the sort picks YEAR first (pos 15), then MONTH (pos 13), then DAY (pos 11) - that is why the key order in `SORT FIELDS` does not match the field order in the record.
- All 4 records passed through unchanged (INSERT 0, DELETE 0) - SORT only reordered them, no filtering applied.
- `SYSIN DD DUMMY` in STEP010 is required by IEBGENER even when no editing is needed - without it the step would fail.
