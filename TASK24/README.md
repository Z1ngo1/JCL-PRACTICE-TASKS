# Task 24 - Multi-Step Job: PROC, GDG, SORT JOIN, ICETOOL

## Overview

This job is a comprehensive multi-step pipeline combining multiple JCL techniques: an inline PROC (SORTPROC) as a reusable sort template, GDG base creation with LISTCAT existence check, dataset setup, data loading via IEBGENER, sorting via the inline PROC, SORT JOINKEYS inner join of two datasets, ICETOOL salary statistics (MIN/MAX/AVG/COUNT), and final result printing. The job joins EMPBASE (employee records) with SALBASE (salary records) on employee ID and writes the joined output to a new GDG generation.

## Job Details

| Property | Value |
|----------|-------|
| Job Name | TASK24 |
| Job Class | A |
| MSGCLASS | A |
| MSGLEVEL | (1,1) |
| NOTIFY | &SYSUID |

## Steps

| Step | Program | Description |
|------|---------|-------------|
| STEP005 | IDCAMS | LISTCAT to check if GDG base RESULT.JCL exists; RC=0 exists, RC=4 not found |
| STEP007 | IDCAMS | DEFINE GDG base LIMIT(5) SCRATCH NOEMPTY; executed only if STEP005 RC >= 4 (IF/ENDIF) |
| STEP010 | IEFBR14 | Delete [EMPBASE](DATA/TASK24.HLQ.EMPBASE.JCL.txt), [SALBASE](DATA/TASK24.HLQ.SALBASE.JCL.txt), EMPSORT using DISP=(MOD,DELETE,DELETE) |
| STEP020 | IEFBR14 | Create empty EMPBASE (LRECL=40) and SALBASE (LRECL=30) sequential datasets |
| STEP030 | IEBGENER | Load 7 employee records into EMPBASE trimmed to 40 bytes; skip if STEP020 RC ≠ 0 |
| STEP040 | IEBGENER | Load 7 salary records into SALBASE trimmed to 30 bytes; skip if STEP030 RC ≠ 0 |
| STEP050 | SORTPROC | Call inline PROC: sort EMPBASE by ROLE(15,10) then ID(1,4) into EMPSORT; skip if STEP040 RC ≠ 0 |
| STEP060 | SORT | JOINKEYS inner join EMPSORT(F1) + SALBASE(F2) on ID(1,4); REFORMAT F1:1-32 + F2:1-28 = 60 bytes; output to GDG(+1) |
| STEP070 | ICETOOL | STATS on RESULT.JCL(+1): salary field(37,6,ZD) MIN/MAX/AVG/COUNT; skip if STEP060 RC ≠ 0 |
| STEP080 | IEBGENER | Print final GDG(+1) joined content to SYSOUT; skip if STEP070 RC ≠ 0 |

## COND Logic

| Step | COND Parameter | Meaning |
|------|----------------|---------|
| STEP007 | IF STEP005.RC>=4 THEN ... ENDIF | Execute only when GDG base does not exist (LISTCAT returned RC=4) |
| STEP030 | (00,NE,STEP020) | Skip if STEP020 RC ≠ 0 (dataset creation failed) |
| STEP040 | (00,NE,STEP030) | Skip if STEP030 RC ≠ 0 (EMPBASE load failed) |
| STEP050 | (00,NE,STEP040) | Skip if STEP040 RC ≠ 0 (SALBASE load failed) |
| STEP060 | (00,NE,STEP050.STEP1) | Skip if SORTPROC STEP1 RC ≠ 0 (sort failed) |
| STEP070 | (00,NE,STEP060) | Skip if STEP060 RC ≠ 0 (join failed) |
| STEP080 | (00,NE,STEP070) | Skip if STEP070 RC ≠ 0 (ICETOOL failed) |

## Input Data Layout

### Input Datasets (DATA/TASK24.HLQ)

#### [EMPBASE](DATA/TASK24.HLQ.EMPBASE.JCL.txt) - LRECL=40, 7 records

| Position | Length | Type | Description |
|----------|--------|------|-------------|
| 1-4 | 4 | CH | Employee ID (0001-0007) |
| 5-12 | 8 | CH | Last Name |
| 13-23 | 11 | CH | Role (DEVELOPER/ANALYST/MANAGER) |
| 24-25 | 2 | CH | Gender (M/F) |
| 26-29 | 4 | CH | Birth Year |

Sample inline data:

```
0001IVANOV     DEVELOPER  M 1985
0002PETROV     ANALYST    M 1990
0003SIDOROV    MANAGER    M 1978
0004KOZLOV     DEVELOPER  M 1992
0005MOROZOV    ANALYST    F 1988
0006NOVIKOV    DEVELOPER  M 1995
0007POPOV      MANAGER    F 1982
```

#### [SALBASE](DATA/TASK24.HLQ.SALBASE.JCL.txt) - LRECL=30, 7 records

| Position | Length | Type | Description |
|----------|--------|------|-------------|
| 1-4 | 4 | CH | Employee ID (join key) |
| 5-10 | 6 | CH | Salary amount |
| 11-20 | 10 | CH | Role (DEVELOPER/ANALYST/MANAGER) |

Sample inline data:

```
0001005000DEVELOPER
0002003200ANALYST
0003007800MANAGER
0004004500DEVELOPER
0005002900ANALYST
0006006100DEVELOPER
0007008200MANAGER
```

### Output Dataset (DATA/TASK24.HLQ.RESULT.JCL)

#### [RESULT GDG (+1)](DATA/TASK24.HLQ.RESULT.JCL/G0001V00.txt) - LRECL=60, 7 records

> REFORMAT FIELDS=(F1:1,32,F2:1,28) = 60 bytes total; written by STEP060 SORT JOINKEYS

| Position | Length | Source | Description |
|----------|--------|--------|-------------|
| 1-4 | 4 | F1 | Employee ID |
| 5-12 | 8 | F1 | Last Name |
| 13-23 | 11 | F1 | Role |
| 24-25 | 2 | F1 | Gender |
| 26-29 | 4 | F1 | Birth Year |
| 30-32 | 3 | F1 | Padding |
| 33-36 | 4 | F2 | Employee ID (from SALBASE) |
| 37-42 | 6 | F2 | Salary |
| 43-52 | 10 | F2 | Role (from SALBASE) |
| 53-60 | 8 | F2 | Padding |

## Output

| File | Description |
|------|-------------|
| [SYSOUT.STEP005.txt](OUTPUT/SYSOUT.STEP005.txt) | IDCAMS LISTCAT output - GDG base existence check |
| [SYSOUT.STEP050.STEP1.txt](OUTPUT/SYSOUT.STEP050.STEP1.txt) | SORTPROC output - EMPBASE sorted by ROLE then ID into EMPSORT |
| [SYSOUT.STEP060.txt](OUTPUT/SYSOUT.STEP060.txt) | SORT JOINKEYS output - inner join messages and statistics |
| [JNF1JMSG.STEP060.txt](OUTPUT/JNF1JMSG.STEP060.txt) | Join messages for F1 (EMPSORT) |
| [JNF2JMSG.STEP060.txt](OUTPUT/JNF2JMSG.STEP060.txt) | Join messages for F2 (SALBASE) |
| [TOOLMSG.STEP070.txt](OUTPUT/TOOLMSG.STEP070.txt) | ICETOOL STATS output - COUNT=7, MIN=002900, MAX=008200, AVG=005385, TOTAL=037700 |
| [DFSMSG.STEP070.txt](OUTPUT/DFSMSG.STEP070.txt) | ICETOOL DFSMSdss messages |
| [SYSUT2.STEP080.txt](OUTPUT/SYSUT2.STEP080.txt) | Final joined GDG content - 7 employees sorted by ROLE then ID |

## Key JCL Concepts Used

- **Inline PROC (SORTPROC)** - Procedure defined within the same JCL using PROC/PEND statements; reusable sort template with symbolic parameters &SORTIN and &SORTOUT; SYSIN DD DUMMY overridden by caller via STEP1.SYSIN
- **Symbolic parameters** - Parameters like &SORTIN passed at EXEC SORTPROC,SORTIN=dsname; resolved at execution time
- **STEP1.SYSIN DD** - Overrides SYSIN=DUMMY inside the PROC with actual SORT FIELDS; uses stepname.ddname notation
- **LISTCAT ENTRIES() GDG** - IDCAMS command to check if GDG base exists in catalog; returns RC=0 (found) or RC=4 (not found)
- **IF/ENDIF conditional** - JCL IF statement to conditionally execute STEP007 only when LISTCAT reports GDG not found
- **DISP=(MOD,DELETE,DELETE)** - Allocate with MOD (creates if not exists), delete on normal and abnormal; safe way to delete without IDCAMS
- **SORT JOINKEYS** - Performs inner join between two datasets matched on key fields; JOINKEYS FILES=F1/F2 with FIELDS=(pos,len,order)
- **REFORMAT FIELDS=(F1:pos,len,F2:pos,len)** - Concatenates fields from both join files into output record
- **ICETOOL STATS** - Computes MIN/MAX/AVG/TOTAL/COUNT statistics on numeric fields; ON(pos,len,format) specifies the field
- **ZD (Zoned Decimal)** - Numeric format where each byte represents one digit; used for salary statistics
- **COND=(00,NE,STEP.PROC.STEP)** - References RC of a step inside a PROC using dotted notation STEP050.STEP1
- **GDG(+1) output** - Output dataset written as new GDG generation; physical name resolved at job end

## Notes

- STEP005/007 use IF/ENDIF (JCL conditional) rather than COND parameter; allows defining GDG base only on first job run
- STEP010 uses DISP=(MOD,DELETE,DELETE) with IEFBR14 instead of IDCAMS DELETE; SPACE=(TRK,(1,0)) needed if dataset does not exist yet
- SORTPROC defined with SYSIN DD DUMMY; actual sort fields supplied by STEP050 via STEP1.SYSIN override; symbolic parameters SORTIN and SORTOUT resolved at EXEC time
- STEP060 COND references STEP050.STEP1 - the STEP1 substep inside SORTPROC; dotted notation identifies proc step
- SORT FIELDS=(15,10,CH,A,1,4,CH,A) sorts by Role (pos 15, len 10) ascending then by ID (pos 1, len 4) ascending
- JOINKEYS inner join: only records with matching ID in both F1 and F2 appear in output; all 7 employees have matching salary records
- REFORMAT creates 60-byte output: 32 bytes from employee record + 28 bytes from salary record
- Salary position in output record: starts at byte 37 (F2 starts at byte 33, salary is bytes 5-10 of F2 = bytes 37-42 in output)
- ICETOOL STATS ON(37,6,ZD): COUNT=7, MIN=002900, MAX=008200, AVG=005385, TOTAL=037700
- Final output sorted by role alphabetically (ANALYST, DEVELOPER, MANAGER) then by ID within each role
- GDG naming: RESULT.JCL is base name; actual generation written as RESULT.JCL.G0001V00 on first run; LIMIT(5) allows up to 5 generations
