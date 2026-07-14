# JCL-PRACTICE-TASKS

A collection of hands-on JCL (Job Control Language) practice tasks covering SORT utilities, IEBGENER, IEBCOPY, IEBUPDTE, IDCAMS, VSAM, GDG, instream PROCs, JOINKEYS, ICETOOL, and advanced multi-step job design on IBM Z mainframe.

> ⚠️ **Disclaimer:** All programs in this repository are **personal learning exercises** - written,
> designed, and tested entirely by me while studying IBM mainframe development. They may be
> **incomplete**, may not cover all edge cases or error conditions, and are not intended for
> production use. Some tasks may share **similar structure, logic, or concepts. Think of this repository as a solid
> **reference point for beginners** who are just getting started with JCL and
> related mainframe technologies.

---

## About This Repository

This repository is a structured collection of hands-on JCL practice tasks designed to build practical skills in IBM z/OS job control and utility usage. It focuses on real-world scenarios such as dataset manipulation, sorting, filtering, VSAM management, GDG handling, and multi-step job design. Each task is intentionally organized to reinforce both fundamental and advanced concepts through repetition and incremental complexity. The goal is to provide a clear, practical learning path for anyone preparing to work with mainframe technologies.

## Repository Structure

```
JCL-PRACTICE-TASKS/
  TASK01/
    README.md
    JCL/
    DATA/
  TASK02/
    README.md
    JCL/
    DATA/
  ...
  TASK24/
    README.md
    JCL/
    DATA/
```

Each task folder contains:
- `README.md` - full description: Overview, Job Details, Steps, COND Logic, Input Data Layout, Output, Key JCL Concepts Used, Notes
- `JCL/` - JCL source files
- `DATA/` - input/output dataset files

---

## Task Overview

| Task | Title | Key Utilities / Concepts |
|------|-------|---------------------------|
| [TASK01](./TASK1/README.md) | Sort Employees by Date of Birth (SORT) | SORT multi-key, IEBGENER, IEFBR14, Safe Delete Pattern, DCB Referback |
| [TASK02](./TASK2/README.md) | Include and Omit Records by State and Type (SORT) | SORT INCLUDE COND, AND condition, IEBGENER, IEFBR14 |
| [TASK03](./TASK3/README.md) | Copy PS to PS with Exact Record Length (IEBGENER) | GENERATE/RECORD FIELD, PS-to-PS copy, DCB Referback, COND Parameter |
| [TASK04](./TASK4/README.md) | Sort TASK3 Output by Last Name (SORT) | Cross-task dataset reuse, SORT FIELDS on NAME, DCB specification |
| [TASK05](./TASK5/README.md) | Filter Employees by Role: DEVELOPER Only (SORT) | SORT FIELDS=COPY, INCLUDE on ROLE field, GENERATE/RECORD FIELD |
| [TASK06](./TASK6/README.md) | Reformat Employee Records with OUTREC (SORT) | OUTREC FIELDS, C'|' literal, LRECL change via OUTREC, OPTION COPY |
| [TASK07](./TASK7/README.md) | OUTREC BUILD with Literal Prefix and Salary Field | OUTREC BUILD, literals in OUTREC, byte range selection, LRECL reduction |
| [TASK08](./TASK8/README.md) | Swap and Reorder Fields with OUTREC BUILD (SORT) | OUTREC BUILD field reordering, cross-task reuse, pipe delimiters |
| [TASK09](./TASK9/README.md) | Filter by Role and Reformat with INCLUDE + OUTREC BUILD | INCLUDE + OUTREC combined, C'RUB' literal suffix, SORT FIELDS=COPY |
| [TASK10](./TASK10/README.md) | Multi-Step Job: Filter, Sort, Reformat and Print (SORT + IEBGENER) | &&TEMP temporary dataset, COND=EVEN, descending SORT, OUTREC padding |
| [TASK11](./TASK11/README.md) | Multi-Step Job: OUTFIL Split, ICETOOL Count and SORT Merge | SORT OUTFIL, ICETOOL COUNT, SORT MERGE, COND=EVEN |
| [TASK12](./TASK12/README.md) | Multi-Step Job: SET Symbolic Variables, PARM and SORT OUTREC Report Header | SET symbolic variables, PARM parameter, OUTREC BUILD with literal, multi-condition COND |
| [TASK13](./TASK13/README.md) | Instream PROC with Symbolic Parameters, SORT and DD Concatenation | Instream PROC, PROC symbolic parameters, SYMBOLS=JCLONLY, EXPORT SYMLIST, DD Concatenation |
| [TASK14](./TASK14/README.md) | Instream PROC with Two Steps: SORT Filter + ICETOOL Count and PARM JP Variables | SORT PARM JP variables, two-step instream PROC, INCLUDE COND with AND, DD concatenation |
| [TASK15](./TASK15/README.md) | Inner Join Two Files Using SORT JOINKEYS | SORT JOINKEYS, REFORMAT FIELDS, inner join, SORTJNF1/SORTJNF2 DD names |
| [TASK16](./TASK16/README.md) | Left Outer Join Two Files Using SORT JOINKEYS (UNPAIRED F1) | JOINKEYS UNPAIRED F1, REFORMAT FIELDS with FILL, left outer join |
| [TASK17](./TASK17/README.md) | Inline PROC with JOINKEYS, Symbolic Parameters, and Multi-Step Filtering | Inline PROC, JOINKEYS outer join, ICETOOL COUNT, symbolic parameters, DD concatenation |
| [TASK18](./TASK18/README.md) | IDCAMS Dataset Management (DELETE, ALLOCATE, REPRO) | IDCAMS DELETE NONVSAM, SCRATCH PURGE, IF LASTCC/MAXCC, IEFBR14, IDCAMS REPRO |
| [TASK19](./TASK19/README.md) | VSAM KSDS: DEFINE CLUSTER + REPRO + LISTCAT | VSAM KSDS, DEFINE CLUSTER, KEYS, FREESPACE, REPRO, LISTCAT ALL |
| [TASK20](./TASK20/README.md) | VSAM KSDS: VERIFY + REPRO EXPORT + ALTER FREESPACE + REPRO INSERT | VERIFY, REPRO EXPORT/INSERT, ALTER FREESPACE, OUTREC BUILD, &&TEMP datasets |
| [TASK21](./TASK21/README.md) | IEBCOPY: PDS Management and Selective Copy | IEBCOPY selective copy, PDS directory blocks, IEFBR14 allocation, MAXCC management |
| [TASK22](./TASK22/README.md) | IEBUPDTE: PDS Member Maintenance and Update | IEBUPDTE PARM=NEW/MOD, ./ ADD/CHANGE/DELETE, sequence numbers, in-place update |
| [TASK23](./TASK23/README.md) | GDG (Generation Data Group): Create Base and Manage Generations | GDG DEFINE, LIMIT, SCRATCH/NOEMPTY, relative generation numbers, GENERATE MAXFLDS |
| [TASK24](./TASK24/README.md) | Multi-Step Job: PROC, GDG, SORT JOIN, ICETOOL | Inline PROC, GDG management, SORT JOINKEYS, ICETOOL STATS, IF/ENDIF, COND |

---

## Getting Started

### Prerequisites
- Access to an IBM Z mainframe system (IBM Z XPLORE or any other)

### Running a Task

1. Navigate to the desired task folder (e.g., `TASK01/JCL/`)
2. Upload the JCL file to your mainframe using your preferred transfer method
3. Submit the job via TSO/ISPF 
4. Review the job output in SDSF or equivalent (check `JESMSGLG`, `JESJCL`, `JESYSMSG`, and step sysouts)
5. Compare the output dataset contents with the expected results described in the task `README.md`

---

## Key JCL Concepts Covered

- **SORT / DFSORT**: `SORT FIELDS`, `SORT FIELDS=COPY`, `INCLUDE`, `OMIT`, `OUTREC FIELDS`, `OUTREC BUILD`, `OUTFIL`, `MERGE`, `JOINKEYS`, `REFORMAT`
- **ICETOOL**: `COUNT`, `STATS` (MIN/MAX/AVG/COUNT/TOTAL)
- **IEBGENER**: sequential file copy, inline data loading, `GENERATE`/`RECORD FIELD` control statements
- **IEBCOPY**: PDS selective copy, compression, directory block management
- **IEBUPDTE**: PDS member add/change/delete, sequence number control, in-place update
- **IDCAMS**: `DELETE`, `DEFINE CLUSTER`, `REPRO`, `LISTCAT`, `ALTER`, `VERIFY`, `DEFINE GDG`
- **VSAM**: KSDS (Key-Sequenced Data Set), FREESPACE, DATA/INDEX components
- **GDG**: Generation Data Groups, relative generation numbers, LIMIT/SCRATCH/NOEMPTY
- **JCL Techniques**: COND parameter, COND=EVEN, IF/ENDIF, SET symbolic variables, PARM, instream PROCs, DD concatenation, temporary datasets (`&&name`), IEFBR14 safe delete, DCB referback, EXPORT SYMLIST

---

## Author

Self-taught mainframe developer. All programs were written from scratch as practice exercises on IBM z/OS with JCL for z/OS.
