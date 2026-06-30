//SORT2    JOB (1337),'INCLUDE AND OMIT',CLASS=A,MSGCLASS=A,            
//             MSGLEVEL=(1,1),NOTIFY=&SYSUID                            
//**********************************************************************
//* TASK2: INCLUDE ONLY RECORDS WHERE STATE=NY AND TYPE=A              *
//* STEP1 - DELETE ALREADY EXISTING DATASETS (IF EXIST)                *
//* STEP2 - LOAD INLINE EMPLOYEE DATA INTO INPUT DATASET               *
//*         RECORD FORMAT: NAME(10)+TYPE(1)+SP+STATE(2)+SP+AMT(6)      *
//* STEP3 - SORT BY NAME ASC, INCLUDE STATE=NY AND TYPE=A ONLY         *
//**********************************************************************
//**********************************************************************
//* DELETE ALREADY EXISTING DATASETS IF THEY EXIST                     *
//* NOTE: SPACE PARAMETER USED IF DATASET DOES NOT EXIST               *
//**********************************************************************
//STEP1    EXEC PGM=IEFBR14                                             
//DELDD1   DD DSN=Z73460.TASK2.JCL,                                     
//            DISP=(MOD,DELETE,DELETE),                                 
//            SPACE=(TRK,(1,0))                                         
//DELDD2   DD DSN=Z73460.TASK2.JCL.SORT,                                
//            DISP=(MOD,DELETE,DELETE),                                 
//            SPACE=(TRK,(1,0))                                         
//**********************************************************************
//* LOAD INPUT DATA INTO DATASET                                       *
//**********************************************************************
//STEP2    EXEC PGM=IEBGENER,COND=(04,LT,STEP1)                                         
//SYSPRINT DD SYSOUT=*                                                                                                 
//SYSUT1   DD *                                                         
SMITH     A  NY  001500                                                 
JOHNSON   X  NY  002300                                                 
WILLIAMS  A  CA  000800                                                 
BROWN     A  NY  000500                                                 
JONES     X  TX  003000                                                 
GARCIA    A  NY  001200                                                 
MILLER    A  FL  000900                                                 
DAVIS     A  NY  000050                                                 
WILSON    X  NY  005000                                                 
TAYLOR    A  NY  002100                                                 
/*                                                                      
//SYSUT2   DD DSN=Z73460.TASK2.JCL,                                     
//         DISP=(NEW,CATLG,DELETE),                                     
//         SPACE=(TRK,(1,1),RLSE),                                      
//         DCB=(RECFM=FB,LRECL=80,DSORG=PS)                             
//SYSIN    DD DUMMY                                                     
//**********************************************************************
//* BYPASSED IF ANY PREVIOUS STEP RC > 4                               *
//* SORT RECORDS INCLUDE 'NY' AND OMIT 'X' PARAMETERS                  *
//**********************************************************************
//STEP3    EXEC PGM=SORT,COND=(04,LT)                                   
//SYSPRINT DD SYSOUT=*                                                  
//SYSOUT   DD SYSOUT=*                                                  
//SORTIN   DD DSN=Z73460.TASK2.JCL,DISP=SHR     INPUT DATA SET          
//SORTOUT  DD DSN=Z73460.TASK2.JCL.SORT,        OUTPUT DATA SET         
//         DISP=(NEW,CATLG,DELETE),                                     
//         SPACE=(TRK,(1,1),RLSE),                                      
//         DCB=*.SORTIN                                                 
//SYSIN    DD *                                                         
  SORT FIELDS=(1,10,CH,A)                                               
  INCLUDE COND=(14,2,CH,EQ,C'NY',AND,11,1,CH,EQ,C'A')                   
/*                                                                      
//
