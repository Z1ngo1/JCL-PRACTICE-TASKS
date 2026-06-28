//SORT1    JOB (125),'SORT TASK 1',CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1),   
//             NOTIFY=&SYSUID                                           
//**********************************************************************
//* TASK1: SORT EMPLOYEES BY DATE OF BIRTHDAY (YEAR, MONTH, DAY)       *
//* STEP005 - DELETE ALREADY EXISTING DATASETS (IF EXIST)              *
//* STEP010 - LOAD INLINE EMPLOYEE DATA INTO INPUT DATASET             *
//*           RECORD FORMAT: NAME(10) + DDMMYYYY(8) = LRECL=80         *
//* STEP020 - SORT BY YEAR(15,4) THEN MONTH(13,2) THEN DAY(11,2) ASC   *
//**********************************************************************
//**********************************************************************
//* DELETE ALREADY EXISTING DATASETS IF THEY EXIST                     *
//* NOTE: SPACE PARAMETER USED IF DATASET DOES NOT EXIST               *
//**********************************************************************
//STEP005  EXEC PGM=IEFBR14                                             
//DELDD1   DD DSN=Z73460.TASK1.JCL,                                     
//            DISP=(MOD,DELETE,DELETE),  
//            SPACE=(TRK,(1,0)) 
//DELDD2   DD DSN=Z73460.TASK1.JCL.SORT,                                
//            DISP=(MOD,DELETE,DELETE),
//            SPACE=(TRK,(1,0)) 
//**********************************************************************
//* BYPASSED THIS STEP IF STEP005 RC > 4                               *
//* LOAD INPUT DATA INTO DATASET                                       *
//**********************************************************************
//STEP010  EXEC PGM=IEBGENER,COND=(04,LT,STEP005)                       
//SYSPRINT DD SYSOUT=*                                                                                                   
//SYSUT1   DD *                                                         
DMITRIEV  06122007                                                      
SHERSHUN  30012008                                                      
DEMENTIEV 25042007                                                      
BOGDANOV  03072008                                                      
/*                                                                      
//SYSUT2   DD DSN=Z73460.TASK1.JCL,                                     
//         DISP=(NEW,CATLG,DELETE),                                     
//         SPACE=(TRK,(2,2),RLSE),                                      
//         DCB=(RECFM=FB,LRECL=80,DSORG=PS)                             
//SYSIN    DD DUMMY                                                     
//**********************************************************************
//* BYPASSED THIS STEP IF ANY PREVIOUS STEP RC > 4                     *
//* SORT EMPLOYEES BY DATE OF BIRTHDAY ASCENDING                       *
//**********************************************************************
//STEP020  EXEC PGM=SORT,COND=(04,LT)                                   
//SYSPRINT DD SYSOUT=*                                                  
//SYSOUT   DD SYSOUT=*                                                  
//SORTIN   DD DSN=Z73460.TASK1.JCL,DISP=SHR                             
//SORTOUT  DD DSN=Z73460.TASK1.JCL.SORT,                                
//         DISP=(NEW,CATLG,DELETE),                                     
//         SPACE=(TRK,(2,2),RLSE),                                      
//         DCB=*.SORTIN                                                 
//* SORT ON DATE OF BIRTHDAY(YEAR,MONTH AND DAY)                        
//SYSIN    DD *                                                         
 SORT FIELDS=(15,4,CH,A,13,2,CH,A,11,2,CH,A)                            
/*                                                                      
//
