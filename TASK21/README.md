# TASK21: IEBCOPY - PDS Management and Selective Copy

## Overview
Demonstrates PDS (Partitioned Data Set) management using IEBCOPY utility: creating PDS libraries, loading members, performing selective copying, and compressing datasets to reclaim unused space.

## Job Details

| Parameter | Value |
|-----------|-------|
| Job Name | TASK21 |
| Job Class | A |
| Message Class | A |
| Message Level | (1,1) |

## Job Steps

### STEP010: Delete PDS Libraries (IDCAMS)
**Program:** IDCAMS  
**Purpose:** Delete SRCLIB and TGTLIB if they exist (RC=8 is acceptable - dataset not found)  
**Input:**
- DELETE commands for both PDS libraries
- SET MAXCC=0 if RC<=8

**Output:** [SYSOUT.STEP010.txt](OUTPUT/SYSOUT.STEP010.txt)

### STEP020: Create Empty PDS Libraries (IEFBR14)
**Program:** IEFBR14 (dummy program)  
**Purpose:** Create two empty PDS libraries with directory space  
**COND:** (08,LT,STEP010) - Skip if STEP010 RC < 8  
**Datasets Created:**
- SRCLIB: Source library for loading members
- TGTLIB: Target library for selective copy

**Space Allocation:** SPACE=(TRK,(2,2,10))
- Primary: 2 tracks
- Secondary: 2 tracks
- Directory blocks: 10 (60 members capacity)

### STEP030: Load MEMBER1 (Developers)
**Program:** IEBGENER  
**Purpose:** Load MEMBER1 containing developer records into SRCLIB  
**COND:** (00,NE,STEP020) - Skip if STEP020 failed  
**Input:** Inline data (4 developer records)

### STEP033: Load MEMBER2 (Analysts)
**Program:** IEBGENER  
**Purpose:** Load MEMBER2 containing analyst records into SRCLIB  
**COND:** (00,NE,STEP020) - Skip if STEP020 failed  
**Input:** Inline data (3 analyst records)

### STEP036: Load MEMBER3 (Managers)
**Program:** IEBGENER  
**Purpose:** Load MEMBER3 containing manager records into SRCLIB  
**COND:** (00,NE,STEP020) - Skip if STEP020 failed  
**Input:** Inline data (3 manager records)

### STEP040: Selective Copy to TGTLIB (IEBCOPY)
**Program:** IEBCOPY  
**Purpose:** Copy only MEMBER1 and MEMBER3 to TGTLIB (exclude MEMBER2)  
**COND:** ((00,NE,STEP030),(00,NE,STEP033),(00,NE,STEP036)) - Skip if any load step failed  
**Operation:**
```
COPY INDD=INPUT,OUTDD=OUTPUT
SELECT MEMBER=((MEMBER1,,R),(MEMBER3,,R))
```
- R = Replace if member already exists in output
- MEMBER2 (Analysts) is intentionally excluded

**Output:** [SYSOUT.STEP040.txt](OUTPUT/SYSOUT.STEP040.txt)

### STEP050: Compress SRCLIB In-Place (IEBCOPY)
**Program:** IEBCOPY  
**Purpose:** Compress SRCLIB to reclaim space from deleted/replaced members  
**COND:** (00,NE,STEP040) - Skip if STEP040 failed  
**Operation:**
```
COPY INDD=SYSUT1,OUTDD=SYSUT1
```
- INDD=OUTDD syntax indicates in-place compression
- All three members compressed

**Output:** [SYSOUT.STEP050.txt](OUTPUT/SYSOUT.STEP050.txt)

## Condition Code Logic

| Step | COND Parameter | Meaning |
|------|----------------|----------|
| STEP020 | (08,LT,STEP010) | Skip if STEP010 RC < 8 (unexpected error) |
| STEP030 | (00,NE,STEP020) | Skip if STEP020 RC ≠ 0 |
| STEP033 | (00,NE,STEP020) | Skip if STEP020 RC ≠ 0 |
| STEP036 | (00,NE,STEP020) | Skip if STEP020 RC ≠ 0 |
| STEP040 | Multiple | Skip if any of STEP030/033/036 RC ≠ 0 |
| STEP050 | (00,NE,STEP040) | Skip if STEP040 RC ≠ 0 |

## Member Layout

### MEMBER1 (Developers) - 4 records
```
ID        NAME       ROLE       SALARY
001IVANOV   DEVELOPER  005000
004KOZLOV   DEVELOPER  004500
006NOVIKOV  DEVELOPER  006100
008SOKOLOV  DEVELOPER  005500
```

### MEMBER2 (Analysts) - 3 records (NOT copied to TGTLIB)
```
ID        NAME       ROLE       SALARY
002PETROV   ANALYST    003200
005MOROZOV  ANALYST    002900
010ORLOV    ANALYST    003100
```

### MEMBER3 (Managers) - 3 records
```
ID        NAME       ROLE       SALARY
003SIDOROV  MANAGER    007800
007POPOV    MANAGER    008200
009LEBEDEV  MANAGER    006800
```

## Output

| File | Description |
|------|-------------|
| [SYSOUT.STEP010.txt](OUTPUT/SYSOUT.STEP010.txt) | IDCAMS output - both datasets deleted successfully |
| [SYSOUT.STEP040.txt](OUTPUT/SYSOUT.STEP040.txt) | IEBCOPY selective copy - 2 members copied to TGTLIB |
| [SYSOUT.STEP050.txt](OUTPUT/SYSOUT.STEP050.txt) | IEBCOPY compress - all 3 members compressed in SRCLIB |

## Key JCL Concepts Used

### IEBCOPY
IBM utility for copying and managing PDS members with multiple functions:
- **Selective Copy:** Copy specific members using SELECT statements
- **Compress:** Reorganize PDS to reclaim space from deleted/replaced members
- **Replace Mode:** R parameter replaces existing members in output PDS
- **In-Place Compression:** INDD=OUTDD=same-dataset syntax compresses without creating temporary copy

### PDS (Partitioned Data Set)
Dataset organization that stores multiple members (named subsets) in a single dataset:
- **Directory:** Stores member names and locations (allocated as directory blocks)
- **Data Area:** Stores actual member content
- **Directory Blocks:** Each block holds ~6 member entries; 10 blocks = 60 members capacity
- **Compression:** Removes fragmentation caused by member updates/deletions

### SELECT Statement
IEBCOPY control statement for selective member operations:
- Syntax: SELECT MEMBER=((name1,,R),(name2,,R))
- R = Replace if member exists in output
- Omitted members are not copied (intentional filtering)

### IEFBR14 for PDS Creation
Dummy program that allocates datasets without processing data:
- SPACE parameter includes directory allocation: (TRK,(2,2,10))
- Third value (10) specifies directory blocks for member storage
- Efficient way to create empty PDS structure

### Conditional COND with Multiple Steps
STEP040 uses multiple conditions: ((00,NE,STEP030),(00,NE,STEP033),(00,NE,STEP036))
- Parentheses group multiple conditions
- Step skipped if ANY condition is true (logical OR)
- Ensures all members loaded before attempting copy

### IDCAMS MAXCC Management
SET MAXCC=0 statement resets job condition code:
- Allows job to continue after acceptable errors (dataset not found)
- RC=8 from DELETE is normal when dataset doesn't exist
- Prevents job failure from expected conditions

## Notes

- **STEP010 MAXCC Reset:** IF MAXCC <= 8 THEN SET MAXCC = 0 ensures RC=8 (dataset not found) doesn't cause job failure, allowing subsequent steps to execute normally
- **Selective Copy Purpose:** STEP040 intentionally excludes MEMBER2 (Analysts), demonstrating how to copy only specific members between PDS libraries
- **SRCLIB Contains 3 Members:** After loading, SRCLIB holds MEMBER1 (Developers), MEMBER2 (Analysts), and MEMBER3 (Managers) - total 10 records
- **TGTLIB Contains 2 Members:** After selective copy, TGTLIB holds only MEMBER1 (Developers) and MEMBER3 (Managers) - total 7 records
- **Compression Reclaims Space:** STEP050 compression reorganizes SRCLIB to eliminate fragmentation, improving access performance and reclaiming unused directory space
- **Replace Mode (R):** The R parameter in SELECT ensures that if members already exist in TGTLIB, they will be replaced rather than causing an error
- **In-Place Compression Syntax:** INDD=SYSUT1,OUTDD=SYSUT1 tells IEBCOPY to compress the dataset without creating a temporary copy, saving space and processing time
- **Directory Block Calculation:** SPACE=(TRK,(2,2,10)) allocates 10 directory blocks, providing capacity for approximately 60 members (6 entries per block)
- **IEBCOPY Messages:** IEB154I confirms successful copy, IEB098I reports copy statistics, IEB152I shows compression results
