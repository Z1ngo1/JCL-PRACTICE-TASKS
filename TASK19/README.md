# Task 19 - VSAM KSDS: DEFINE CLUSTER + REPRO + LISTCAT

## Overview

This job demonstrates VSAM KSDS (Key-Sequenced Data Set) management using IDCAMS: defining a KSDS cluster with index, loading employee data from a sequential file using REPRO, and verifying the cluster structure using LISTCAT. The job creates a temporary sequential input file via IEBGENER before copying its contents into the VSAM cluster.

---

## Job Details

| Property | Value |
|-----------|----------------|
| Job Name | `TASK19` |
| Job Class | `A` |
| MSGCLASS | `A` |
| MSGLEVEL | `(1,1)` |
| NOTIFY | `&SYSUID` |

---

## Steps

| Step | Program | Description |
|---------|----------|---------------------------------------------------------------------------------------------------------------|
| STEP010 | IDCAMS | Delete KSDS cluster [`TASK19.JCL.EMPKSDS`](DATA/TASK19.JCL.EMPKSDS.txt) and sequential file [`TASK19.JCL.INFILE`](DATA/TASK19.JCL.INFILE.txt) if they exist; set MAXCC=0 if RC <= 8 |
| STEP020 | IDCAMS | Define VSAM KSDS cluster with 3-byte key, 36-byte fixed records, FREESPACE(10,20); skip if STEP010 RC > 8 |
| STEP030 | IEBGENER | Create sequential input file [`TASK19.JCL.INFILE`](DATA/TASK19.JCL.INFILE.txt) from 7 inline employee records, LRECL=36; skip if STEP010 RC > 8 |
| STEP040 | IDCAMS | REPRO: copy data from sequential file into KSDS cluster; skip if STEP020 or STEP030 RC != 0 |
| STEP050 | IDCAMS | LISTCAT ALL: display full cluster definition and verify structure; skip if STEP040 RC != 0 |

---

## COND Logic

| Step | COND Parameter | Meaning |
|---------|--------------------------------------|----------------------------------------------------------|
| STEP010 | *(none)* | Always runs |
| STEP020 | `COND=(08,LT,STEP010)` | Skip if STEP010 RC > 8 |
| STEP030 | `COND=(08,LT,STEP010)` | Skip if STEP010 RC > 8 |
| STEP040 | `COND=((00,NE,STEP020),(00,NE,STEP030))` | Skip if STEP020 RC != 0 OR STEP030 RC != 0 |
| STEP050 | `COND=(00,NE,STEP040)` | Skip if STEP040 RC != 0 |

---

## STEP010 - IDCAMS DELETE

**SYSIN control statements:**
```
DELETE Z73460.TASK19.JCL.EMPKSDS CLUSTER PURGE
DELETE Z73460.TASK19.JCL.INFILE NONVSAM SCRATCH PURGE
IF MAXCC <= 8 THEN SET MAXCC = 0
```

| Statement | Description |
|-----------|-------------|
| `DELETE ... CLUSTER PURGE` | Delete VSAM cluster and all components (DATA, INDEX) |
| `DELETE ... NONVSAM SCRATCH PURGE` | Delete non-VSAM sequential file |
| `IF MAXCC <= 8 THEN SET MAXCC = 0` | Treat RC=8 (dataset not found) as success |

---

## STEP020 - IDCAMS DEFINE CLUSTER

`COND=(08,LT,STEP010)` - Skip if STEP010 RC > 8

Defines a VSAM KSDS (Key-Sequenced Data Set) cluster.

**SYSIN control statements:**
```
DEFINE CLUSTER -
  (NAME(Z73460.TASK19.JCL.EMPKSDS) -
   KEYS(3 0) -
   RECORDSIZE(36,36) -
   TRACKS(1 1) -
   INDEXED -
   FREESPACE(10,20)) -
DATA -
  (NAME(Z73460.TASK19.JCL.EMPKSDS.DATA)) -
INDEX -
  (NAME(Z73460.TASK19.JCL.EMPKSDS.INDEX))
```

| Parameter | Description |
|-----------|-------------|
| `NAME(...)` | Cluster name |
| `KEYS(3 0)` | Key: 3 bytes long, starts at offset 0 (first byte of record) |
| `RECORDSIZE(36,36)` | Fixed-length records: 36 bytes average and maximum |
| `TRACKS(1 1)` | Primary allocation: 1 track; secondary allocation: 1 track |
| `INDEXED` | KSDS type (key-sequenced, indexed) |
| `FREESPACE(10,20)` | 10% free space in each CI (Control Interval), 20% free CAs (Control Areas) for future inserts |
| `DATA (NAME(...))` | Name of the data component |
| `INDEX (NAME(...))` | Name of the index component |

---

## STEP030 - IEBGENER Create Input File

`COND=(08,LT,STEP010)` - Skip if STEP010 RC > 8

Creates a sequential file from inline employee data.

**Inline Data (SYSUT1):**

| ID | Last Name | Position | Salary |
|----|-----------|----------|--------|
| 001 | IVANOV | DEVELOPER | 005000 |
| 002 | PETROV | ANALYST | 003200 |
| 003 | SIDOROV | MANAGER | 007800 |
| 004 | KOZLOV | DEVELOPER | 004500 |
| 005 | MOROZOV | ANALYST | 002900 |
| 006 | NOVIKOV | DEVELOPER | 006100 |
| 007 | POPOV | MANAGER | 008200 |

**IEBGENER SYSIN:**
```
GENERATE MAXFLDS=1
RECORD FIELD=(36,1,,1)
```

- `RECORD FIELD=(36,1,,1)` - Copy 36 bytes from input position 1 to output position 1

**Output:** [`TASK19.JCL.INFILE`](DATA/TASK19.JCL.INFILE.txt) - LRECL=36, RECFM=FB

---

## STEP040 - IDCAMS REPRO

`COND=((00,NE,STEP020),(00,NE,STEP030))` - Skip if STEP020 or STEP030 RC != 0

Copies records from sequential file into KSDS cluster.

**SYSIN control statements:**
```
REPRO INFILE(INDD) -
     OUTFILE(OUTDD)
```

**DD Statements:**
- `INDD` - Sequential input file: [`TASK19.JCL.INFILE`](DATA/TASK19.JCL.INFILE.txt)
- `OUTDD` - KSDS cluster: [`TASK19.JCL.EMPKSDS`](DATA/TASK19.JCL.EMPKSDS.txt)

---

## STEP050 - IDCAMS LISTCAT

`COND=(00,NE,STEP040)` - Skip if STEP040 RC != 0

Displays full cluster definition and statistics.

**SYSIN control statements:**
```
LISTCAT ENTRIES(Z73460.TASK19.HLQ.EMPKSDS.JCL) ALL
```

- `ENTRIES(...)` - Cluster name to list
- `ALL` - Display all attributes (cluster, data component, index component, statistics)

---

## Final Result ([`TASK19.JCL.EMPKSDS`](DATA/TASK19.JCL.EMPKSDS.txt))

VSAM KSDS cluster [`TASK19.JCL.EMPKSDS`](DATA/TASK19.JCL.EMPKSDS.txt) created with 7 employee records:

```
001IVANOV    DEVELOPER  005000
002PETROV    ANALYST    003200
003SIDOROV   MANAGER    007800
004KOZLOV    DEVELOPER  004500
005MOROZOV   ANALYST    002900
006NOVIKOV   DEVELOPER  006100
007POPOV     MANAGER    008200
```

Records are indexed by the 3-byte key (employee ID) starting at position 0.

---

## Output

| File | Description |
|------|-------------|
| [SYSOUT.STEP010.txt](OUTPUT/SYSOUT.STEP010.txt) | IDCAMS DELETE messages - cluster and sequential file deleted or not found (RC=8) |
| [SYSOUT.STEP020.txt](OUTPUT/SYSOUT.STEP020.txt) | IDCAMS DEFINE CLUSTER messages - KSDS cluster defined successfully |
| [SYSOUT.STEP040.txt](OUTPUT/SYSOUT.STEP040.txt) | IDCAMS REPRO messages - 7 records copied from sequential file to KSDS |
| [SYSOUT.STEP050.txt](OUTPUT/SYSOUT.STEP050.txt) | IDCAMS LISTCAT output - full cluster definition: key position/length, record size, freespace, data/index component names, allocation statistics |

---

## Key JCL Concepts Used

- **VSAM KSDS (Key-Sequenced Data Set)** - A VSAM dataset type where records are stored and accessed by a unique key field; supports random and sequential access; automatically maintained index for fast key-based lookups
- **DEFINE CLUSTER** - IDCAMS command to create a VSAM dataset; requires key definition (offset and length), record size, space allocation, and organization type (INDEXED for KSDS)
- **KEYS(length offset)** - Defines the key field: `KEYS(3 0)` means a 3-byte key starting at byte 0 (first byte of each record)
- **FREESPACE(CI%, CA%)** - Reserves free space for future record insertions: `FREESPACE(10,20)` means 10% free in each Control Interval, 20% free Control Areas; reduces CI/CA splits and improves performance
- **INDEXED** - Specifies KSDS organization; VSAM automatically builds and maintains an index for key-based access
- **REPRO** - IDCAMS command to copy data between datasets; works with VSAM and non-VSAM files; when loading into KSDS, records must be in ascending key order or REPRO will fail
- **LISTCAT ALL** - Displays comprehensive information about VSAM catalog entries including cluster attributes, data/index component names, space allocation, record counts, and access statistics
- **DATA and INDEX components** - KSDS consists of two physical components: DATA (actual records) and INDEX (key index for fast lookups); both are named automatically as `clustername.DATA` and `clustername.INDEX`

---

## Notes

- VSAM KSDS requires records to be loaded in ascending key order. The input data in STEP030 is already sorted by employee ID (001, 002, 003, ...), so REPRO succeeds.
- `KEYS(3 0)` specifies that the key is 3 bytes long and starts at offset 0. In this task, the key is the employee ID (first 3 bytes of each 36-byte record).
- `RECORDSIZE(36,36)` means fixed-length records of exactly 36 bytes. For variable-length records, you would specify minimum and maximum: `RECORDSIZE(min,max)`.
- `FREESPACE(10,20)` reserves space for future insertions. 10% in each CI (Control Interval, ~4KB) and 20% in each CA (Control Area, multiple CIs). This reduces the frequency of CI/CA splits, which are expensive I/O operations.
- STEP010 deletes both the KSDS cluster and the sequential input file. `DELETE ... CLUSTER` removes all components (DATA, INDEX, catalog entry). `DELETE ... NONVSAM` removes the sequential file.
- `IF MAXCC <= 8 THEN SET MAXCC = 0` treats RC=8 (dataset not found) as success, which is standard practice when deleting datasets that may or may not exist.
- STEP050 LISTCAT output shows detailed cluster information: key offset/length, CISIZE, RECORDSIZE, FREESPACE, REC-TOTAL (record count), allocated extents, and catalog entry type.
- The sequential input file created in STEP030 is temporary and could be deleted after STEP040, but in this job it is kept for reference and stored in the DATA folder.
