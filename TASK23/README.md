# Task 23 - GDG (Generation Data Group): Create Base and Manage Generations

## Overview

This job demonstrates Generation Data Group (GDG) operations: defining a GDG base with LIMIT(3) SCRATCH NOEMPTY parameters, creating two generations by writing employee data, and reading generations using relative generation numbers (0) for current and (-1) for previous. GDG is used for managing sequential dataset versions automatically, commonly for backups and historical data.

## Job Details

| Property | Value |
|----------|-------|
| Job Name | TASK23 |
| Job Class | A |
| MSGCLASS | A |
| MSGLEVEL | (1,1) |
| NOTIFY | &SYSUID |

## Steps

| Step | Program | Description |
|------|---------|-------------|
| STEP010 | IDCAMS | Delete GDG base and all generations if they exist; SET MAXCC=0 if RC<=8 |
| STEP020 | IDCAMS | Define GDG base with LIMIT(3) SCRATCH NOEMPTY; skip if STEP010 RC > 8 |
| STEP030 | IEBGENER | Write first generation (+1): 3 employees with GENERATE MAXFLDS; becomes G0001V00 |
| STEP040 | IEBGENER | Write second generation (+2 same job): 4 employees; becomes G0002V00 |
| STEP050 | IEBGENER | Read generation (+1): print G0001V00 (3 employees) |
| STEP060 | IEBGENER | Read generation (+2): print G0002V00 (4 employees) |

## COND Logic

| Step | COND Parameter | Meaning |
|------|----------------|---------|
| STEP020 | (08,LT,STEP010) | Skip if STEP010 RC > 8 (unexpected error during DELETE) |
| STEP030 | (00,NE,STEP020) | Skip if STEP020 RC ≠ 0 (GDG base definition failed) |
| STEP040 | (00,NE,STEP030) | Skip if STEP030 RC ≠ 0 (first generation write failed) |
| STEP050 | (00,NE,STEP040) | Skip if STEP040 RC ≠ 0 (second generation write failed) |
| STEP060 | (00,NE,STEP040) | Skip if STEP040 RC ≠ 0 (second generation write failed) |

## Generation Data Layout

### GDG Generations (DATA/TASK23.HLQ.EMPGDG.JCL)

#### [G0001V00](DATA/TASK23.HLQ.EMPGDG.JCL.G0001V00.txt) (First Generation) - LRECL=36, 3 records

| Position | Length | Type | Description |
|----------|--------|------|-------------|
| 1-3 | 3 | CH | Employee ID |
| 4-11 | 8 | CH | Last Name |
| 12-23 | 12 | CH | Role |
| 24-29 | 6 | CH | Salary |

Sample inline data:

```
001IVANOV    DEVELOPER   005000
002PETROV    ANALYST     003200
003SIDOROV   MANAGER     007800
```

#### [G0002V00](DATA/TASK23.HLQ.EMPGDG.JCL.G0002V00.txt) (Second Generation) - LRECL=36, 4 records (updated salaries)

| Position | Length | Type | Description |
|----------|--------|------|-------------|
| 1-3 | 3 | CH | Employee ID |
| 4-11 | 8 | CH | Last Name |
| 12-23 | 12 | CH | Role |
| 24-29 | 6 | CH | Salary (updated) |

Sample inline data:

```
001IVANOV    DEVELOPER   005500
002PETROV    ANALYST     003500
003SIDOROV   MANAGER     008000
004KOZLOV    DEVELOPER   004500
```

## Output

| File | Description |
|------|-------------|
| [SYSOUT.STEP010.txt](OUTPUT/SYSOUT.STEP010.txt) | IDCAMS DELETE output - GDG base and generations deleted; MAXCC reset to 0 |
| [SYSOUT.STEP020.txt](OUTPUT/SYSOUT.STEP020.txt) | IDCAMS DEFINE GDG output - GDG base created with LIMIT(3) SCRATCH NOEMPTY |
| [SYSUT2.STEP050.txt](OUTPUT/SYSUT2.STEP050.txt) | G0001V00 content - 3 employees (first generation) |
| [SYSUT2.STEP060.txt](OUTPUT/SYSUT2.STEP060.txt) | G0002V00 content - 4 employees with updated salaries (second generation) |

## Key JCL Concepts Used

- **GDG (Generation Data Group)** - Catalog structure for managing related sequential dataset versions; only base is defined, generations created automatically
- **DEFINE GDG** - IDCAMS command to create GDG base entry in catalog; does not allocate physical datasets, only catalog structure
- **LIMIT(n)** - Maximum number of generations to keep in catalog; here LIMIT(3) means maximum 3 generations maintained
- **SCRATCH** - Physically delete oldest generation when limit exceeded; opposite of NOSCRATCH (uncatalog only)
- **NOEMPTY** - When limit hit, remove only oldest one generation; EMPTY would delete all generations at once
- **GDG PURGE** - DELETE command option to remove GDG base and all associated generations in one operation
- **Relative generation number (+n)** - References generation relative to current job; (+1) creates next generation
- **Absolute generation number (GnnnnVmm)** - Physical name assigned at job end; nnnn=generation, mm=version (usually 00)
- **GENERATE MAXFLDS** - IEBGENER control statement to format records to exact LRECL; MAXFLDS=1 means single field spans entire record
- **RECORD FIELD=(36,1,,1)** - Field definition: 36 bytes starting position 1, copied to output position 1
- **(+1) and (+2) in same job** - Both resolve at job end; (+1)→G0001V00, (+2)→G0002V00

## Notes

- STEP010 deletes both GDG base (with GDG PURGE keyword) and all generations (with .* wildcard); IF MAXCC <= 8 THEN SET MAXCC = 0 handles RC=8 (not found)
- STEP020 DEFINE GDG creates only catalog entry, no physical dataset; LIMIT(3) allows maximum 3 generations, SCRATCH physically deletes oldest, NOEMPTY removes one at a time
- STEP030 writes (+1) which becomes G0001V00 at job end; uses GENERATE MAXFLDS=1 with RECORD FIELD=(36,1,,1) to format 36-byte records
- STEP040 writes (+2) in same job which becomes G0002V00; both (+1) and (+2) are relative to job start, resolved at job termination
- GDG naming: Z73460.TASK23.HLQ.EMPGDG.JCL is base name; actual generations are Z73460.TASK23.HLQ.EMPGDG.JCL.G0001V00, G0002V00, etc.
- STEP050 reads DSN=...JCL(+1) which after STEP040 cataloging resolves to G0001V00 (first generation written)
- STEP060 reads DSN=...JCL(+2) which after STEP040 cataloging resolves to G0002V00 (second generation written)
- Relative numbers during job: (+1), (+2) are prospective; after cataloging in read steps they reference existing generations
- When LIMIT(3) is exceeded (4th generation created), oldest generation G0001V00 would be physically deleted (SCRATCH) and only G0002V00, G0003V00, G0004V00 remain
- GDG is commonly used for daily/weekly backups, transaction logs, and versioned datasets where automatic rotation is needed
