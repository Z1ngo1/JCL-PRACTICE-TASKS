//TASK3    JOB (888),'COPY FROM PS TO PS',CLASS=A,MSGCLASS=A,           
//             MSGLEVEL=(1,1),NOTIFY=&SYSUID                            
//**********************************************************************
//*   TASK3: COPY EMPLOYEES FILE TO NEW DATASET WITH EXACT LENGTH      *
//**********************************************************************
//**********************************************************************
//* DELETE ALREADY EXISTING DATASETS IF THEY EXIST                     *
//* NOTE: SPACE PARAMETER USED IF DATASET DOES NOT EXIST               *
//**********************************************************************
//STEP010  EXEC PGM=IEFBR14                                             
//DELDD1   DD DSN=Z73460.TASK3.INPUT.JCL,                               
//            SPACE=(TRK,(1,0),RLSE),                                   
//            DISP=(MOD,DELETE,DELETE)                                  
//DELDD2   DD DSN=Z73460.TASK3.OUTPUT.JCL,                              
//            SPACE=(TRK,(1,0),RLSE),                                   
//            DISP=(MOD,DELETE,DELETE)                                  
//**********************************************************************
//* STEP020 WILL BE BYPASSED IF STEP010 RC IS GREATER THAN 4.          *
//* USE SYSIN PARAMETER WITH GENERATE MAXFLDS AND RECORD FIELD TO COPY *
//* EXACT LENGTH OF RECORD.                                            *
//* LOAD INPUT DATA TO DATASET.                                        *
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
//SYSUT2   DD DSN=Z73460.TASK3.INPUT.JCL,                               
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(2,2),RLSE),                                   
//            DCB=(RECFM=FB,DSORG=PS,LRECL=30)                          
//**********************************************************************
//* STEP030 WILL BE BYPASSED IF STEP020 RC IS GREATER THAN 4.          *
//* COPY DATA FROM INPUT DATASET TO OUTPUT DATASET.                    *
//* DCB PARAMETERS OF OUTPUT FILE WILL BE THE SAME AS INPUT DCB        *
//**********************************************************************
//STEP030  EXEC PGM=IEBGENER,COND=(04,LT,STEP020)                       
//SYSPRINT DD SYSOUT=*                                                  
//SYSUT1   DD DSN=Z73460.TASK3.INPUT.JCL,DISP=SHR                       
//SYSUT2   DD DSN=Z73460.TASK3.OUTPUT.JCL,                              
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(1,1),RLSE),                                   
//            DCB=*.STEP030.SYSUT1                                      
//SYSIN    DD DUMMY                                                     
