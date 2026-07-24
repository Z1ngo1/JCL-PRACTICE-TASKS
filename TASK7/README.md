# Task 7 - OUTREC BUILD with Literal Prefix and Salary Field

## Overview

This job reformats employee records by building a new output layout using SORT's `OUTREC BUILD` statement. Each output record gets a constant prefix `REC:` followed by the last name (10 bytes) and salary (6 bytes) - the first name and role fields are dropped and the record length is reduced from 36 to 20 bytes.

---

## Job Details

| Property  | Value        |
|-----------|--------------|
| Job Name  | `TASK7`      |
| Job Class | `A`          |
| MSGCLASS  | `A`          |
| MSGLEVEL  | `(1,1)`      |
| NOTIFY    | `&SYSUID`    |

---

## Steps

| Step    | Program  | Description                                                                 |
|---------|----------|-----------------------------------------------------------------------------|
| STEP010 | IEFBR14  | Delete existing datasets [`TASK7.JCL.INPUT`](DATA/TASK7.JCL.INPUT.txt) and [`TASK7.JCL.OUTPUT`](DATA/TASK7.JCL.OUTPUT.txt) if they exist |
| STEP020 | IEBGENER | Load inline data, trim records to LRECL=36 using GENERATE/RECORD FIELD      |
| STEP030 | SORT     | Reformat all records using OUTREC BUILD: `REC:` + LASTNAME + SALARY, output LRECL=20 |

---

## COND Logic

| Step    | COND Parameter       | Meaning                    |
|---------|----------------------|----------------------------|
| STEP010 | *(none)*             | Always runs                |
| STEP020 | `COND=(04,LT,STEP010)` | Skip if STEP010 RC > 4   |
| STEP030 | `COND=(04,LT,STEP020)` | Skip if STEP020 RC > 4   |

---

## Input Data Layout

Record format: `LASTNAME(10) + FIRSTNAME(10) + ROLE(10) + SALARY(6)` - `LRECL=36`, `RECFM=FB`, `DSORG=PS`

| Field     | Position | Length | Format |
|-----------|----------|--------|--------|
| LASTNAME  | 1        | 10     | CH     |
| FIRSTNAME | 11       | 10     | CH     |
| ROLE      | 21       | 10     | CH     |
| SALARY    | 31       | 6      | CH     |

### Sample Input Records ([`TASK7.JCL.INPUT`](DATA/TASK7.JCL.INPUT.txt))

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
OUTREC BUILD=(C'REC:',1,10,31,6)
```

New output layout: `C'REC:'(4) + LASTNAME(1,10) + SALARY(31,6)` = 20 bytes total.

---

## Output

Statistics from [SYSOUT.txt](OUTPUT/SYSOUT.txt)

```
ICE090I 0 OUTPUT LRECL = 20, BLKSIZE = 27980, TYPE = FB                         
ICE171I 0 SORTOUT LRECL OF 20 IS DIFFERENT FROM SORTIN(NN) LRECL OF 36 - RC=0   
ICE055I 0 INSERT 0, DELETE 0                                                    
ICE054I 0 RECORDS - IN: 7, OUT: 7                                               
```

## Reformatted Result ([`TASK7.JCL.OUTPUT`](DATA/TASK7.JCL.OUTPUT.txt))

```
REC:IVANOV    005000
REC:PETROV    003200
REC:SIDOROV   007800
REC:KOZLOV    004500
REC:MOROZOV   002900
REC:NOVIKOV   006100
REC:POPOV     008200
```

All 7 records reformatted. FIRSTNAME and ROLE are gone, `REC:` prefix is added before each last name.

---

## Key JCL Concepts Used

- **OUTREC BUILD** - constructs a new output record from selected byte ranges and literals
- **C'REC:' literal in OUTREC** - inserts a 4-byte constant prefix at the start of each output record
- **Byte range selection** - `1,10` picks LASTNAME, `31,6` picks SALARY, skipping FIRSTNAME and ROLE entirely
- **LRECL reduction via OUTREC** - input LRECL=36, output LRECL=20; ICE171I in SYSOUT is informational only

---

## Notes

- `SORT FIELDS=COPY` means no sorting is applied - records keep their original order, only the layout changes.
- FIRSTNAME (bytes 11-20) and ROLE (bytes 21-30) are not referenced in OUTREC BUILD, so they are silently dropped.
- ICE171I in SYSOUT is not an error - it is SORT informing that the output LRECL differs from input LRECL due to OUTREC reformatting.
- This task extends TASK6 by adding a salary field and using `BUILD` instead of `FIELDS` in OUTREC.
