//TASK16   JOB (888),'LEFT JOINKEYS',CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1), 
//             NOTIFY=&SYSUID                                           
//**********************************************************************
//* TASK16: LEFT OUTER JOIN USING SORT JOINKEYS (UNPAIRED F1)          *
//* STEP010 - DELETE ALREADY EXISTING DATASETS (IF EXIST)              *
//* STEP020 - CREATE EMPLOYEE FILE: ID(3)+NAME(17), LRECL=20           *
//* STEP030 - CREATE SALARY FILE: ID(3)+SALARY(6), LRECL=9             *
//* STEP040 - EXECUTE LEFT JOIN, FILLING MISSING SALARIES WITH '000000'*
//**********************************************************************
//**********************************************************************
//* DELETE ALREADY EXISTING DATASETS IF THEY EXIST                     *
//* NOTE: SPACE PARAMETER USED IF DATASET DOES NOT EXIST               *
//**********************************************************************
//STEP010  EXEC PGM=IEFBR14                                             
//DELDD1   DD DSN=Z73460.TASK16.EMPLLIST.JCL,                           
//            DISP=(MOD,DELETE,DELETE),                                 
//            SPACE=(TRK,(1,0))                                         
//DELDD2   DD DSN=Z73460.TASK16.SALARY.JCL,                             
//            DISP=(MOD,DELETE,DELETE),                                 
//            SPACE=(TRK,(1,0))                                         
//DELDD3   DD DSN=Z73460.TASK16.RESULT.JCL,                             
//            DISP=(MOD,DELETE,DELETE),                                 
//            SPACE=(TRK,(1,0))                                         
//**********************************************************************
//* CREATE MASTER EMPLOYEE FILE AND LOAD DATA USIING IEBGENER          *
//* ROWS ARE FORMATTED TO AN EXACT RECORD LENGTH OF 20 BYTES           *
//**********************************************************************
//STEP020  EXEC PGM=IEBGENER                                            
//SYSPRINT DD SYSOUT=*                                                  
//SYSUT1   DD *                                                         
001IVANOV    IVAN                                                       
002PETROV    PETR                                                       
003SIDOROV   SERG                                                       
004KOZLOV    ALEX                                                       
005MOROZOV   DIMA                                                       
006NOVIKOV   OLEG                                                       
007SMIRNOV   PAVL                                                       
/*                                                                      
//SYSUT2   DD DSN=Z73460.TASK16.EMPLLIST.JCL,                           
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(1,1),RLSE),                                   
//            DCB=(RECFM=FB,DSORG=PS,LRECL=20)                          
//SYSIN    DD *                                                         
  GENERATE MAXFLDS=1                                                    
  RECORD FIELD=(20,1,,1)                                                
/*                                                                      
//**********************************************************************
//* CREATE SALARY DATASET AND LOAD DATA WITH UNMATCHED RECORDS         *
//* ROWS ARE FORMATTED TO AN EXACT RECORD LENGTH OF 9 BYTES            *
//**********************************************************************
//STEP030  EXEC PGM=IEBGENER                                            
//SYSPRINT DD SYSOUT=*                                                  
//SYSUT1   DD *                                                         
001005000                                                               
002003200                                                               
003007800                                                               
005002900                                                               
006006100                                                               
008004400                                                               
/*                                                                      
//SYSUT2   DD DSN=Z73460.TASK16.SALARY.JCL,                             
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(1,1),RLSE),                                   
//            DCB=(RECFM=FB,DSORG=PS,LRECL=9)                           
//SYSIN    DD *                                                         
  GENERATE MAXFLDS=1                                                    
  RECORD FIELD=(9,1,,1)                                                 
/*                                                                      
//**********************************************************************
//* BYPASSES STEP IF STEP020 OR STEP030 RETURNED CODE NOT EQUAL 0      *
//* EXECUTE LEFT OUTER JOIN (UNPAIRED,F1) WITH DEFAULT NULL FILL       *
//* MATCHES BY ID. MISSING SALARIES DEFAULT TO '000000' VIA FILL PARAM *
//**********************************************************************
//STEP040  EXEC PGM=SORT,COND=((00,NE,STEP020),(00,NE,STEP030))         
//SYSPRINT DD SYSOUT=*                                                  
//SYSOUT   DD SYSOUT=*                                                  
//SORTJNF1 DD DSN=Z73460.TASK16.EMPLLIST.JCL,DISP=SHR                   
//SORTJNF2 DD DSN=Z73460.TASK16.SALARY.JCL,DISP=SHR                     
//SORTOUT  DD DSN=Z73460.TASK16.RESULT.JCL,                             
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(1,1),RLSE),                                   
//            DCB=(RECFM=FB,DSORG=PS,LRECL=29)                          
//SYSIN    DD *                                                         
  SORT FIELDS=COPY                                                      
  JOINKEYS FILE=F1,FIELDS=(1,3,A)                                       
  JOINKEYS FILE=F2,FIELDS=(1,3,A)                                       
  JOIN UNPAIRED,F1                                                      
  REFORMAT FIELDS=(F1:1,20,F2:4,6),FILL=C'0'                            
/*                                                                      
