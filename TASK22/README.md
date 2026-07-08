# Task 22 - IEBUPDTE: PDS Member Maintenance and Update

## Overview

This job demonstrates PDS member maintenance using IEBUPDTE utility: creating a PDS library, adding two new members (EMPDATA and SALDATA) with sequence number control, modifying an existing member (deleting a record and adding new records), and printing the updated member for verification. IEBUPDTE is primarily used for source code libraries and supports in-place updates with sequence numbering.

## Job Details

| Property | Value |
|----------|-------|
| Job Name | TASK22 |
| Job Class | A |
| MSGCLASS | A |
| MSGLEVEL | (1,1) |
| NOTIFY | &SYSUID |

## Steps

| Step | Program | Description |
|------|---------|-------------|
| STEP010 | IDCAMS | Delete [UPDLIB.JCL](JCL/TASK22.jcl) if it exists; SET MAXCC=0 if RC<=8 |
| STEP020 | IEFBR14 | Create empty PDS library SPACE=(TRK,(2,2,10)); skip if STEP010 RC > 8 |
| STEP030 | IEBUPDTE | PARM=NEW: add [EMPDATA](DATA/TASK22.HLQ.UPDLIB.JCL/EMPDATA.txt) (5 employees) and [SALDATA](DATA/TASK22.HLQ.UPDLIB.JCL/SALDATA.txt) (5 salary records) with sequence numbering |
| STEP040 | IEBUPDTE | PARM=MOD: update EMPDATA in-place - delete sequence 20 (PETROV), add 2 new employees (NOVIKOV, POPOV) |
| STEP050 | IEBGENER | Print updated EMPDATA member to SYSOUT for verification |

## COND Logic

| Step | COND Parameter | Meaning |
|------|----------------|----------|
| STEP020 | (08,LT,STEP010) | Skip if STEP010 RC > 8 (unexpected error during DELETE) |
| STEP030 | (00,NE,STEP020) | Skip if STEP020 RC ≠ 0 (PDS creation failed) |
| STEP040 | (00,NE,STEP030) | Skip if STEP030 RC ≠ 0 (adding members failed) |
| STEP050 | (00,NE,STEP040) | Skip if STEP040 RC ≠ 0 (update failed) |

## Member Data Layout

### EMPDATA Member (Initial) - LRECL=80, 5 records with sequence numbers

| Position | Length | Type | Description |
|----------|--------|------|-------------|
| 1-3 | 3 | CH | Employee ID |
| 4-11 | 8 | CH | Last Name |
| 12-23 | 12 | CH | Role |
| 24-29 | 6 | CH | Salary |
| 73-80 | 8 | NUM | Sequence number (00000010, 00000020, etc.) |

Initial records (STEP030):
```
001IVANOV   DEVELOPER  005000                                             00000010
002PETROV   ANALYST    003200                                             00000020
003SIDOROV  MANAGER    007800                                             00000030
004KOZLOV   DEVELOPER  004500                                             00000040
005MOROZOV  ANALYST    002900                                             00000050
```

### EMPDATA Member (After STEP040) - 6 records

After DELETE SEQ1=00000020,SEQ2=00000020 and adding 2 new records:
```
001IVANOV   DEVELOPER  005000                                             00000010
003SIDOROV  MANAGER    007800                                             00000030
004KOZLOV   DEVELOPER  004500                                             00000040
005MOROZOV  ANALYST    002900                                             00000050
006NOVIKOV  DEVELOPER  006100                                             00000060
007POPOV    MANAGER    008200                                             00000070
```

### SALDATA Member - LRECL=80, 5 records with sequence numbers

| Position | Length | Type | Description |
|----------|--------|------|-------------|
| 1-3 | 3 | CH | Employee ID |
| 4-12 | 9 | CH | Salary + Currency (RUB) |
| 73-80 | 8 | NUM | Sequence number |

Sample records:
```
001005000RUB                                                               00000010
002003200RUB                                                               00000020
003007800RUB                                                               00000030
004004500RUB                                                               00000040
005002900RUB                                                               00000050
```

## Output

| File | Description |
|------|-------------|
| [SYSOUT.STEP010.txt](OUTPUT/SYSOUT.STEP010.txt) | IDCAMS DELETE output - PDS library deleted; MAXCC reset to 0 |
| [SYSOUT.STEP030.txt](OUTPUT/SYSOUT.STEP030.txt) | IEBUPDTE ADD output - 2 members (EMPDATA, SALDATA) created with sequence numbering |
| [SYSOUT.STEP040.txt](OUTPUT/SYSOUT.STEP040.txt) | IEBUPDTE MOD output - EMPDATA updated (1 record deleted, 2 added) |
| [SYSUT2.STEP050.txt](OUTPUT/SYSUT2.STEP050.txt) | Final EMPDATA member content - 6 employees with sequence numbers |

## Key JCL Concepts Used

- **IEBUPDTE** - IBM utility for maintaining source libraries (PDS members) with sequence number support; handles ADD, CHANGE, DELETE, and REPL operations
- **IEBUPDTE PARM=NEW** - Creates new PDS members; SYSUT1=DUMMY indicates input comes only from SYSIN DD; sequence numbers assigned automatically
- **IEBUPDTE PARM=MOD** - Modifies existing PDS members; SYSUT1=SYSUT2 (same dataset) performs in-place update
- **./ ADD NAME=membername** - Control statement to add a new member to PDS; followed by member data
- **./ CHANGE NAME=membername** - Control statement to switch to existing member for editing
- **./ DELETE SEQ1=n,SEQ2=m** - Deletes records with sequence numbers from n to m (inclusive); here deletes single line 00000020
- **./ NUMBER NEW1=start,INCR=increment** - Assigns sequence numbers starting at start with increment; example: NEW1=00000010,INCR=00000010
- **./ ENDUP** - Marks end of IEBUPDTE control statements and data
- **Sequence numbers** - 8-digit numbers in columns 73-80 used for line identification and ordering; required for ./ DELETE and ./ CHANGE operations
- **In-place update** - SYSUT1 and SYSUT2 pointing to same dataset with DISP=SHR/OLD allows direct modification without creating temporary copy
- **SYSIN DD DATA** - Inline control statements and data; terminated by /* delimiter

## Notes

- STEP010 uses `IF MAXCC <= 8 THEN SET MAXCC = 0` because RC=8 (dataset not found) is acceptable and should not fail the job
- STEP020 creates PDS with SPACE=(TRK,(2,2,10)): 2 primary tracks, 2 secondary tracks, 10 directory blocks (~60 member capacity)
- STEP030 PARM=NEW with SYSUT1 DD DUMMY means input comes entirely from SYSIN; no existing members are read
- `./ NUMBER NEW1=00000010,INCR=00000010` assigns sequence numbers 10, 20, 30... to each record in columns 73-80
- STEP040 performs in-place update: SYSUT1 DD DISP=SHR (read) and SYSUT2 DD DISP=OLD (exclusive write) point to same dataset
- `./ CHANGE NAME=EMPDATA` switches context to EMPDATA member for editing
- `./ DELETE SEQ1=00000020,SEQ2=00000020` removes only the record at sequence 00000020 (PETROV, 002)
- After deletion, new records (006NOVIKOV, 007POPOV) are appended with sequence numbers 00000060 and 00000070
- STEP050 prints final EMPDATA content showing 6 employees: original 5 minus PETROV plus NOVIKOV and POPOV
- IEBUPDTE automatically renumbers and reorganizes members; sequence numbers ensure correct ordering
- IEBUPDTE is typically used for source code libraries (COBOL, Assembler, JCL) where line-level changes are common
