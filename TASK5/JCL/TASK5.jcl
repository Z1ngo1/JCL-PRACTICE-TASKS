//TASK5    JOB (888),'COPY ONLY DEV',CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1), 
//             NOTIFY=&SYSUID                                           
//**********************************************************************
//* TASK5: FILTER EMPLOYEES BY POSITION                                *
//* LOAD EMPLOYEE RECORDS INTO INPUT DATASET, THEN USE SORT INCLUDE    *
//* TO COPY ONLY DEVELOPER RECORDS TO OUTPUT DATASET                   *
//**********************************************************************
//**********************************************************************
//* DELETE ALREADY EXISTING DATASETS IF THEY EXIST                     *
//* NOTE: SPACE PARAMETER USED IF DATASET DOES NOT EXIST               *
//**********************************************************************
//STEP005  EXEC PGM=IEFBR14                                             
//DELDD1   DD DSN=Z73460.TASK5.INPUT.JCL,                               
//            SPACE=(TRK,(1,0)),                                        
//            DISP=(MOD,DELETE,DELETE)                                  
//DELDD2   DD DSN=Z73460.TASK5.SORT.JCL,                                
//            SPACE=(TRK,(1,0)),                                        
//            DISP=(MOD,DELETE,DELETE)                                  
//**********************************************************************
//* INSERT DATA INTO DATASET BY USING GENERATE MAXFLDS PARAMETER       *
//* ROWS ARE FORMATTED TO AN EXACT RECORD LENGTH OF 30 BYTES           *
//**********************************************************************
//STEP010  EXEC PGM=IEBGENER                                            
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
//SYSUT2   DD DSN=Z73460.TASK5.INPUT.JCL,                               
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(1,1),RLSE),                                   
//            DCB=(RECFM=FB,DSORG=PS,LRECL=30)                          
//**********************************************************************
//* BYPASSES THIS STEP IF STEP010 FAILS WITH RETURN CODE > 4           *
//* FILTER INPUT FILE AND COPY MATCHING RECORDS TO OUTPUT FILE         *
//* INCLUDE CONDITION EXTRACTS ONLY EMPLOYEES WITH THE DEVELOPER ROLE  *
//**********************************************************************
//STEP015  EXEC PGM=SORT,COND=(04,LT,STEP010)                           
//SYSPRINT DD SYSOUT=*                                                  
//SYSOUT   DD SYSOUT=*                                                  
//SORTIN   DD DSN=Z73460.TASK5.INPUT.JCL,DISP=SHR                       
//SORTOUT  DD DSN=Z73460.TASK5.SORT.JCL,                                
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(1,1),RLSE),                                   
//            DCB=(RECFM=FB,DSORG=PS,LRECL=30)                          
//SYSIN    DD *                                                         
  SORT FIELDS=COPY                                                      
  INCLUDE COND=(21,9,CH,EQ,C'DEVELOPER')                                
/*                                                                      
//
