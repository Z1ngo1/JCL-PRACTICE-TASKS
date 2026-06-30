//TASK6    JOB (888),'COPY TO NEW FORMAT',CLASS=A,MSGCLASS=A,           
//             MSGLEVEL=(1,1),NOTIFY=&SYSUID                            
//**********************************************************************
//* TASK6: REFORMAT EMPLOYEE RECORDS TO NEW OUTPUT LAYOUT              *
//* LOAD EMPLOYEE DATA INTO INPUT DATASET, THEN USE SORT OUTREC        *
//* TO BUILD NEW FORMAT: LASTNAME(10) + '|' + POSITION(10) = 21 BYTES  *
//**********************************************************************
//**********************************************************************
//* DELETE ALREADY EXISTING DATASETS IF THEY EXIST                     *
//* NOTE: SPACE PARAMETER USED IF DATASET DOES NOT EXIST               *
//**********************************************************************
//STEP010  EXEC PGM=IEFBR14                                             
//DELDD1   DD DSN=Z73460.TASK6.INPUT.JCL,                               
//            SPACE=(TRK,(1,0)),                                        
//            DISP=(MOD,DELETE,DELETE)                                  
//DELDD2   DD DSN=Z73460.TASK6.NEWFORM.JCL,                             
//            SPACE=(TRK,(1,0)),                                        
//            DISP=(MOD,DELETE,DELETE)                                  
//**********************************************************************
//* INSERT DATA INTO DATASET BY USING GENERATE MAXFLDS PARAMETER       *
//* ROWS ARE FORMATTED TO AN EXACT RECORD LENGTH OF 30 BYTES           *
//**********************************************************************
//STEP020  EXEC PGM=IEBGENER                                            
//SYSPRINT DD SYSOUT=*                                                  
//SYSIN    DD *                                                         
  GENERATE MAXFLDS=1                                                    
  RECORD FIELD=(30,1,,1)                                                
/*                                                                      
//SYSUT1   DD *                                                         
IVANOV    IVAN      DEVELOPER                                           
PETROV    PETR      ANALYST                                             
SIDOROV   SERGEY    MANAGER                                             
KOZLOV    ALEXEY    DEVELOPER                                           
MOROZOV   DMITRY    ANALYST                                             
NOVIKOV   OLEG      DEVELOPER                                           
POPOV     ANDREY    MANAGER                                             
/*                                                                      
//SYSUT2   DD DSN=Z73460.TASK6.INPUT.JCL,                               
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(1,1),RLSE),                                   
//            DCB=(RECFM=FB,DSORG=PS,LRECL=30)                          
//**********************************************************************
//* BYPASSES THE STEP IF STEP020 FAILS WITH RETURN CODE > 4            *
//* REFORMAT RECORDS USING OUTREC:                                     *
//* NEW LAYOUT: LASTNAME(1,10) + DELIMITER '|' + POSITION(21,10)       *
//* OUTPUT RECORD LENGTH = 10 + 1 + 10 = 21 BYTES                      *
//**********************************************************************
//STEP030  EXEC PGM=SORT,COND=(04,LT,STEP020)                           
//SYSPRINT DD SYSOUT=*                                                  
//SYSOUT   DD SYSOUT=*                                                  
//SORTIN   DD DSN=Z73460.TASK6.INPUT.JCL,DISP=SHR                       
//SORTOUT  DD DSN=Z73460.TASK6.NEWFORM.JCL,                             
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(1,1),RLSE),                                   
//            DCB=(RECFM=FB,DSORG=PS,LRECL=21)                          
//SYSIN    DD *                                                         
  OPTION COPY                                                           
  OUTREC FIELDS=(1,10,C'|',21,10)                                       
/*                                                                      
//
