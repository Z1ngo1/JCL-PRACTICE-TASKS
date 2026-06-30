//TASK4    JOB (888),'SORT CUST FILE',CLASS=A,MSGCLASS=A,               
//             MSGLEVEL=(1,1),NOTIFY=&SYSUID                            
//**********************************************************************
//* TASK4: SORT DATA FROM TASK3 IN ASCENDING ORDER BY LAST NAME        *
//* STEP005 - DELETE ALREADY EXISTING DATASETS (IF EXIST)              *
//* STEP010 - SORT TASK3 OUTPUT BY LAST NAME(COL 1-10) ASC             *
//**********************************************************************
//**********************************************************************
//* DELETE ALREADY EXISTING DATASETS IF THEY EXIST                     *
//* NOTE: SPACE PARAMETER USED IF DATASET DOES NOT EXIST               *
//**********************************************************************
//STEP005  EXEC PGM=IEFBR14                                             
//DELDD1   DD DSN=Z73460.TASK4.SORT.JCL,                                
//            SPACE=(TRK,(1,0),RLSE),                                   
//            DISP=(MOD,DELETE,DELETE)                                  
//**********************************************************************
//* BYPASSED THIS STEP IF STEP005 RC > 4                               *
//* SORT DATA FROM TASK3 IN ASCENDING ORDER BY LAST NAME               *
//**********************************************************************
//STEP010  EXEC PGM=SORT,COND=(04,LT,STEP005)                                                
//SYSPRINT DD SYSOUT=*                                                  
//SYSOUT   DD SYSOUT=*                                                  
//SORTIN   DD DSN=Z73460.TASK3.OUTPUT.JCL,DISP=SHR                      
//SORTOUT  DD DSN=Z73460.TASK4.SORT.JCL,                                
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(1,1),RLSE),                                   
//            DCB=(RECFM=FB,DSORG=PS,LRECL=30)                          
//SYSIN    DD *                                                         
  SORT FIELDS=(1,10,CH,A)                                               
/*                                                                      
//
