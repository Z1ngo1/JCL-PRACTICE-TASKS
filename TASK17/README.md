# Task 17 - Inline PROC with JOINKEYS, Symbolic Parameters, and Multi-Step Filtering

## Overview

This job demonstrates an inline procedure (SALPROC) that filters and counts employee records by role using SORT JOINKEYS, symbolic parameter substitution, ICETOOL counting, and temporary datasets. A left outer join creates a master dataset with employee ID, name, role, and salary. The inline proc is then called twice: once to filter and count DEVELOPER records, and once for MANAGER records. Final totals are concatenated and printed to SYSOUT.

---

## Job Details

| Property | Value |
|-----------|------------------|
| Job Name | `TASK17` |
| Job Class | `A` |
| MSGCLASS | `A` |
| MSGLEVEL | `(1,1)` |
| NOTIFY | `&SYSUID` |
| EXPORT | `SYMLIST=(ROLE)` |

---

## Inline Procedure - SALPROC

```
//SALPROC PROC ROLE=,OUTDSN=
```

Parameters:
- `ROLE` - Symbolic parameter: role name to filter (e.g., `DEVELOPER`, `MANAGER`)
- `OUTDSN` - Symbolic parameter: output dataset name for count result

### SALPROC.STEP1 - Filter by Role and Sort by Salary

Filters `&&JOINED` by `&ROLE`, sorts descending by salary, outputs to `&&ROLEOUT`.

**SORT SYSIN:**
```
SORT FIELDS=(24,6,CH,D)
INCLUDE COND=(14,10,CH,EQ,C'&ROLE')
```

- `SORT FIELDS=(24,6,CH,D)` - Sort by salary (position 24, length 6) descending
- `INCLUDE COND=(14,10,CH,EQ,C'&ROLE')` - Include only records where position 14 (role field, length 10) matches `&ROLE`

### SALPROC.STEP2 - Count Filtered Records

`COND=(00,NE,STEP1)` - Skip if STEP1 RC != 0

Uses ICETOOL to count records in `&&ROLEOUT` and write the count to `&OUTDSN`.

**ICETOOL TOOLIN:**
```
COUNT FROM(INDD) WRITE(OUTDD)
```

---

## Steps

| Step | Program | Description |
|---------|----------|-----------------------------------------------------------------------------------------------------------------------------------------|
| STEP010 | IEFBR14 | Delete existing datasets [`TASK17.EMPLLIST.JCL`](DATA/TASK17.EMPLLIST.JCL.txt) and [`TASK17.SALARY.JCL`](DATA/TASK17.SALARY.JCL.txt) if they exist |
| STEP020 | IEBGENER | Load 10 inline employee records (ID + NAME + ROLE) into [`TASK17.EMPLLIST.JCL`](DATA/TASK17.EMPLLIST.JCL.txt), LRECL=26 |
| STEP030 | IEBGENER | Load 8 inline salary records (ID + SALARY) into [`TASK17.SALARY.JCL`](DATA/TASK17.SALARY.JCL.txt), LRECL=9 |
| STEP040 | SORT | Left outer join [`TASK17.EMPLLIST.JCL`](DATA/TASK17.EMPLLIST.JCL.txt) and [`TASK17.SALARY.JCL`](DATA/TASK17.SALARY.JCL.txt) by ID (pos 1-3), output to `&&JOINED`, LRECL=29 |
| STEP050 | SALPROC | Call SALPROC with `ROLE='DEVELOPER '`, filter developers, count -> `&&DEVCNT` |
| STEP060 | SALPROC | Call SALPROC with `ROLE='MANAGER '`, filter managers, count -> `&&MGRCNT` |
| STEP070 | SORT | Concatenate `&&DEVCNT` and `&&MGRCNT`, add prefix `TOTAL: ` to each line, output to SYSOUT |
| STEP080 | IEBGENER | `COND=EVEN` - Always print full `&&JOINED` dataset to SYSOUT for verification |

---

## COND Logic

| Step | COND Parameter | Meaning |
|------------------|-----------------------------------------------|----------------------------------------------------------|
| STEP010 | *(none)* | Always runs |
| STEP020 | `COND=(04,LT,STEP010)` | Skip if STEP010 RC > 4 |
| STEP030 | `COND=(04,LT,STEP010)` | Skip if STEP010 RC > 4 |
| STEP040 | `COND=((04,LT,STEP020),(04,LT,STEP030))` | Skip if STEP020 RC > 4 OR STEP030 RC > 4 |
| STEP050 | `COND=(00,NE,STEP040)` | Skip if STEP040 RC != 0 |
| STEP050.STEP2 | `COND=(00,NE,STEP1)` | Skip if STEP050.STEP1 RC != 0 |
| STEP060 | `COND=(00,NE,STEP040)` | Skip if STEP040 RC != 0 |
| STEP060.STEP2 | `COND=(00,NE,STEP1)` | Skip if STEP060.STEP1 RC != 0 |
| STEP070 | `COND=((00,NE,STEP050.STEP2),(00,NE,STEP060.STEP2))` | Skip if STEP050.STEP2 RC != 0 OR STEP060.STEP2 RC != 0 |
| STEP080 | `COND=EVEN` | Always runs regardless of previous step return codes |

---

## Input File Layouts

### File 1 - Employee File ([TASK17.EMPLLIST.JCL.txt](DATA/TASK17.EMPLLIST.JCL.txt))

Format: `ID(3) + NAME(10) + ROLE(13)` - `LRECL=26`, `RECFM=FB`, `DSORG=PS`

| Field | Position | Length | Description |
|-------|----------|--------|-------------|
| ID | 1 | 3 | Employee ID (zero-padded) |
| NAME | 4 | 10 | Employee last name |
| ROLE | 14 | 13 | Job role (space-padded) |

```
001IVANOV    DEVELOPER
002PETROV    ANALYST
003SIDOROV   MANAGER
004KOZLOV    DEVELOPER
005MOROZOV   ANALYST
006NOVIKOV   DEVELOPER
007POPOV     MANAGER
008SOKOLOV   DEVELOPER
009LEBEDEV   MANAGER
010ORLOV     ANALYST
```

### File 2 - Salary File ([TASK17.SALARY.JCL.txt](DATA/TASK17.SALARY.JCL.txt))

Format: `ID(3) + SALARY(6)` - `LRECL=9`, `RECFM=FB`, `DSORG=PS`

| Field | Position | Length | Description |
|-------|----------|--------|-------------|
| ID | 1 | 3 | Employee ID (matches File 1) |
| SALARY | 4 | 6 | Salary (zero-padded) |

```
001005000
002003200
003007800
004004500
006006100
007008200
008005500
009006800
```

Note: IDs 005 (MOROZOV) and 010 (ORLOV) are present in the employee file but absent from the salary file. Their salaries will be filled with `000000` by the left join.

---

## STEP040 - JOINKEYS Control Statements

```
SORT FIELDS=COPY
JOINKEYS FILE=F1,FIELDS=(1,3,A)
JOINKEYS FILE=F2,FIELDS=(1,3,A)
JOIN UNPAIRED,F1
REFORMAT FIELDS=(F1:1,23,F2:4,6),FILL=C'0'
```

| Statement | Description |
|-----------|-------------|
| `JOINKEYS FILE=F1,FIELDS=(1,3,A)` | Sort File 1 (EMPLLIST) by ID at position 1, length 3, ascending |
| `JOINKEYS FILE=F2,FIELDS=(1,3,A)` | Sort File 2 (SALARY) by ID at position 1, length 3, ascending |
| `JOIN UNPAIRED,F1` | Left outer join - keep all F1 records even if no match exists in F2 |
| `REFORMAT FIELDS=(F1:1,23,F2:4,6),FILL=C'0'` | Take 23 bytes from F1 (ID+NAME+ROLE, skipping trailing spaces) + 6 bytes from F2 (SALARY); fill missing salary with `000000` |
| `SORT FIELDS=COPY` | No additional sorting after join |

### &&JOINED Record Layout

| Segment | Source | Position in source | Length | Output position | Description |
|---------|--------|--------------------|--------|-----------------|-------------|
| F1:1,23 | EMPLLIST | 1 | 23 | 1 | ID + NAME + ROLE (first 23 bytes) |
| F2:4,6 | SALARY | 4 | 6 | 24 | SALARY (or `000000` if no match) |

Output record length: 23 + 6 = **29 bytes** (LRECL=29)

---

## Final Result

### Joined Dataset (&&JOINED) - Printed by STEP080

All 10 employee records with salary. IDs 005 and 010 have `000000` salary:

```
001IVANOV    DEVELOPER  005000
002PETROV    ANALYST    003200
003SIDOROV   MANAGER    007800
004KOZLOV    DEVELOPER  004500
005MOROZOV   ANALYST    000000
006NOVIKOV   DEVELOPER  006100
007POPOV     MANAGER    008200
008SOKOLOV   DEVELOPER  005500
009LEBEDEV   MANAGER    006800
010ORLOV     ANALYST    000000
```

### Totals by Role - Printed by STEP070

```
TOTAL: 000000000000004
TOTAL: 000000000000003
```

First line: 4 DEVELOPER records
Second line: 3 MANAGER records

---

## Output

| File | Description |
|------|-------------|
| [SYSOUT.STEP040.txt](OUTPUT/SYSOUT.STEP040.txt) | SORT STEP040 sysout - JOINKEYS join statistics |
| [JNF1JMSG.STEP040.txt](OUTPUT/JNF1JMSG.STEP040.txt) | JOINKEYS File 1 (EMPLLIST) sort messages - 10 records in, LRECL=26 |
| [JNF2JMSG.STEP040.txt](OUTPUT/JNF2JMSG.STEP040.txt) | JOINKEYS File 2 (SALARY) sort messages - 8 records in, LRECL=9 |
| [SYSOUT.STEP050.STEP1.txt](OUTPUT/SYSOUT.STEP050.STEP1.txt) | SORT output for DEVELOPER filter - IN: 10, OUT: 4 |
| [TOOLMSG.STEP050.STEP2.txt](OUTPUT/TOOLMSG.STEP050.STEP2.txt) | ICETOOL count messages for DEVELOPER |
| [DFSMSG.STEP050.STEP2.txt](OUTPUT/DFSMSG.STEP050.STEP2.txt) | ICETOOL DFSORT messages for DEVELOPER count |
| [SYSOUT.STEP060.STEP1.txt](OUTPUT/SYSOUT.STEP060.STEP1.txt) | SORT output for MANAGER filter - IN: 10, OUT: 3 |
| [TOOLMSG.STEP060.STEP2.txt](OUTPUT/TOOLMSG.STEP060.STEP2.txt) | ICETOOL count messages for MANAGER |
| [DFSMSG.STEP060.STEP2.txt](OUTPUT/DFSMSG.STEP060.STEP2.txt) | ICETOOL DFSORT messages for MANAGER count |
| [SYSOUT.STEP070.txt](OUTPUT/SYSOUT.STEP070.txt) | SORT output for concatenation - total record count |
| [SORTOUT.STEP070.txt](OUTPUT/SORTOUT.STEP070.txt) | Final counts with prefix: `TOTAL: 000000000000004` (DEVELOPER), `TOTAL: 000000000000003` (MANAGER) |
| [SYSUT2.STEP080.txt](OUTPUT/SYSUT2.STEP080.txt) | Full &&JOINED dataset printed to SYSOUT - all 10 employee records with salary |

---

## Key JCL Concepts Used

- **Inline PROC** - `//SALPROC PROC ... // PEND` defines a reusable inline procedure within the job; can be called multiple times with different parameters
- **Symbolic parameters** - `&ROLE` and `&OUTDSN` are replaced at execution time with values passed from `EXEC SALPROC,ROLE=...,OUTDSN=...`; `SYMBOLS=JCLONLY` in SYSIN DD statement enables parameter substitution in control statements
- **EXPORT SYMLIST=(ROLE)** - Makes the ROLE symbol available globally across all steps in the job
- **Temporary datasets** - `DSN=&&JOINED`, `DSN=&&ROLEOUT`, `DSN=&&DEVCNT`, `DSN=&&MGRCNT` are temporary datasets that exist only during job execution and are automatically deleted when the job completes; shared between steps using `DISP=(NEW,PASS,DELETE)` and `DISP=(OLD,DELETE)`
- **ICETOOL COUNT** - `COUNT FROM(INDD) WRITE(OUTDD)` counts records in INDD and writes a formatted count message to OUTDD
- **OUTREC BUILD** - `OUTREC BUILD=(C'TOTAL: ',1,15)` adds the constant string `TOTAL: ` before the first 15 bytes of each input record
- **COND=EVEN** - Executes the step regardless of previous step return codes; used in STEP080 to ensure diagnostic output is always printed
- **Qualified step names** - `COND=(00,NE,STEP050.STEP2)` references STEP2 within the STEP050 proc execution
- **DD concatenation** - `//SORTIN DD DSN=&&DEVCNT... // DD DSN=&&MGRCNT...` concatenates two input datasets into a single logical file

---

## Notes

- IDs 005 (MOROZOV, ANALYST) and 010 (ORLOV, ANALYST) appear in the employee file but have no salary record. Because this is a left outer join, both are included in `&&JOINED` with salary `000000`.
- The ROLE field in EMPLLIST is 13 characters but the actual role names are shorter. `INCLUDE COND=(14,10,CH,EQ,C'&ROLE')` compares 10 bytes starting at position 14 (skipping the first 3-byte ID and 10-byte NAME). The symbolic parameter `ROLE='DEVELOPER '` must be padded to 10 bytes to match.
- `REFORMAT FIELDS=(F1:1,23,F2:4,6)` takes 23 bytes from F1 instead of the full 26. This trims trailing spaces from the ROLE field in the output.
- STEP070 concatenates the two count datasets (`&&DEVCNT` and `&&MGRCNT`) and adds the prefix `TOTAL: ` to each line using `OUTREC BUILD`.
- STEP080 uses `COND=EVEN` to ensure that `&&JOINED` is always printed to SYSOUT, even if earlier steps fail. This provides diagnostic information for troubleshooting.
- The inline proc SALPROC is called twice in this job: STEP050 for DEVELOPER filtering and STEP060 for MANAGER filtering. Each execution creates its own temporary datasets.
- `SYMBOLS=JCLONLY` in the SYSIN DD tells SORT to perform symbolic substitution only on JCL symbols (like `&ROLE`), not on SORT symbols.
- ICETOOL COUNT writes a formatted output like `000000000000004` (count of 4) with leading zeros to a fixed 15-byte field.
