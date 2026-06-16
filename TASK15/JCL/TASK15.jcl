//TASK15   JOB (888),'SORT JOINKEYS',CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1), 
//             NOTIFY=&SYSUID                                           
//**********************************************************************
//* TASK15: INNER JOIN TWO FILES USING SORT JOINKEYS                   *
//* STEP010 - DELETE ALREADY EXISTING DATASETS (IF EXIST)              *
//* STEP020 - CREATE EMPLOYEE FILE WITH DATA: ID(3)+NAME(17), LRECL=20 *
//* STEP030 - CREATE SALARY FILE WITH DATA: ID(3)+SALARY(6), LRECL=9   *
//* STEP040 - JOIN F1+F2 BY ID(1-3), OUTPUT ID+NAME+SALARY, LRECL=25   *
//*           NOTE: ID 004 (KOZLOV) HAS NO SALARY - WON'T APPEAR       *
//**********************************************************************
//**********************************************************************
//* DELETE ALREADY EXISTING DATASETS IF THEY EXIST                     *
//* NOTE: SPACE PARAMETER USED IF DATASET DOES NOT EXIST               *
//**********************************************************************
//STEP010  EXEC PGM=IEFBR14                                             
//DELDD1   DD DSN=Z73460.TASK15.EMPLS.JCL,                              
//            DISP=(MOD,DELETE,DELETE),                                 
//            SPACE=(TRK,(1,0))                                         
//DELDD2   DD DSN=Z73460.TASK15.SALARY.JCL,                             
//            DISP=(MOD,DELETE,DELETE),                                 
//            SPACE=(TRK,(1,0))                                         
//DELDD3   DD DSN=Z73460.TASK15.JOIN.JCL,                               
//            DISP=(MOD,DELETE,DELETE),                                 
//            SPACE=(TRK,(1,0))                                         
//**********************************************************************
//* CREATE EMPLOYEE FILE AND LOAD DATA (ID + NAME) USING IEBGENER      *
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
/*                                                                      
//SYSUT2   DD DSN=Z73460.TASK15.EMPLS.JCL,                              
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(1,1),RLSE),                                   
//            DCB=(RECFM=FB,DSORG=PS,LRECL=20)                          
//SYSIN    DD *                                                         
  GENERATE MAXFLDS=1                                                    
  RECORD FIELD=(20,1,,1)                                                
/*                                                                      
//**********************************************************************
//* CREATE SALARY FILE AND LOAD DATA (ID + AMOUNT) USING IEBGENER      *
//**********************************************************************
//STEP030  EXEC PGM=IEBGENER                                            
//SYSPRINT DD SYSOUT=*                                                  
//SYSUT1   DD *                                                         
001005000                                                               
002003200                                                               
003007800                                                               
005002900                                                               
006006100                                                               
/*                                                                      
//SYSUT2   DD DSN=Z73460.TASK15.SALARY.JCL,                             
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(1,1),RLSE),                                   
//            DCB=(RECFM=FB,DSORG=PS,LRECL=9)                           
//SYSIN    DD *                                                         
  GENERATE MAXFLDS=1                                                    
  RECORD FIELD=(9,1,,1)                                                 
/*                                                                      
//**********************************************************************
//* BYPASSES STEP IF STEP020 OR STEP030 RETURNED CODE NOT EQUAL 0      *
//* SORT JOINKEYS: INNER JOIN EMPLS AND SALARY BY ID (POSITIONS 1-3)   *
//* REFORMAT: F1:1,3=ID  F1:4,10=NAME  F2:4,6=SALARY                   *
//* SORT FIELDS=COPY: NO ADDITIONAL SORT AFTER JOIN                    *
//**********************************************************************
//STEP040  EXEC PGM=SORT,COND=((00,NE,STEP020),(00,NE,STEP030))         
//SYSPRINT DD SYSOUT=*                                                  
//SYSOUT   DD SYSOUT=*                                                  
//SORTJNF1 DD DSN=Z73460.TASK15.EMPLS.JCL,DISP=SHR                      
//SORTJNF2 DD DSN=Z73460.TASK15.SALARY.JCL,DISP=SHR                     
//SORTOUT  DD DSN=Z73460.TASK15.JOIN.JCL,                               
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(1,1),RLSE),                                   
//            DCB=(RECFM=FB,DSORG=PS,LRECL=25)                          
//SYSIN    DD *                                                         
  JOINKEYS FILE=F1,FIELDS=(1,3,A)                                       
  JOINKEYS FILE=F2,FIELDS=(1,3,A)                                       
  REFORMAT FIELDS=(F1:1,3,F1:4,10,F2:4,6)                               
  SORT FIELDS=COPY                                                      
/*                                                                      
