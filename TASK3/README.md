# Task 03 - Copy PS to PS with Exact Record Length (IEBGENER)

## Overview

This job copies an employee dataset from one sequential file to another using IEBGENER. The key feature is the use of `GENERATE` and `RECORD FIELD` control statements in STEP020 to trim records to an exact length of **30 bytes** before writing. STEP030 then copies the trimmed input to the output dataset inheriting DCB from SYSUT1.

---

## Job Details

| Property  | Value     |
|-----------|-----------|
| Job Name  | `TASK3`   |
| Job Class | `A`       |
| MSGCLASS  | `A`       |
| MSGLEVEL  | `(1,1)`   |
| NOTIFY    | `&SYSUID` |

---

## Steps

| Step    | Program  | Description                                                                                    |
|---------|----------|------------------------------------------------------------------------------------------------|
| STEP010 | IEFBR14  | Delete existing datasets [`TASK3.JCL.INPUT`](DATA/TASK3.JCL.INPUT.txt) and [`TASK3.JCL.OUTPUT`](DATA/TASK3.JCL.OUTPUT.txt) if they exist |
| STEP020 | IEBGENER | Load inline data, trim records to LRECL=30 using GENERATE/RECORD FIELD control statements      |
| STEP030 | IEBGENER | Copy input dataset to output dataset, DCB inherited from SYSUT1 via referback                  |

---

## COND Logic

| Step    | COND Parameter         | Meaning                        |
|---------|------------------------|--------------------------------|
| STEP010 | *(none)*               | Always runs                    |
| STEP020 | `COND=(04,LT,STEP010)` | Skip if STEP010 RC > 4         |
| STEP030 | `COND=(04,LT,STEP020)` | Skip if STEP020 RC > 4         |

---

## Input Data Layout

Record format: `NAME(10) + FIRSTNAME(10) + ROLE(10)` - `LRECL=30`, `RECFM=FB`, `DSORG=PS`

| Field     | Position | Length | Format | Description         |
|-----------|----------|--------|--------|---------------------|
| NAME      | 1        | 10     | CH     | Employee last name  |
| FIRSTNAME | 11       | 10     | CH     | Employee first name |
| ROLE      | 21       | 10     | CH     | Job role            |

### Sample Input Records ([`TASK3.JCL.INPUT`](DATA/TASK3.JCL.INPUT.txt))

```
IVANOV    IVAN      DEVELOPER 
PETROV    PETR      ANALYST   
SIDOROV   SERGEY    MANAGER   
KOZLOV    ALEXEY    DEVELOPER 
MOROZOV   DMITRY    ANALYST   
```

---

## IEBGENER Control Statements (STEP020)

```
GENERATE MAXFLDS=1
RECORD FIELD=(30,1,,1)
```

| Parameter | Value      | Description                                                                    |
|-----------|------------|--------------------------------------------------------------------------------|
| MAXFLDS   | 1          | Maximum number of fields in RECORD statement                                   |
| FIELD     | (30,1,,1)  | Copy 30 bytes from position 1 of input, write to position 1 of output         |

This trims any extra trailing data so the output record is exactly 30 bytes.

---

## Output

### Output Dataset ([`TASK3.JCL.OUTPUT`](DATA/TASK3.JCL.OUTPUT.txt))

```
IVANOV    IVAN      DEVELOPER 
PETROV    PETR      ANALYST   
SIDOROV   SERGEY    MANAGER   
KOZLOV    ALEXEY    DEVELOPER 
MOROZOV   DMITRY    ANALYST   
```

All 5 records copied unchanged - input records were already exactly 30 bytes.

---

## Key JCL Concepts Used

- **GENERATE/RECORD FIELD** - IEBGENER control statements that define exact byte ranges to copy, used here to enforce LRECL=30 on each record
- **PS to PS copy with IEBGENER** - using IEBGENER twice: first to load and trim inline data, then to copy between two sequential datasets
- **DCB=*.STEP030.SYSUT1** - referback across DDs within the same step: SYSUT2 inherits DCB from SYSUT1 of STEP030

---

## Notes

- `GENERATE MAXFLDS=1` is required before any `RECORD` statement - it tells IEBGENER how many field definitions to expect.
- `RECORD FIELD=(30,1,,1)` means: take 30 bytes from position 1 of the input record and write them to position 1 of the output - effectively enforcing exact record length.
- In STEP030, `SYSIN DD DUMMY` means no editing is applied - IEBGENER does a straight copy from input to output.
