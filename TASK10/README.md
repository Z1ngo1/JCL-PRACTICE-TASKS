# Task 10 - Multi-Step Job: Filter, Sort, Reformat and Print (SORT + IEBGENER)

## Overview

This is a multi-step pipeline job that combines filtering, sorting, reformatting, and printing in a single JCL job. Employee records are loaded inline, then DEVELOPER records are filtered and sorted by salary in descending order into a temporary dataset. A second SORT step reads the temporary dataset and reformats each record into LASTNAME + `|` + SALARY layout. A final IEBGENER step prints the result to SYSOUT and always runs regardless of previous step outcomes.

---

## Job Details

| Property  | Value        |
|-----------|--------------|
| Job Name  | `TASK10`     |
| Job Class | `A`          |
| MSGCLASS  | `A`          |
| MSGLEVEL  | `(1,1)`      |
| NOTIFY    | `&SYSUID`    |

---

## Steps

| Step    | Program  | Description                                                                                                   |
|---------|----------|---------------------------------------------------------------------------------------------------------------|
| STEP010 | IEFBR14  | Delete existing datasets [`TASK10.JCL.INPUT`](DATA/TASK10.JCL.INPUT.txt) and [`TASK10.JCL.FINAL`](DATA/TASK10.JCL.FINAL.txt) if they exist |
| STEP020 | IEBGENER | Load 8 inline employee records into [`TASK10.JCL.INPUT`](DATA/TASK10.JCL.INPUT.txt), LRECL=80               |
| STEP030 | SORT     | Filter DEVELOPER records from input, sort by SALARY descending, save to temporary dataset `&&TEMP`            |
| STEP040 | SORT     | Read `&&TEMP`, reformat records with OUTREC BUILD: LASTNAME + `\|` + SALARY + 63 spaces, save to [`TASK10.JCL.FINAL`](DATA/TASK10.JCL.FINAL.txt) |
| STEP050 | IEBGENER | Print [`TASK10.JCL.FINAL`](DATA/TASK10.JCL.FINAL.txt) to SYSOUT - runs even if previous steps failed (`COND=EVEN`) |

---

## COND Logic

| Step    | COND Parameter         | Meaning                                              |
|---------|------------------------|------------------------------------------------------|
| STEP010 | *(none)*               | Always runs                                          |
| STEP020 | `COND=(04,LT,STEP010)` | Skip if STEP010 RC > 4                               |
| STEP030 | `COND=(04,LT,STEP020)` | Skip if STEP020 RC > 4                               |
| STEP040 | `COND=(00,NE,STEP030)` | Skip if STEP030 RC is not 0 (run only on clean sort) |
| STEP050 | `COND=EVEN`            | Always runs - even if any previous step abended      |

---

## Input Data Layout

Record format: `LASTNAME(10) + FIRSTNAME(10) + ROLE(10) + SALARY(6)` - `LRECL=80`, `RECFM=FB`, `DSORG=PS`

| Field     | Position | Length | Format | Description          |
|-----------|----------|--------|--------|----------------------|
| LASTNAME  | 1        | 10     | CH     | Employee last name   |
| FIRSTNAME | 11       | 10     | CH     | Employee first name  |
| ROLE      | 21       | 10     | CH     | Job role             |
| SALARY    | 31       | 6      | CH     | Salary (zero-padded) |

### Sample Input Records ([`TASK10.JCL.INPUT`](DATA/TASK10.JCL.INPUT.txt))

```
IVANOV    IVAN      DEVELOPER 005000
PETROV    PETR      ANALYST   003200
SIDOROV   SERGEY    MANAGER   007800
KOZLOV    ALEXEY    DEVELOPER 004500
MOROZOV   DMITRY    ANALYST   002900
NOVIKOV   OLEG      DEVELOPER 006100
POPOV     ANDREY    MANAGER   008200
SOKOLOV   DENIS     DEVELOPER 005500
```

---

## STEP030 - Filter and Sort Control Statements

```
SORT FIELDS=(31,6,CH,D)
INCLUDE COND=(21,9,CH,EQ,C'DEVELOPER')
```

| Statement | Field    | Position | Length | Condition      | Value       |
|-----------|----------|----------|--------|----------------|-------------|
| SORT      | SALARY   | 31       | 6      | Descending (D) | -           |
| INCLUDE   | ROLE     | 21       | 9      | EQ             | `DEVELOPER` |

Output saved to temporary dataset `&&TEMP` (DISP=PASS, deleted after job ends).

---

## STEP040 - Reformat Control Statements

```
SORT FIELDS=COPY
OUTREC BUILD=(1,10,C'|',31,6,63X)
```

| Segment | Source       | Length | Description                        |
|---------|--------------|--------|------------------------------------|
| 1,10    | Input pos 1  | 10     | LASTNAME                           |
| C'\|'   | Literal      | 1      | Pipe delimiter                     |
| 31,6    | Input pos 31 | 6      | SALARY                             |
| 63X     | Filler       | 63     | Trailing spaces to maintain LRECL=80|

Output record length: 10 + 1 + 6 + 63 = **80 bytes**

---

## Output

| File | Description |
|------|-------------|
| [SYSOUT.STEP030.txt](OUTPUT/SYSOUT.STEP030.txt) | SORT STEP030 control statements sysout - filter and sort by SALARY descending |
| [SYSOUT.STEP040.txt](OUTPUT/SYSOUT.STEP040.txt) | SORT STEP040 control statements sysout - reformat records with OUTREC BUILD |
| [SYSUT2.STEP050.txt](OUTPUT/SYSUT2.STEP050.txt) | Final reformatted DEVELOPER records printed by IEBGENER STEP050 (COND=EVEN) |

---

## Final Result ([`TASK10.JCL.FINAL`](DATA/TASK10.JCL.FINAL.txt))

4 DEVELOPER records filtered, sorted by salary descending, then reformatted:

```
NOVIKOV   |006100
SOKOLOV   |005500
IVANOV    |005000
KOZLOV    |004500
```

Printed to SYSOUT by STEP050 [SYSUT2.STEP050.txt](OUTPUT/SYSUT2.STEP050.txt) (IEBGENER with COND=EVEN).

---

## Key JCL Concepts Used

- **`&&TEMP` temporary dataset** - created in STEP030 with `DISP=(NEW,PASS,DELETE)` and consumed in STEP040 with `DISP=(OLD,DELETE,DELETE)`, it exists only during the job
- **`COND=EVEN`** - STEP050 always executes regardless of previous step return codes or abends, ensuring the print step always runs
- **Descending SORT on SALARY** - `SORT FIELDS=(31,6,CH,D)` sorts character field in reverse order, highest salary first
- **63X filler in OUTREC** - pads the output record with 63 spaces to maintain the original LRECL=80
- **`INCLUDE COND` length equals keyword length, not field width** - `INCLUDE COND=(21,9,CH,EQ,C'DEVELOPER')` compares exactly 9 bytes against the 9-char literal; the remaining 1 byte of the ROLE field (trailing space) is not compared and does not need to be included in the literal.

---

## Notes

- PETROV, SIDOROV, MOROZOV, POPOV are excluded in STEP030 because their ROLE is ANALYST or MANAGER.
- `&&TEMP` is a temporary instream dataset - it is automatically deleted when the job ends or when STEP040 reads and deletes it with `DISP=(OLD,DELETE,DELETE)`.
- STEP050 uses `SYSIN DD DUMMY` meaning IEBGENER does a straight copy from [`TASK10.JCL.FINAL`](DATA/TASK10.JCL.FINAL.txt) to SYSOUT with no editing.
- This task is the first multi-step pipeline in this repository where two SORT steps work sequentially on the same data stream.
- `INCLUDE COND=(21,9,CH,EQ,C'DEVELOPER')` compares 9 bytes from position 21 in the record against the 9-char literal `DEVELOPER`. The remaining 1 byte of the ROLE field (position 30, trailing space) is not compared - no padding needed in the literal.
