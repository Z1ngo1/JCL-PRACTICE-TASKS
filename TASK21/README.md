# Task 21 - IEBCOPY: PDS Management and Selective Copy

## Overview

This job demonstrates PDS (Partitioned Data Set) operations using IEBCOPY utility: creating PDS libraries, loading members via IEBGENER, performing selective copy of members between libraries, and compressing a PDS to reclaim unused space. The job creates two PDS libraries (SRCLIB and TGTLIB), loads three members into SRCLIB (MEMBER1-DEVELOPERS, MEMBER2-ANALYSTS, MEMBER3-MANAGERS), copies only MEMBER1 and MEMBER3 to TGTLIB (excluding MEMBER2 intentionally), and compresses SRCLIB in place.

## Job Details

| Property | Value |
|----------|-------|
| Job Name | TASK21 |
| Job Class | A |
| MSGCLASS | A |
| MSGLEVEL | (1,1) |
| NOTIFY | &SYSUID |

## Steps

| Step | Program | Description |
|------|---------|-------------|
| STEP010 | IDCAMS | Delete [SRCLIB](DATA/TASK21.JCL.SRCLIB) and [TGTLIB](DATA/TASK21.JCL.TGTLIB) if they exist; SET MAXCC=0 if RC<=8 |
| STEP020 | IEFBR14 | Create two empty PDS libraries with directory blocks SPACE=(TRK,(2,2,10)); skip if STEP010 RC < 8 |
| STEP030 | IEBGENER | Load inline [MEMBER1](DATA/TASK21.JCL.SRCLIB/MEMBER1.txt) (4 developers) into SRCLIB; skip if STEP020 RC ≠ 0 |
| STEP033 | IEBGENER | Load inline [MEMBER2](DATA/TASK21.JCL.SRCLIB/MEMBER2.txt) (3 analysts) into SRCLIB; skip if STEP020 RC ≠ 0 |
| STEP036 | IEBGENER | Load inline [MEMBER3](DATA/TASK21.JCL.SRCLIB/MEMBER3.txt) (3 managers) into SRCLIB; skip if STEP020 RC ≠ 0 |
| STEP040 | IEBCOPY | Selective COPY: copy only [MEMBER1](DATA/TASK21.JCL.TGTLIB/MEMBER1.txt) and [MEMBER3](DATA/TASK21.JCL.TGTLIB/MEMBER3.txt) to [TGTLIB](DATA/TASK21.JCL.TGTLIB) using SELECT; skip if any STEP030/033/036 failed |
| STEP050 | IEBCOPY | COMPRESS [SRCLIB](DATA/TASK21.JCL.SRCLIB) in place (INDD=OUTDD=SYSUT1); reclaim space from deleted/replaced members |

## COND Logic

| Step | COND Parameter | Meaning |
|------|----------------|---------|
| STEP020 | (08,LT,STEP010) | Skip if STEP010 RC > 8 (unexpected error during DELETE) |
| STEP030 | (00,NE,STEP020) | Skip if STEP020 RC ≠ 0 (PDS creation failed) |
| STEP033 | (00,NE,STEP020) | Skip if STEP020 RC ≠ 0 (PDS creation failed) |
| STEP036 | (00,NE,STEP020) | Skip if STEP020 RC ≠ 0 (PDS creation failed) |
| STEP040 | ((00,NE,STEP030),(00,NE,STEP033),(00,NE,STEP036)) | Skip if ANY of the three member load steps failed |
| STEP050 | (00,NE,STEP040) | Skip if STEP040 RC ≠ 0 (selective copy failed) |

## Member Data Layout

### SRCLIB Members [SRCLIB](DATA/TASK21.JCL.SRCLIB)

#### [MEMBER1](DATA/TASK21.JCL.SRCLIB/MEMBER1.txt) (Developers) - LRECL=80, 4 records

| Position | Length | Type | Description |
|----------|--------|------|-------------|
| 1-3 | 3 | CH | Employee ID |
| 4-11 | 8 | CH | Last Name |
| 12-23 | 12 | CH | Role (DEVELOPER) |
| 24-29 | 6 | CH | Salary |

Sample inline data:

```
001IVANOV    DEVELOPER   005000
004KOZLOV    DEVELOPER   004500
006NOVIKOV   DEVELOPER   006100
008SOKOLOV   DEVELOPER   005500
```

#### [MEMBER2](DATA/TASK21.JCL.SRCLIB/MEMBER2.txt) (Analysts) - LRECL=80, 3 records

| Position | Length | Type | Description |
|----------|--------|------|-------------|
| 1-3 | 3 | CH | Employee ID |
| 4-11 | 8 | CH | Last Name |
| 12-23 | 12 | CH | Role (ANALYST) |
| 24-29 | 6 | CH | Salary |

Sample inline data:

```
002PETROV    ANALYST     003200
005MOROZOV   ANALYST     002900
010ORLOV     ANALYST     003100
```

#### [MEMBER3](DATA/TASK21.JCL.SRCLIB/MEMBER3.txt) (Managers) - LRECL=80, 3 records

| Position | Length | Type | Description |
|----------|--------|------|-------------|
| 1-3 | 3 | CH | Employee ID |
| 4-11 | 8 | CH | Last Name |
| 12-23 | 12 | CH | Role (MANAGER) |
| 24-29 | 6 | CH | Salary |

Sample inline data:

```
003SIDOROV   MANAGER     007800
007POPOV     MANAGER     008200
009LEBEDEV   MANAGER     006800
```

### TGTLIB Members [TGTLIB](DATA/TASK21.JCL.TGTLIB)

> Copied from SRCLIB via IEBCOPY SELECT in STEP040 (MEMBER2 excluded intentionally)

#### [MEMBER1](DATA/TASK21.JCL.TGTLIB/MEMBER1.txt) (Developers) - LRECL=80, 4 records

| Position | Length | Type | Description |
|----------|--------|------|-------------|
| 1-3 | 3 | CH | Employee ID |
| 4-11 | 8 | CH | Last Name |
| 12-23 | 12 | CH | Role (DEVELOPER) |
| 24-29 | 6 | CH | Salary |

Same data as SRCLIB MEMBER1 (copied via SELECT MEMBER=((MEMBER1,,R)))

#### [MEMBER3](DATA/TASK21.JCL.TGTLIB/MEMBER3.txt) (Managers) - LRECL=80, 3 records

| Position | Length | Type | Description |
|----------|--------|------|-------------|
| 1-3 | 3 | CH | Employee ID |
| 4-11 | 8 | CH | Last Name |
| 12-23 | 12 | CH | Role (MANAGER) |
| 24-29 | 6 | CH | Salary |

Same data as SRCLIB MEMBER3 (copied via SELECT MEMBER=((MEMBER3,,R)))

## Output

| File | Description |
|------|-------------|
| [SYSOUT.STEP010.txt](OUTPUT/SYSOUT.STEP010.txt) | IDCAMS DELETE output - both PDS libraries deleted; MAXCC reset to 0 |
| [SYSOUT.STEP040.txt](OUTPUT/SYSOUT.STEP040.txt) | IEBCOPY selective copy output - 2 members (MEMBER1, MEMBER3) copied to TGTLIB |
| [SYSOUT.STEP050.txt](OUTPUT/SYSOUT.STEP050.txt) | IEBCOPY compress output - all 3 members in SRCLIB compressed in place |

## Key JCL Concepts Used

- **IEBCOPY** - IBM utility for copying and managing PDS members; performs copy, merge, compress, and unload operations
- **IEBCOPY SELECT** - Control statement to selectively copy specific members using `SELECT MEMBER=((name1,,R),(name2,,R))`; R=replace if exists
- **IEBCOPY COMPRESS** - Operation to reorganize PDS and reclaim space from deleted/replaced members using `INDD=OUTDD=same-dataset` syntax
- **PDS (Partitioned Data Set)** - Dataset organization type that stores multiple members (named subsets); consists of directory and data area
- **Directory Blocks** - PDS directory stores member names and locations; each block holds ~6 member entries; specified as third SPACE parameter (2,2,10)
- **IEFBR14 for PDS creation** - Dummy program that allocates datasets without processing; efficient way to create empty PDS structure with SPACE parameter
- **Multiple COND tests** - STEP040 uses `((cond1),(cond2),(cond3))` syntax to skip if ANY condition is true (logical OR)
- **MAXCC management** - IDCAMS `SET MAXCC=0` resets job condition code; allows continuation after acceptable errors like RC=8 (dataset not found)
- **In-place compression** - IEBCOPY with INDD=OUTDD pointing to same DD (SYSUT1) compresses without temporary copy

## Notes

- STEP010 uses `IF MAXCC <= 8 THEN SET MAXCC = 0` because RC=8 from DELETE (dataset not found) is normal and should not fail the job
- STEP020 creates two PDS libraries with SPACE=(TRK,(2,2,10)): 2 primary tracks, 2 secondary tracks, 10 directory blocks (~60 member capacity)
- All three IEBGENER steps (STEP030/033/036) load inline data into PDS members; each creates a separate member in SRCLIB
- STEP040 intentionally excludes MEMBER2 (Analysts) from the copy operation; only MEMBER1 and MEMBER3 are copied to TGTLIB
- The R parameter in SELECT MEMBER=((MEMBER1,,R),(MEMBER3,,R)) means "replace if member already exists in output PDS"
- After STEP040, SRCLIB contains 3 members (MEMBER1, MEMBER2, MEMBER3) but TGTLIB contains only 2 members (MEMBER1, MEMBER3)
- STEP050 compression reorganizes the PDS directory and data area; important for performance and space reclamation
- IEBCOPY messages: IEB154I confirms successful operation, IEB098I reports copy statistics, IEB152I shows compression results
