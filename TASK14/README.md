# Task 14 - Instream PROC with Two Steps: SORT Filter + ICETOOL Count and PARM JP Variables

## Overview

This job demonstrates an instream proc (RPTPROC) with two internal steps and three symbolic parameters: `&ROLE`, `&MINSAL`, and `&OUTDSN`. RPTPROC first filters records by role and minimum salary using SORT with PARM-passed JP variables, then counts the matching records using ICETOOL. The main job calls RPTPROC twice - for DEVELOPERs with salary >= 004500 and for MANAGERs with salary >= 006000 - then concatenates both count outputs and prints them to SYSOUT.

---

## Job Details

| Property | Value |
|-----------|----------------|
| Job Name | `TASK14` |
| Job Class | `A` |
| MSGCLASS | `A` |
| MSGLEVEL | `(1,1)` |
| NOTIFY | `&SYSUID` |
| EXPORT | `SYMLIST=(ROLE,MINSAL)` |

---

## Instream PROC: RPTPROC

```
//RPTPROC PROC ROLE=,MINSAL=,OUTDSN=
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `&ROLE` | *(empty)* | Role value passed as JP1 to SORT INCLUDE filter |
| `&MINSAL` | *(empty)* | Minimum salary value passed as JP2 to SORT INCLUDE filter |
| `&OUTDSN` | *(empty)* | Name of the temporary output dataset for the count result |

RPTPROC has two internal steps:
- **STEP1** (SORT) — filters `&&ALLIN` by role and minimum salary, writes to `&&FILTERED`
- **STEP2** (ICETOOL) — counts records in `&&FILTERED`, writes count to `&OUTDSN`; runs only if STEP1 RC=0

---

## Steps

| Step | Program | Description |
|---------|----------|---------------------------------------------------------------------------------------------------------------|
| STEP010 | SORT | Load 10 inline employee records, copy all to temporary dataset `&&ALLIN` using `SORT FIELDS=COPY` |
| STEP020 | RPTPROC | Call RPTPROC with `ROLE='DEVELOPER '`, `MINSAL='004500'`, output count to `&&DCNT` |
| STEP030 | RPTPROC | Call RPTPROC with `ROLE='MANAGER '`, `MINSAL='006000'`, output count to `&&MCNT` |
| STEP040 | IEBGENER | Concatenate `&&DCNT` and `&&MCNT` via DD concatenation, print to SYSOUT |

---

## COND Logic

| Step / Proc Step | COND Parameter | Meaning |
|------------------|----------------------------------------------|----------------------------------------------------------|
| STEP010 | *(none)* | Always runs |
| STEP020 | *(none)* | Always runs |
| STEP030 | *(none)* | Always runs |
| RPTPROC STEP2 | `COND=(00,NE,STEP1)` | Inside proc: skip ICETOOL if SORT STEP1 RC != 0 |
| STEP040 | `COND=((00,NE,STEP020.STEP2),(00,NE,STEP030.STEP2))` | Skip if STEP020.STEP2 or STEP030.STEP2 RC != 0 |

---

## Input Data Layout

Record format: `LASTNAME(10) + FIRSTNAME(10) + ROLE(10) + SALARY(6)` - `LRECL=80`, `RECFM=FB`, `DSORG=PS`

| Field | Position | Length | Format | Description |
|-----------|----------|--------|--------|----------------------|
| LASTNAME | 1 | 10 | CH | Employee last name |
| FIRSTNAME | 11 | 10 | CH | Employee first name |
| ROLE | 21 | 10 | CH | Job role |
| SALARY | 31 | 6 | CH | Salary (zero-padded) |

### Sample Input Records (inline in STEP010)

```
IVANOV     IVAN       DEVELOPER  005000
PETROV     PETR       ANALYST    003200
SIDOROV    SERGEY     MANAGER    007800
KOZLOV     ALEXEY     DEVELOPER  004500
MOROZOV    DMITRY     ANALYST    002900
NOVIKOV    OLEG       DEVELOPER  006100
POPOV      ANDREY     MANAGER    008200
SOKOLOV    DENIS      DEVELOPER  005500
LEBEDEV    ROMAN      MANAGER    006800
ORLOV      NIKITA     ANALYST    003100
```

---

## RPTPROC STEP1 - SORT Filter with JP Variables

```
SORT FIELDS=(31,6,CH,D)
INCLUDE COND=(21,10,CH,EQ,JP1,AND,31,6,CH,GE,JP2)
```

JP variables are passed via the EXEC PARM parameter:

```
EXEC PGM=SORT,PARM='JP1"&ROLE",JP2"&MINSAL"'
```

| JP Variable | Value (STEP020) | Value (STEP030) | Description |
|-------------|-----------------|-----------------|-------------|
| `JP1` | `DEVELOPER ` | `MANAGER   ` | Role value for INCLUDE EQ filter (10 chars padded) |
| `JP2` | `004500` | `006000` | Minimum salary for INCLUDE GE filter |

| Statement | Field | Position | Length | Condition | Value |
|-----------|--------|----------|--------|-----------|-------|
| SORT | SALARY | 31 | 6 | Descending (D) | - |
| INCLUDE | ROLE | 21 | 10 | EQ JP1 | `&ROLE` (10 chars) |
| INCLUDE | SALARY | 31 | 6 | GE JP2 | `&MINSAL` |

---

## RPTPROC STEP2 - ICETOOL Count

```
COUNT FROM(INDD) WRITE(OUTDD)
```

| Operand | DD Name | Dataset |
|---------|---------|---------|
| FROM | INDD | `&&FILTERED` (filtered records from STEP1) |
| WRITE | OUTDD | `&OUTDSN` (passed as `&&DCNT` or `&&MCNT`) |

---

## Final Result ([SYSUT2.STEP040.txt](OUTPUT/SYSUT2.STEP040.txt))

Two count values concatenated and printed by STEP040:

```
00000000000000004
00000000000000003
```

| Line | Meaning |
|------|---------|
| `00000000000000004` | 4 DEVELOPER records with SALARY >= 004500 (IVANOV 005000, KOZLOV 004500, NOVIKOV 006100, SOKOLOV 005500) |
| `00000000000000003` | 3 MANAGER records with SALARY >= 006000 (SIDOROV 007800, POPOV 008200, LEBEDEV 006800) |

---

## Output

| File | Description |
|------|-------------|
| [SYSOUT.STEP010.txt](OUTPUT/SYSOUT.STEP010.txt) | SORT STEP010 sysout - copy all records to `&&ALLIN` |
| [SYSOUT.STEP020.STEP1.txt](OUTPUT/SYSOUT.STEP020.STEP1.txt) | RPTPROC STEP020.STEP1 sysout - filter DEVELOPER salary >= 004500 |
| [SYSOUT.STEP030.STEP1.txt](OUTPUT/SYSOUT.STEP030.STEP1.txt) | RPTPROC STEP030.STEP1 sysout - filter MANAGER salary >= 006000 |
| [TOOLMSG.STEP020.STEP2.txt](OUTPUT/TOOLMSG.STEP020.STEP2.txt) | ICETOOL STEP020.STEP2 TOOLMSG - count result for DEVELOPERs |
| [TOOLMSG.STEP030.STEP2.txt](OUTPUT/TOOLMSG.STEP030.STEP2.txt) | ICETOOL STEP030.STEP2 TOOLMSG - count result for MANAGERs |
| [DFSMSG.STEP020.STEP2.txt](OUTPUT/DFSMSG.STEP020.STEP2.txt) | ICETOOL STEP020.STEP2 DFSMSG - data facility messages |
| [DFSMSG.STEP030.STEP2.txt](OUTPUT/DFSMSG.STEP030.STEP2.txt) | ICETOOL STEP030.STEP2 DFSMSG - data facility messages |
| [SYSUT2.STEP040.txt](OUTPUT/SYSUT2.STEP040.txt) | Final concatenated count output printed by IEBGENER STEP040 |

---

## Key JCL Concepts Used

- **SORT PARM JP variables** - `PARM='JP1"value1",JP2"value2"'` passes named character constants to SORT; they are then referenced in SYSIN control statements as `JP1`, `JP2` instead of hardcoded literals, making the proc reusable with different filter values
- **Two-step instream PROC** - RPTPROC contains two steps (STEP1 SORT + STEP2 ICETOOL); the proc encapsulates a complete filter-and-count pipeline called with different parameters each time
- **`INCLUDE COND` with AND** - `INCLUDE COND=(21,10,CH,EQ,JP1,AND,31,6,CH,GE,JP2)` filters records that match both conditions simultaneously: role equals JP1 AND salary is >= JP2
- **`EXPORT SYMLIST=(ROLE,MINSAL)`** - allows the `ROLE` and `MINSAL` symbols to be visible inside the proc's SYSIN instream data for `SYMBOLS=JCLONLY` substitution
- **Proc step COND reference** - `COND=((00,NE,STEP020.STEP2),(00,NE,STEP030.STEP2))` uses `jobstep.procstep` notation to reference the second step inside each proc call
- **DD concatenation** - `&&DCNT` and `&&MCNT` concatenated under SYSUT1 so IEBGENER prints both count lines sequentially in one output

---

## Notes

- ANALYST records (PETROV, MOROZOV, ORLOV) are never matched because RPTPROC is only called with ROLE=DEVELOPER and ROLE=MANAGER.
- `ROLE='DEVELOPER '` is padded to 10 characters to match the full ROLE field width, because the INCLUDE uses length `10`: `INCLUDE COND=(21,10,CH,EQ,JP1,...)`.
- KOZLOV (004500) is included in the DEVELOPER count because `004500 >= 004500` (GE includes equal values).
- `&&FILTERED` is an internal proc temporary dataset: created by STEP1 with `DISP=(NEW,PASS,DELETE)` and consumed by STEP2 with `DISP=(OLD,DELETE)`. It exists only between the two proc steps and is automatically deleted after STEP2.
- ICETOOL count format is a 17-character zero-padded number: `00000000000000004` means 4 records.
- There is no DATA folder for this task - all input data is provided inline in STEP010 SORTIN.
