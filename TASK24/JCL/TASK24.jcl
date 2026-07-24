//TASK24   JOB (888),'MULTI STEPS',CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1),   
//             NOTIFY=&SYSUID                                           
//**********************************************************************
//* TASK24: MULTI-STEP JOB WITH PROC, GDG, JOIN, ICETOOL AND SORT      *
//* SORTPROC - INLINE PROC: SORT ANY DATASET, SORTIN/SORTOUT AS PARAMS *
//* STEP005  - CHECK IF GDG BASE EXISTS VIA LISTCAT                    *
//* STEP007  - DEFINE GDG BASE ONLY IF STEP005 RC >= 4 (NOT FOUND)     *
//* STEP010  - DELETE EMPBASE, SALBASE, EMPSORT IF THEY EXIST          *
//* STEP020  - CREATE EMPTY EMPBASE(LRECL=40) AND SALBASE(LRECL=30)    *
//* STEP030  - LOAD EMPLOYEE DATA INTO EMPBASE, TRIM TO 40 BYTES       *
//* STEP040  - LOAD SALARY DATA INTO SALBASE, TRIM TO 30 BYTES         *
//* STEP050  - CALL SORTPROC: SORT EMPBASE BY ROLE(15,10) THEN ID(1,4) *
//* STEP060  - JOINKEYS: JOIN EMPSORT+SALBASE ON ID(1,4), WRITE GDG(+1)*
//*            REFORMAT: F1 BYTES 1-32 + F2 BYTES 1-28 = LRECL 60      *
//* STEP070  - ICETOOL STATS: SALARY FIELD(37,6,ZD) MIN/MAX/AVG/COUNT  *
//* STEP080  - PRINT FINAL GDG(+1) CONTENT TO SYSOUT VIA IEBGENER      *
//**********************************************************************
//SORTPROC PROC                                                         
//*--------------------------------------------------------------------*
//* INLINE PROC SORTPROC - REUSABLE SORT TEMPLATE                      *
//* &SORTIN  - SYMBOLIC PARAM: INPUT DATASET NAME (PASSED BY USER)     *
//* &SORTOUT - SYMBOLIC PARAM: OUTPUT DATASET NAME (PASSED BY USER)    *
//* SYSIN=DUMMY HERE - ACTUAL SORT FIELDS OVERRIDDEN BY USER           *
//*--------------------------------------------------------------------*
//STEP1    EXEC PGM=SORT                                                
//SYSPRINT DD SYSOUT=*                                                  
//SYSOUT   DD SYSOUT=*                                                  
//SORTIN   DD DSN=&SORTIN,DISP=SHR                                      
//SORTOUT  DD DSN=&SORTOUT,                                             
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(2,1)),                                        
//            DCB=(RECFM=FB,DSORG=PS,LRECL=40)                          
//SYSIN    DD DUMMY                                                     
//         PEND                                                         
//**********************************************************************
//* CHECK IF GDG BASE ALREADY EXISTS IN CATALOG                        *
//* LISTCAT RC=0 - GDG EXISTS, SKIP DEFINE                             *
//* LISTCAT RC=4 - GDG NOT FOUND, PROCEED TO STEP007                   *
//**********************************************************************
//STEP005  EXEC PGM=IDCAMS                                              
//SYSPRINT DD SYSOUT=*                                                  
//SYSIN    DD *                                                         
  LISTCAT ENTRIES(Z73460.TASK24.JCL.RESULT) GDG                     
/*                                                                      
//**********************************************************************
//* BYPASSES THIS STEP IF RETURN CODE STEP005 LOWER THAN 4             *
//* DEFINE GDG BASE - CATALOG ENTRY ONLY, NO PHYSICAL DATASET          *
//* LIMIT(5)  - KEEP MAXIMUM 5 GENERATIONS AT A TIME                   *
//* SCRATCH   - PHYSICALLY DELETE OLDEST GENERATION WHEN LIMIT HIT     *
//* NOEMPTY   - REMOVE ONLY OLDEST GENERATION, NOT ALL AT ONCE         *
//**********************************************************************
//         IF STEP005.RC>=4 THEN                                        
//STEP007  EXEC PGM=IDCAMS                                              
//SYSPRINT DD SYSOUT=*                                                  
//SYSIN    DD *                                                         
  DEFINE GDG(NAME(Z73460.TASK24.JCL.RESULT) -                       
         LIMIT(5) -                                                     
         SCRATCH -                                                      
         NOEMPTY)                                                       
/*                                                                      
//         ENDIF                                                        
//**********************************************************************
//* DELETE WORKING DATASETS IF THEY ALREADY EXIST                      *
//* NOTE: SPACE PARAMETER USED IF DATASET DOES NOT EXIST               *
//**********************************************************************
//STEP010  EXEC PGM=IEFBR14                                             
//DELDD1   DD DSN=Z73460.TASK24.JCL.EMPBASE,                        
//            DISP=(MOD,DELETE,DELETE),                                 
//            SPACE=(TRK,(1,0))                                         
//DELDD2   DD DSN=Z73460.TASK24.JCL.SALBASE,                        
//            DISP=(MOD,DELETE,DELETE),                                 
//            SPACE=(TRK,(1,0))                                         
//DELDD3   DD DSN=Z73460.TASK24.JCL.EMPSORT,                        
//            DISP=(MOD,DELETE,DELETE),                                 
//            SPACE=(TRK,(1,0))                                         
//**********************************************************************
//* CREATE TWO EMPTY SEQUENTIAL DATASETS VIA IEFBR14                   *
//**********************************************************************
//STEP020  EXEC PGM=IEFBR14                                             
//CREATE1  DD DSN=Z73460.TASK24.JCL.EMPBASE,                        
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(2,1)),                                        
//            DCB=(RECFM=FB,DSORG=PS,LRECL=40)                          
//CREATE2  DD DSN=Z73460.TASK24.JCL.SALBASE,                        
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(2,1)),                                        
//            DCB=(RECFM=FB,DSORG=PS,LRECL=30)                          
//**********************************************************************
//* BYPASSED THIS STEP IF STEP020 RC NOT EQUAL 0                       *
//* LOAD EMPLOYEE DATA INTO EMPBASE USING IEBGENER                     *
//* ROWS ARE FORMATTED TO AN EXACT RECORD LENGTH OF 40 BYTES           *
//**********************************************************************
//STEP030  EXEC PGM=IEBGENER,COND=(00,NE,STEP020)                       
//SYSPRINT DD SYSOUT=*                                                  
//SYSUT1   DD *                                                         
0001IVANOV    DEVELOPER  M  1985                                        
0002PETROV    ANALYST    M  1990                                        
0003SIDOROV   MANAGER    M  1978                                        
0004KOZLOV    DEVELOPER  M  1992                                        
0005MOROZOV   ANALYST    F  1988                                        
0006NOVIKOV   DEVELOPER  M  1995                                        
0007POPOV     MANAGER    F  1982                                        
/*                                                                      
//SYSUT2   DD DSN=Z73460.TASK24.JCL.EMPBASE,DISP=SHR                
//SYSIN    DD *                                                         
  GENERATE MAXFLDS=1                                                    
  RECORD FIELD=(40,1,,1)                                                
/*                                                                      
//**********************************************************************
//* BYPASSED THIS STEP IF STEP030 RC NOT EQUAL 0                       *
//* LOAD SALARY DATA INTO SALBASE USING IEBGENER                       *
//* ROWS ARE FORMATTED TO AN EXACT RECORD LENGTH OF 30 BYTES           *
//**********************************************************************
//STEP040  EXEC PGM=IEBGENER,COND=(00,NE,STEP030)                       
//SYSPRINT DD SYSOUT=*                                                  
//SYSUT1   DD *                                                         
0001005000DEVELOPER                                                     
0002003200ANALYST                                                       
0003007800MANAGER                                                       
0004004500DEVELOPER                                                     
0005002900ANALYST                                                       
0006006100DEVELOPER                                                     
0007008200MANAGER                                                       
/*                                                                      
//SYSUT2   DD DSN=Z73460.TASK24.JCL.SALBASE,DISP=SHR                
//SYSIN    DD *                                                         
  GENERATE MAXFLDS=1                                                    
  RECORD FIELD=(30,1,,1)                                                
/*                                                                      
//**********************************************************************
//* BYPASSED THIS STEP IF STEP040 RC NOT EQUAL 0                       *
//* CALL SORTPROC: SORT EMPBASE BY ROLE(COL 15,LEN 10) THEN ID(COL 1,4)*
//* STEP1.SYSIN OVERRIDES SYSIN=DUMMY DEFINED IN THE PROC              *
//**********************************************************************
//STEP050  EXEC SORTPROC,COND=(00,NE,STEP040),                          
//            SORTIN=Z73460.TASK24.JCL.EMPBASE,                     
//            SORTOUT=Z73460.TASK24.JCL.EMPSORT                     
//STEP1.SYSIN DD *                                                      
  SORT FIELDS=(15,10,CH,A,1,4,CH,A)                                     
/*                                                                      
//**********************************************************************
//* BYPASSED THIS STEP IF STEP050 RC NOT EQUAL 0                       *
//* JOINKEYS: INNER JOIN EMPSORT(F1) AND SALBASE(F2) ON ID(1,4)        *
//* REFORMAT: CONCATENATE F1 BYTES 1-32 AND F2 BYTES 1-28 = 60 BYTES   *
//* OUTPUT WRITTEN AS NEW GDG GENERATION (+1) OF RESULT GDG BASE       *
//* SORT FIELDS IN MAIN SORT: ROLE(15,10) THEN ID(1,4) ASC             *
//**********************************************************************
//STEP060  EXEC PGM=SORT,COND=(00,NE,STEP050.STEP1)                     
//SYSPRINT DD SYSOUT=*                                                  
//SYSOUT   DD SYSOUT=*                                                  
//SORTJNF1 DD DSN=Z73460.TASK24.JCL.EMPSORT,DISP=SHR                
//SORTJNF2 DD DSN=Z73460.TASK24.JCL.SALBASE,DISP=SHR                
//SORTOUT  DD DSN=Z73460.TASK24.JCL.RESULT(+1),                     
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(3,1)),                                        
//            DCB=(RECFM=FB,DSORG=PS,LRECL=60)                          
//SYSIN    DD *                                                         
  SORT FIELDS=(15,10,CH,A,1,4,CH,A)                                     
  JOINKEYS FILES=F1,FIELDS=(1,4,A)                                      
  JOINKEYS FILES=F2,FIELDS=(1,4,A)                                      
  REFORMAT FIELDS=(F1:1,32,F2:1,28)                                     
/*                                                                      
//**********************************************************************
//* BYPASSED THIS STEP IF STEP060 RC NOT EQUAL 0                       *
//* ICETOOL STATS: COMPUTE MIN/MAX/AVG/COUNT ON SALARY FIELD           *
//* ON(37,6,ZD) - SALARY AT OFFSET 37, LENGTH 6, ZONED DECIMAL FORMAT  *
//**********************************************************************
//STEP070  EXEC PGM=ICETOOL,COND=(00,NE,STEP060)                        
//TOOLMSG  DD SYSOUT=*                                                  
//DFSMSG   DD SYSOUT=*                                                  
//INDD     DD DSN=Z73460.TASK24.JCL.RESULT(+1),DISP=SHR             
//TOOLIN   DD *                                                         
  STATS FROM(INDD) ON(37,6,ZD)                                          
/*                                                                      
//**********************************************************************
//* BYPASSED THIS STEP IF STEP070 RC NOT EQUAL 0                       *
//* PRINT FINAL JOINED AND SORTED GDG GENERATION TO SYSOUT             *
//**********************************************************************
//STEP080  EXEC PGM=IEBGENER,COND=(00,NE,STEP070)                       
//SYSPRINT DD SYSOUT=*                                                  
//SYSUT1   DD DSN=Z73460.TASK24.JCL.RESULT(+1),DISP=SHR             
//SYSUT2   DD SYSOUT=*                                                  
//SYSIN    DD DUMMY                                                     
//
