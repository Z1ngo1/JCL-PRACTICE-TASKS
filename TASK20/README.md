# Task 20 - VSAM KSDS: VERIFY + REPRO EXPORT + ALTER FREESPACE + REPRO INSERT

## Overview

This job demonstrates advanced VSAM KSDS operations: verifying cluster integrity, backing up (unloading) VSAM data to a sequential file using REPRO, altering FREESPACE parameters, formatting new inline records via SORT, and inserting them into the KSDS cluster. The job builds on TASK19's KSDS cluster by adding 3 new employees.

---

## Job Details

| Property | Value |
|-----------|----------------|
| Job Name | `TASK20` |
| Job Class | `A` |
| MSGCLASS | `A` |
| MSGLEVEL | `(1,1)` |
| NOTIFY | `&SYSUID` |

---

## Steps

| Step | Program | Description |
|---------|----------|---------------------------------------------------------------------------------------------------------------|
| STEP010 | IDCAMS | VERIFY: check KSDS cluster [`TASK19.HLQ.EMPKSDS.JCL`](DATA/TASK19.HLQ.EMPKSDS.JCL.txt) for structural integrity |
| STEP015 | IEFBR14 | Delete backup file [`TASK20.HLQ.EMPBKUP.JCL`](DATA/TASK20.HLQ.EMPBKUP.JCL.txt) if it exists |
| STEP020 | IDCAMS | REPRO EXPORT: unload KSDS to sequential backup file; skip if STEP010 or STEP015 RC != 0 |
| STEP030 | IDCAMS | ALTER: change cluster FREESPACE to (10,30); skip if STEP020 RC != 0 |
| STEP035 | SORT | Format inline 80-byte records -> 36-byte LRECL via OUTREC; save to `&&TEMPFILE`; skip if STEP030 RC != 0 |
| STEP040 | IDCAMS | REPRO INSERT: add 3 new records from `&&TEMPFILE` into KSDS; skip if STEP030 or STEP035 RC != 0 |

---

## COND Logic

| Step | COND Parameter | Meaning |
|---------|--------------------------------------|----------------------------------------------------------|
| STEP010 | *(none)* | Always runs |
| STEP015 | *(none)* | Always runs |
| STEP020 | `COND=((00,NE,STEP010),(00,NE,STEP015))` | Skip if STEP010 RC != 0 OR STEP015 RC != 0 |
| STEP030 | `COND=(00,NE,STEP020)` | Skip if STEP020 RC != 0 |
| STEP035 | `COND=(00,NE,STEP030)` | Skip if STEP030 RC != 0 |
| STEP040 | `COND=((00,NE,STEP030),(00,NE,STEP035))` | Skip if STEP030 RC != 0 OR STEP035 RC != 0 |

---

## STEP010 - IDCAMS VERIFY

**SYSIN control statements:**
```
VERIFY DATASET(Z73460.TASK19.HLQ.EMPKSDS.JCL)
```

Verifies the structural integrity of the KSDS cluster by checking:
- End-of-file (EOF) pointers
- Index component consistency
- Control Interval / Control Area structure
- Recovery from potential abends or crashes

VERIFY must be run after a system crash or abend before performing any read/write operations on the cluster.

---

## STEP015 - IEFBR14 Delete Backup File

Deletes the backup file if it already exists.

**DD Statement:**
```
//DELDD1 DD DSN=Z73460.TASK20.HLQ.EMPBKUP.JCL,
// DISP=(MOD,DELETE,DELETE),
// SPACE=(TRK,(1,1))
```

---

## STEP020 - IDCAMS REPRO EXPORT

`COND=((00,NE,STEP010),(00,NE,STEP015))` - Skip if STEP010 or STEP015 RC != 0

Unloads (exports) VSAM KSDS content to a sequential backup file.

**SYSIN control statements:**
```
REPRO INFILE(INDD) -
     OUTFILE(OUTDD)
```

**DD Statements:**
- `INDD` - KSDS cluster: [`TASK19.HLQ.EMPKSDS.JCL`](DATA/TASK19.HLQ.EMPKSDS.JCL.txt)
- `OUTDD` - Sequential backup file: [`TASK20.HLQ.EMPBKUP.JCL`](DATA/TASK20.HLQ.EMPBKUP.JCL.txt) (LRECL=36, RECFM=FB)

This creates a portable sequential file containing all KSDS records. The backup can later be used to restore the cluster using REPRO in the opposite direction.

---

## STEP030 - IDCAMS ALTER FREESPACE

`COND=(00,NE,STEP020)` - Skip if STEP020 RC != 0

Modifies the FREESPACE parameter of the KSDS DATA component.

**SYSIN control statements:**
```
ALTER Z73460.TASK19.HLQ.EMPKSDS.JCL.DATA -
     FREESPACE(10,30)
```

- `FREESPACE(10,30)` - 10% free in each CI (Control Interval), 30% free in each CA (Control Area)
- Increased CA freespace (30% vs. original 20%) provides more room for future insertions without triggering expensive CA splits

---

## STEP035 - SORT Format Records

`COND=(00,NE,STEP030)` - Skip if STEP030 RC != 0

Trims inline 80-byte JCL cards to 36-byte LRECL records using SORT OUTREC.

**Inline Data (SORTIN):**

| ID | Last Name | Position | Salary |
|----|-----------|----------|--------|
| 008 | SOKOLOV | DEVELOPER | 005500 |
| 009 | LEBEDEV | MANAGER | 006800 |
| 010 | ORLOV | ANALYST | 003100 |

**SYSIN control statements:**
```
SORT FIELDS=COPY
OUTREC BUILD=(1,36)
```

- `SORT FIELDS=COPY` - No sorting; records passed through as-is
- `OUTREC BUILD=(1,36)` - Extract first 36 bytes of each input record

**Output:** `&&TEMPFILE` - Temporary dataset, LRECL=36

---

## STEP040 - IDCAMS REPRO INSERT

`COND=((00,NE,STEP030),(00,NE,STEP035))` - Skip if STEP030 or STEP035 RC != 0

Inserts new records from `&&TEMPFILE` into the KSDS cluster.

**SYSIN control statements:**
```
REPRO INFILE(TEMPREC) -
     OUTFILE(OUTKSDS)
```

**DD Statements:**
- `TEMPREC` - Temporary file: `&&TEMPFILE` (3 new employees)
- `OUTKSDS` - KSDS cluster: [`TASK19.HLQ.EMPKSDS.JCL.NEW`](DATA/TASK19.HLQ.EMPKSDS.JCL.NEW.txt)

The new records are inserted in key order. The KSDS index is automatically updated.

---

## Final Result

VSAM KSDS cluster [`TASK19.HLQ.EMPKSDS.JCL.NEW`](DATA/TASK19.HLQ.EMPKSDS.JCL.NEW.txt) now contains 10 employee records (7 original + 3 new):

```
001IVANOV    DEVELOPER  005000
002PETROV    ANALYST    003200
003SIDOROV   MANAGER    007800
004KOZLOV    DEVELOPER  004500
005MOROZOV   ANALYST    002900
006NOVIKOV   DEVELOPER  006100
007POPOV     MANAGER    008200
008SOKOLOV   DEVELOPER  005500
009LEBEDEV   MANAGER    006800
010ORLOV     ANALYST    003100
```

Sequential backup file [`TASK20.HLQ.EMPBKUP.JCL`](DATA/TASK20.HLQ.EMPBKUP.JCL.txt) contains the original 7 records.

---

## Output

| File | Description |
|------|-------------|
| [SYSOUT.STEP010.txt](OUTPUT/SYSOUT.STEP010.txt) | IDCAMS VERIFY output - cluster integrity check passed |
| [SYSOUT.STEP020.txt](OUTPUT/SYSOUT.STEP020.txt) | IDCAMS REPRO EXPORT output - 7 records unloaded to backup file |
| [SYSOUT.STEP030.txt](OUTPUT/SYSOUT.STEP030.txt) | IDCAMS ALTER output - FREESPACE changed to (10,30) |
| [SYSOUT.STEP040.txt](OUTPUT/SYSOUT.STEP040.txt) | IDCAMS REPRO INSERT output - 3 records added to KSDS |

---

## Key JCL Concepts Used

- **VERIFY** - IDCAMS command that checks VSAM cluster structural integrity; validates EOF pointers, index consistency, and CI/CA structure; must be run after crashes or abends before accessing the cluster
- **REPRO EXPORT (unload)** - Copies VSAM KSDS records to a sequential file; creates a portable backup that can be used to restore or migrate the cluster; output file can be stored on tape or disk for disaster recovery
- **REPRO INSERT (reload)** - Adds new records to an existing KSDS cluster; records must be in ascending key order; VSAM automatically updates the index and splits CIs/CAs as needed
- **ALTER FREESPACE** - Modifies the FREESPACE parameter of a VSAM cluster's DATA component; increased freespace reduces the frequency of CI/CA splits during inserts, improving performance
- **OUTREC BUILD** - SORT statement that reformats output records; `BUILD=(1,36)` extracts the first 36 bytes of each input record, effectively trimming 80-byte JCL cards to the required LRECL
- **Temporary datasets (&&name)** - Datasets prefixed with `&&` are temporary and exist only during job execution; automatically deleted when the job completes; used here to pass formatted records between SORT and REPRO

---

## Notes

- VERIFY should always be run after a system crash or job abend that was accessing a VSAM cluster. Skipping VERIFY can result in data corruption or incorrect EOF pointers.
- REPRO EXPORT creates a sequential backup of the KSDS. This backup can later be used to restore the cluster by reversing the INFILE/OUTFILE DDs.
- ALTER FREESPACE changes the freespace parameter, but it only affects future inserts. Existing CIs/CAs are not reorganized. To reclaim actual disk space or redistribute freespace, the cluster must be reorganized (EXPORT -> DELETE -> DEFINE -> IMPORT).
- STEP035 uses `OUTREC BUILD=(1,36)` to trim 80-byte inline JCL cards to 36-byte records. This is necessary because VSAM KSDS expects fixed-length 36-byte records.
- The 3 new employee records (008, 009, 010) are in ascending key order, so REPRO INSERT succeeds. If the records were out of order, REPRO would fail with a sequence error.
- After STEP040, the KSDS cluster contains 10 employees total. The backup file created in STEP020 still contains only the original 7 records.
