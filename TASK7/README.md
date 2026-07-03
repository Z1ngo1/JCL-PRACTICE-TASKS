# Task 7 - OUTREC BUILD with Literal Prefix and Salary Field

## Overview

This task reformats employee records by building a new output layout using SORT `OUTREC BUILD`. Each output record gets a constant prefix `REC:` followed by the last name (10 bytes) and salary (6 bytes), reducing the record length from 36 to 20 bytes. The first name and role fields are dropped from the output.

## Steps

**STEP010** - Delete existing input and output datasets using IEFBR14 (cleanup step).

**STEP020** - Load 7 employee records into the input dataset using IEBGENER with `GENERATE MAXFLDS=1` and `RECORD FIELD=(36,1,,1)` to set LRECL=36.

**STEP030** - Use SORT with `OUTREC BUILD=(C'REC:',1,10,31,6)` to reformat each record: prepend the literal `REC:`, extract LASTNAME (bytes 1-10), and extract SALARY (bytes 31-36). Output LRECL=20.

## Input Data Layout

LRECL=36, RECFM=FB, DSORG=PS

| Bytes | Field     | Length |
|-------|-----------|--------|
| 1-10  | LASTNAME  | 10     |
| 11-20 | FIRSTNAME | 10     |
| 21-30 | ROLE      | 10     |
| 31-36 | SALARY    | 6      |

Input records:

```
IVANOV    IVAN      DEVELOPER 005000
PETROV    PETR      ANALYST   003200
SIDOROV   SERGEY    MANAGER   007800
KOZLOV    ALEXEY    DEVELOPER 004500
MOROZOV   DMITRY    ANALYST   002900
NOVIKOV   OLEG      DEVELOPER 006100
POPOV     ANDREY    MANAGER   008200
```

See: [TASK7.INPUT.JCL.txt](DATA/TASK7.INPUT.JCL.txt)

## Datasets

| DD Name  | DSN                      | Role        |
|----------|--------------------------|-------------|
| SORTIN   | Z73460.TASK7.INPUT.JCL   | Input PS    |
| SORTOUT  | Z73460.TASK7.OUTPUT.JCL  | Output PS   |

## Output

Output LRECL=20: `C'REC:'(4) + LASTNAME(10) + SALARY(6)`

```
REC:IVANOV    005000
REC:PETROV    003200
REC:SIDOROV   007800
REC:KOZLOV    004500
REC:MOROZOV   002900
REC:NOVIKOV   006100
REC:POPOV     008200
```

See: [TASK7.OUTPUT.JCL.txt](DATA/TASK7.OUTPUT.JCL.txt)

SYSOUT log: [SYSOUT.txt](OUTPUT/SYSOUT.txt)

## Key JCL Concepts Used

- **OUTREC BUILD** - constructs a new output record from selected byte ranges and literals
- **C'REC:' literal in OUTREC** - inserts a 4-byte constant prefix at the start of each output record
- **Byte range selection** - `1,10` picks LASTNAME, `31,6` picks SALARY, skipping FIRSTNAME and ROLE entirely
- **LRECL reduction via OUTREC** - input LRECL=36, output LRECL=20; ICE171I is informational only

## Notes

- `SORT FIELDS=COPY` means no sorting is applied - records keep their original order, only the layout changes.
- FIRSTNAME (bytes 11-20) and ROLE (bytes 21-30) are not referenced in OUTREC BUILD, so they are silently dropped.
- ICE171I in SYSOUT is not an error - it is SORT informing that the output LRECL differs from input LRECL due to OUTREC reformatting.
- This task extends TASK6 by adding a salary field and using `BUILD` instead of `FIELDS` in OUTREC.
