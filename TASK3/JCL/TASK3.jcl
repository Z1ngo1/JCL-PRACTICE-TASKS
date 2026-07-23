//TASK3    JOB (888),'COPY FROM PS TO PS',CLASS=A,MSGCLASS=A,           
//             MSGLEVEL=(1,1),NOTIFY=&SYSUID                            
//**********************************************************************
//* TASK3: COPY EMPLOYEES FILE TO NEW DATASET WITH EXACT LENGTH        *
//* STEP010 - DELETE ALREADY EXISTING DATASETS (IF EXIST)              *
//* STEP020 - LOAD INLINE DATA, TRIM TO LRECL=30 VIA GENERATE/RECORD   *
//*           RECORD FORMAT: NAME(10)+FIRSTNAME(10)+ROLE(10) = 30 BYTES*
//* STEP030 - COPY INPUT DATASET TO OUTPUT, DCB INHERITED FROM SYSUT1  *
//**********************************************************************
//**********************************************************************
//* DELETE ALREADY EXISTING DATASETS IF THEY EXIST                     *
//* NOTE: SPACE PARAMETER USED IF DATASET DOES NOT EXIST               *
//**********************************************************************
//STEP010  EXEC PGM=IEFBR14                                             
//DELDD1   DD DSN=Z73460.TASK3.JCL.INPUT,                               
//            SPACE=(TRK,(1,0),RLSE),                                   
//            DISP=(MOD,DELETE,DELETE)                                  
//DELDD2   DD DSN=Z73460.TASK3.JCL.OUTPUT,                              
//            SPACE=(TRK,(1,0),RLSE),                                   
//            DISP=(MOD,DELETE,DELETE)                                  
//**********************************************************************
//* BYPASSED THIS STEP IF STEP010 RC > 4                               *
//* USE SYSIN PARAMETER WITH GENERATE MAXFLDS AND RECORD FIELD TO COPY *
//* EXACT LENGTH OF RECORD.                                            *
//* LOAD INLINE DATA TO DATASET.                                       *
//**********************************************************************
//STEP020  EXEC PGM=IEBGENER,COND=(04,LT,STEP010)                       
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
/*                                                                      
//SYSUT2   DD DSN=Z73460.TASK3.JCL.INPUT,                               
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(2,2),RLSE),                                   
//            DCB=(RECFM=FB,DSORG=PS,LRECL=30)                          
//**********************************************************************
//* BYPASSED THIS STEP IF STEP020 RC > 4                               *
//* COPY DATA FROM INPUT DATASET TO OUTPUT DATASET.                    *
//* DCB PARAMETERS OF OUTPUT FILE WILL BE THE SAME AS INPUT DCB        *
//**********************************************************************
//STEP030  EXEC PGM=IEBGENER,COND=(04,LT,STEP020)                       
//SYSPRINT DD SYSOUT=*                                                  
//SYSUT1   DD DSN=Z73460.TASK3.JCL.INPUT,DISP=SHR                       
//SYSUT2   DD DSN=Z73460.TASK3.JCL.OUTPUT,                              
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(1,1),RLSE),                                   
//            DCB=*.STEP030.SYSUT1                                      
//SYSIN    DD DUMMY                                                     
//
