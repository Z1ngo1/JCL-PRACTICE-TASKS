//TASK17   JOB (888),'JOINKEYS MULTI STEP',CLASS=A,MSGCLASS=A,          
//             MSGLEVEL=(1,1),NOTIFY=&SYSUID                            
//         EXPORT SYMLIST=(ROLE)                                        
//**********************************************************************
//* TASK17: JOINKEYS + INLINE PROC + SORT + ICETOOL + COND             *
//* SALPROC  - FILTERS &&JOINED BY &ROLE, COUNTS RECORDS INTO &OUTDSN  *
//*   STEP1  - INCLUDE BY &ROLE, SORT BY SALARY DESC -> &&ROLEOUT      *
//*   STEP2  - ICETOOL COUNT &&ROLEOUT -> &OUTDSN (ONLY IF STEP1 RC=0) *
//* STEP010 - DELETE ALREADY EXISTING DATASETS (IF EXIST)              *
//* STEP020 - CREATE EMPLOYEE FILE: ID(3)+NAME(10)+ROLE(13), LRECL=26  *
//* STEP030 - CREATE SALARY FILE: ID(3)+SALARY(6), LRECL=9             *
//* STEP040 - EXECUTE LEFT JOIN GENERATING &&JOINED DATASET            *
//*           FILLING MISSING SALARIES WITH '000000'                   *
//* STEP050 - CALL SALPROC FOR DEVELOPERS -> RESULTS IN &&DEVCNT       *
//* STEP060 - CALL SALPROC FOR MANAGERS -> RESULTS IN &&MGRCNT         *
//* STEP070 - CONCATENATE COUNTS AND ADD 'TOTAL: ' PREFIX TO SYSOUT    *
//* STEP080 - ALWAYS EXECUTE (EVEN): PRINT FULL &&JOINED TO SYSOUT     *
//**********************************************************************
//SALPROC  PROC ROLE=,OUTDSN=                                           
//*--------------------------------------------------------------------*
//* FILTER &&JOINED BY &ROLE AND SORT BY SALARY DESC                   *
//*--------------------------------------------------------------------*
//STEP1    EXEC PGM=SORT                                                
//SYSPRINT DD SYSOUT=*                                                  
//SYSOUT   DD SYSOUT=*                                                  
//SORTIN   DD DSN=&&JOINED,DISP=SHR                                     
//SORTOUT  DD DSN=&&ROLEOUT,                                            
//            DISP=(NEW,PASS,DELETE),                                   
//            SPACE=(TRK,(1,1)),                                        
//            DCB=(RECFM=FB,DSORG=PS,LRECL=80)                          
//SYSIN    DD *,SYMBOLS=JCLONLY                                         
  SORT FIELDS=(24,6,CH,D)                                               
  INCLUDE COND=(14,10,CH,EQ,C'&ROLE')                                   
/*                                                                      
//*--------------------------------------------------------------------*
//* BYPASSED THIS STEP IF STEP1 RETURNED CODE NOT EQUAL 0              *
//* COUNT RECORDS IN &&ROLEOUT, WRITE RESULT TO &OUTDSN                *
//*--------------------------------------------------------------------*
//STEP2    EXEC PGM=ICETOOL,COND=(00,NE,STEP1)                          
//TOOLMSG  DD SYSOUT=*                                                  
//DFSMSG   DD SYSOUT=*                                                  
//INDD     DD DSN=&&ROLEOUT,DISP=(OLD,DELETE)                           
//OUTDD    DD DSN=&OUTDSN,                                              
//            DISP=(NEW,PASS,DELETE),                                   
//            SPACE=(TRK,(1,1),RLSE),                                   
//            DCB=(RECFM=FB,DSORG=PS,LRECL=80)                          
//TOOLIN   DD *                                                         
  COUNT FROM(INDD) WRITE(OUTDD)                                         
/*                                                                      
//         PEND                                                         
//**********************************************************************
//* DELETE ALREADY EXISTING DATASETS IF THEY EXIST                     *
//* NOTE: SPACE PARAMETER USED IF DATASET DOES NOT EXIST               *
//**********************************************************************
//STEP010  EXEC PGM=IEFBR14                                             
//DELDD1   DD DSN=Z73460.TASK17.EMPLLIST.JCL,                           
//            DISP=(MOD,DELETE,DELETE),                                 
//            SPACE=(TRK,(1,0))                                         
//DELDD2   DD DSN=Z73460.TASK17.SALARY.JCL,                             
//            DISP=(MOD,DELETE,DELETE),                                 
//            SPACE=(TRK,(1,0))                                         
//**********************************************************************
//* CREATE EMPLOYEE FILE AND LOAD DATA USIING IEBGENER                 *
//* ROWS ARE FORMATTED TO AN EXACT RECORD LENGTH OF 26 BYTES           *
//**********************************************************************
//STEP020  EXEC PGM=IEBGENER                                            
//SYSPRINT DD SYSOUT=*                                                  
//SYSUT1   DD *                                                         
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
/*                                                                      
//SYSUT2   DD DSN=Z73460.TASK17.EMPLLIST.JCL,                           
//           DISP=(NEW,CATLG,DELETE),                                   
//           SPACE=(TRK,(1,1),RLSE),                                    
//           DCB=(RECFM=FB,DSORG=PS,LRECL=26)                           
//SYSIN    DD *                                                         
  GENERATE MAXFLDS=1                                                    
  RECORD FIELD=(26,1,,1)                                                
/*                                                                      
//**********************************************************************
//* CREATE SALARY FILE AND LOAD DATA USIING IEBGENER                   *
//* ROWS ARE FORMATTED TO AN EXACT RECORD LENGTH OF 9 BYTES            *
//**********************************************************************
//STEP030  EXEC PGM=IEBGENER                                            
//SYSPRINT DD SYSOUT=*                                                  
//SYSUT1   DD *                                                         
001005000                                                               
002003200                                                               
003007800                                                               
004004500                                                               
006006100                                                               
007008200                                                               
008005500                                                               
009006800                                                               
/*                                                                      
//SYSUT2   DD DSN=Z73460.TASK17.SALARY.JCL,                             
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(1,1),RLSE),                                   
//            DCB=(RECFM=FB,DSORG=PS,LRECL=9)                           
//SYSIN    DD *                                                         
  GENERATE MAXFLDS=1                                                    
  RECORD FIELD=(9,1,,1)                                                 
/*                                                                      
//**********************************************************************
//* BYPASSES STEP IF STEP020 OR STEP030 RETURNED CODE NOT EQUAL 0      *
//* EXECUTE LEFT JOIN (UNPAIRED,F1) F1=EMPLLIST, F2=SALARY BY ID(1-3)  *
//* MISSING SALARIES DEFAULT TO '000000' VIA FILL=C'0'                 *
//**********************************************************************
//STEP040  EXEC PGM=SORT,COND=((04,LT,STEP020),(04,LT,STEP030))         
//SYSPRINT DD SYSOUT=*                                                  
//SYSOUT   DD SYSOUT=*                                                  
//SORTJNF1 DD DSN=Z73460.TASK17.EMPLLIST.JCL,DISP=SHR                   
//SORTJNF2 DD DSN=Z73460.TASK17.SALARY.JCL,DISP=SHR                     
//SORTOUT  DD DSN=&&JOINED,                                             
//            DISP=(NEW,PASS,DELETE),                                   
//            SPACE=(TRK,(1,1)),                                        
//            DCB=(RECFM=FB,DSORG=PS,LRECL=29)                          
//SYSIN    DD *                                                         
  SORT FIELDS=COPY                                                      
  JOINKEYS FILE=F1,FIELDS=(1,3,A)                                       
  JOINKEYS FILE=F2,FIELDS=(1,3,A)                                       
  JOIN UNPAIRED,F1                                                      
  REFORMAT FIELDS=(F1:1,23,F2:4,6),FILL=C'0'                            
/*                                                                      
//**********************************************************************
//* BYPASSES STEP IF STEP040 RETURNED CODE NOT EQUAL 0                 *
//* CALL SALPROC: FILTER DEVELOPERS, COUNT -> &&DEVCNT                 *
//**********************************************************************
//STEP050  EXEC SALPROC,COND=(00,NE,STEP040),                           
//            ROLE='DEVELOPER ',                                        
//            OUTDSN=&&DEVCNT                                           
//**********************************************************************
//* BYPASSES STEP IF STEP040 RETURNED CODE NOT EQUAL 0                 *
//* CALL SALPROC: FILTER MANAGERS, COUNT -> &&MGRCNT                   *
//**********************************************************************
//STEP060  EXEC SALPROC,COND=(00,NE,STEP040),                           
//            ROLE='MANAGER   ',                                        
//            OUTDSN=&&MGRCNT                                           
//**********************************************************************
//* BYPASSES STEP IF STEP050 OR STEP060 RETURNED CODE NOT EQUAL 0      *
//* CONCATENATE &&DEVCNT AND &&MGRCNT, ADD PREFIX TOTAL: TO EACH LINE  *
//* OUTPUT DIRECTLY TO SYSOUT                                          *
//**********************************************************************
//STEP070  EXEC PGM=SORT,                                               
//           COND=((00,NE,STEP050.STEP2),(00,NE,STEP060.STEP2))         
//SYSPRINT DD SYSOUT=*                                                  
//SYSOUT   DD SYSOUT=*                                                  
//SORTIN   DD DSN=&&DEVCNT,DISP=(OLD,DELETE)                            
//         DD DSN=&&MGRCNT,DISP=(OLD,DELETE)                            
//SORTOUT  DD SYSOUT=*                                                  
//SYSIN    DD *                                                         
  SORT FIELDS=COPY                                                      
  OUTREC BUILD=(C'TOTAL: ',1,15)                                        
/*                                                                      
//**********************************************************************
//* COND=EVEN: ALWAYS RUNS REGARDLESS OF PREVIOUS STEP RETURN CODES    *
//* PRINT CONTENTS OF &&JOINED TO SYSOUT FOR VERIFICATION              *
//**********************************************************************
//STEP080  EXEC PGM=IEBGENER,COND=EVEN                                  
//SYSPRINT DD SYSOUT=*                                                  
//SYSUT1   DD DSN=&&JOINED,DISP=(OLD,DELETE)                            
//SYSUT2   DD SYSOUT=*                                                  
//SYSIN    DD DUMMY                                                     
