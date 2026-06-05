//SORT1    JOB (125),'SORT TASK 1',CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1),   
//             NOTIFY=&SYSUID                                           
//**********************************************************************
//*          TASK1: SORT RECORDS BY DATE OF BIRTHDAY                   *
//**********************************************************************
//**********************************************************************
//* DELETE ALREADY EXISTING DATASETS                                   *
//* NOTE: SPACE PARAMETR USED IF DATASET NOT EXITS                     *
//**********************************************************************
//STEP005  EXEC PGM=IEFBR14                                             
//DELDD1   DD DSN=Z73460.TASK1.JCL,                                     
//            DISP=(MOD,DELETE,DELETE),                 
//            SPACE=(TRK,(1,0))                                         
//DELDD2   DD DSN=Z73460.TASK1.JCL.SORT,                                
//            DISP=(MOD,DELETE,DELETE),        
//            SPACE=(TRK,(1,0))                                         
//**********************************************************************
//* LOAD INPUT DATA INTO DATASET                                       *
//**********************************************************************
//STEP010  EXEC PGM=IEBGENER,COND=(04,LT,STEP005)                       
//SYSPRINT DD SYSOUT=*                                                  
//SYSOUT   DD SYSOUT=*                                                  
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
//* SORT RECORDS ON DATE OF BIRTHDAY                                   *
//**********************************************************************
//STEP020  EXEC PGM=SORT,COND=(04,LT)                                   
//SYSPRINT DD SYSOUT=*                                                  
//SYSOUT   DD SYSOUT=*                                                  
//SORTIN   DD DSN=Z73460.TASK1.JCL,DISP=SHR  INPUT DATA SET FROM STEP010
//SORTOUT  DD DSN=Z73460.TASK1.JCL.SORT,     OUTPUT DATA SET WITH SORT  
//         DISP=(NEW,CATLG,DELETE),                                     
//         SPACE=(TRK,(2,2),RLSE),                                      
//         DCB=*.SORTIN                                                 
//* SORT ON DATE OF BIRTHDAY(YEAR,MONTH AND DAY)                        
//SYSIN    DD *                                                         
 SORT FIELDS=(15,4,CH,A,13,2,CH,A,11,2,CH,A)                            
/*                                                                      
//                                                                      
