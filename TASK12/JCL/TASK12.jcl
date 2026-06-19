//TASK12   JOB (888),'MULTI STEP JOB',CLASS=A,MSGCLASS=A,               
//             MSGLEVEL=(1,1),NOTIFY=&SYSUID                            
//         SET INFILE='Z73460.TASK12.INPUT.JCL'                         
//         SET TMPFILE='Z73460.TASK12.TEMP.JCL'                         
//         SET RPTFILE='Z73460.TASK12.REPORT.JCL'                       
//**********************************************************************
//* TASK12: MULTI-STEP JOB WITH SET, PARM AND SYMBOLIC VARIABLES       *
//* STEP010 - DELETE ALREADY EXISTING DATASETS (IF EXIST)              *
//* STEP020 - LOAD INPUT DATA INTO &INFILE DATASET                     *
//* STEP030 - FILTER SALARY > 004000, SORT DESC, SAVE TO &TMPFILE      *
//* STEP040 - RUNS IEFBR14 WITH PARM STRING AND CREATES EMPTY &RPTFILE *
//* STEP050 - REFORMAT &TMPFILE RECORDS WITH REPORT HEADER TO SYSOUT   *
//**********************************************************************
//**********************************************************************
//* DELETE ALREADY EXISTING DATASETS IF THEY EXIST                     *
//* NOTE: SPACE PARAMETER USED IF DATASET DOES NOT EXIST               *
//**********************************************************************
//STEP010  EXEC PGM=IEFBR14                                             
//DELDD1   DD DSN=&INFILE,                                              
//            DISP=(MOD,DELETE,DELETE),                                 
//            SPACE=(TRK,(1,0))                                         
//DELDD2   DD DSN=&RPTFILE,                                             
//            DISP=(MOD,DELETE,DELETE),                                 
//            SPACE=(TRK,(1,0))                                         
//DELDD3   DD DSN=&TMPFILE,                                             
//            DISP=(MOD,DELETE,DELETE),                                 
//            SPACE=(TRK,(1,0))                                         
//**********************************************************************
//* LOAD INPUT DATA INTO &INFILE DATASET USING IEBGENER                *
//**********************************************************************
//STEP020  EXEC PGM=IEBGENER                                            
//SYSPRINT DD SYSOUT=*                                                  
//SYSIN    DD DUMMY                                                     
//SYSUT1   DD *                                                         
IVANOV    IVAN      DEVELOPER 005000                                    
PETROV    PETR      ANALYST   003200                                    
SIDOROV   SERGEY    MANAGER   007800                                    
KOZLOV    ALEXEY    DEVELOPER 004500                                    
MOROZOV   DMITRY    ANALYST   002900                                    
NOVIKOV   OLEG      DEVELOPER 006100                                    
POPOV     ANDREY    MANAGER   008200                                    
SOKOLOV   DENIS     DEVELOPER 005500                                    
LEBEDEV   ROMAN     MANAGER   006800                                    
ORLOV     NIKITA    ANALYST   003100                                    
/*                                                                      
//SYSUT2   DD DSN=&INFILE,                                              
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(1,1),RLSE),                                   
//            DCB=(RECFM=FB,DSORG=PS,LRECL=80)                          
//**********************************************************************
//* BYPASSES THIS STEP IF STEP020 FAILS WITH RETURN CODE > 4           *
//* FILTER RECORDS WITH SALARY > 004000 AND SORT BY SALARY DESC        *
//* NOTE: SALARY IS CHARACTER FIELD - CH COMPARE WORKS FOR SAME LENGTH *
//**********************************************************************
//STEP030  EXEC PGM=SORT,COND=(04,LT,STEP020)                           
//SYSPRINT DD SYSOUT=*                                                  
//SYSOUT   DD SYSOUT=*                                                  
//SORTIN   DD DSN=&INFILE,DISP=SHR                                      
//SORTOUT  DD DSN=&TMPFILE,                                             
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(1,1),RLSE),                                   
//            DCB=(RECFM=FB,DSORG=PS,LRECL=80)                          
//SYSIN    DD *                                                         
  SORT FIELDS=(31,6,CH,D)                                               
  INCLUDE COND=(31,6,CH,GT,C'004000')                                   
/*                                                                      
//**********************************************************************
//* BYPASSES THIS STEP IF STEP030 FAILS WITH RETURN CODE > 4           *
//* PRACTICE PARM PASSING - IEFBR14 IGNORES PARM BUT IT IS VALID JCL   *
//* CREATES EMPTY &RPTFILE DATASET AS PLACEHOLDER FOR REPORT OUTPUT    *
//**********************************************************************
//STEP040  EXEC PGM=IEFBR14,COND=(04,LT,STEP030),PARM='REPORT,20260525' 
//RPTDD    DD DSN=&RPTFILE,                                             
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(1,1),RLSE),                                   
//            DCB=(RECFM=FB,DSORG=PS,LRECL=80)                          
//**********************************************************************
//* EXECUTES ONLY IF BOTH STEP030 AND STEP040 COMPLETED WITH RC = 0    *
//* REFORMAT RECORDS FROM &TMPFILE AND PRINT TO SYSOUT                 *
//* OUTREC: LITERAL 'REPORT DATE: 20260525 '(22) + NAME(10) + SAL(6)   *
//**********************************************************************
//STEP050  EXEC PGM=SORT,COND=((00,NE,STEP030),(00,NE,STEP040))         
//SYSPRINT DD SYSOUT=*                                                  
//SYSOUT   DD SYSOUT=*                                                  
//SORTIN   DD DSN=&TMPFILE,DISP=SHR                                     
//SORTOUT  DD SYSOUT=*                                                  
//SYSIN    DD *                                                         
  SORT FIELDS=COPY                                                      
  OUTREC BUILD=(C'REPORT DATE: 20260525 ',1,10,31,6)                    
/*                                                                      
