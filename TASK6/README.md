# Task 06 - Reformat Employee Records with OUTREC (SORT)

## Overview

This job reformats employee records into a new output layout using SORT's `OUTREC FIELDS` statement. The original 30-byte record `NAME + FIRSTNAME + ROLE` is transformed into a 21-byte record `NAME(10) + '|' + ROLE(10)` - the FIRSTNAME field is dropped and a pipe delimiter is inserted between the last name and role.

---

## Job Details

| Property  | Value     |
|-----------|-----------|
| Job Name  | `TASK6`   |
| Job Class | `A`       |
| MSGCLASS  | `A`       |
| MSGLEVEL  | `(1,1)`   |
| NOTIFY    | `&SYSUID` |

---

## Steps

| Step    | Program  | Description                                                                                      |
|---------|----------|--------------------------------------------------------------------------------------------------|
| STEP010 | IEFBR14  | Delete existing datasets [`TASK6.INPUT.JCL`](DATA/TASK6.INPUT.JCL.txt) and [`TASK6.NEWFORM.JCL`](DATA/TASK6.NEWFORM.JCL.txt) if they exist  |
| STEP020 | IEBGENER | Load inline data, trim records to LRECL=30 using GENERATE/RECORD FIELD                           |
| STEP030 | SORT     | Reformat all records using OUTREC FIELDS: NAME + '|' + ROLE, output LRECL=21                    |

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

### Sample Input Records ([TASK6.INPUT.JCL.txt](DATA/TASK6.INPUT.JCL.txt))

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

## OUTREC Control Statements

```
OPTION COPY
OUTREC FIELDS=(1,10,C'|',21,10)
```

| Segment   | Source        | Length | Description                        |
|-----------|---------------|--------|---------------------------------|
| 1,10      | Input pos 1   | 10     | Last name (NAME)                   |
| C'\|'     | Literal       | 1      | Pipe delimiter inserted            |
| 21,10     | Input pos 21  | 10     | Role (ROLE), FIRSTNAME is skipped  |

Output record length: 10 + 1 + 10 = **21 bytes**

---

## Output

Statistics from [SYSOUT.txt](OUTPUT/SYSOUT.txt):

```
ICE090I 0 OUTPUT LRECL = 21, BLKSIZE = 27993, TYPE = FB
ICE171I 0 SORTOUT LRECL OF 21 IS DIFFERENT FROM SORTIN(NN) LRECL OF 30 - RC=0
ICE055I 0 INSERT 0, DELETE 0
ICE054I 0 RECORDS - IN: 7, OUT: 7
```

All 7 records reformatted. ICE171I is an informational message - SORT detected the LRECL change from 30 to 21, which is expected and not an error.

### Reformatted Result ([TASK6.NEWFORM.JCL.txt](DATA/TASK6.NEWFORM.JCL.txt))

```
IVANOV    |DEVELOPER 
PETROV    |ANALYST   
SIDOROV   |MANAGER   
KOZLOV    |DEVELOPER 
MOROZOV   |ANALYST   
NOVIKOV   |DEVELOPER 
POPOV     |MANAGER   
```

FIRSTNAME is gone, pipe separates NAME from ROLE.

---

## Key JCL Concepts Used

- **OUTREC FIELDS** - rebuilds each output record by picking specific byte ranges from input and inserting literals
- **C'|' literal in OUTREC** - inserts a constant character value directly into the output record
- **LRECL change via OUTREC** - input LRECL=30, output LRECL=21, SORT handles the difference automatically (ICE171I is informational only)

---

## Notes

- `OPTION COPY` means no sorting is applied - records keep their original order, only the layout changes.
- FIRSTNAME at positions 11-20 is simply not referenced in OUTREC FIELDS, so it is silently dropped from the output.
- ICE171I in SYSOUT is not an error - it is SORT informing that the output LRECL differs from input LRECL due to OUTREC reformatting.
