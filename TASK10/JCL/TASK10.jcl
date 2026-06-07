//TASK10   JOB (888),'MULTI STEP',CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1),    
//             NOTIFY=&SYSUID                                           
//**********************************************************************
//* TASK10: MULTI-STEP JOB WITH DATA FILTERING AND REFORMATTING        *
//* STEP020 - LOAD INPUT DATA                                          *
//* STEP030 - FILTER DEVELOPERS, SORT BY SALARY DESC, SAVE TO &&TEMP   *
//* STEP040 - REFORMAT &&TEMP RECORDS, SAVE TO FINAL DATASET           *
//* STEP050 - PRINT FINAL DATASET TO SYSOUT (RUNS ALWAYS)              *
//**********************************************************************
//* DELETE ALREADY EXISTING DATASETS IF THEY EXIST                     *
//* NOTE: SPACE PARAMETER USED IF DATASET DOES NOT EXIST               *
//**********************************************************************
//STEP010  EXEC PGM=IEFBR14                                             
//DELDD1   DD DSN=Z73460.TASK10.INPUT.JCL,                              
//            DISP=(MOD,DELETE,DELETE),                                 
//            SPACE=(TRK,(1,0))                                         
//DELDD2   DD DSN=Z73460.TASK10.FINAL.JCL,                              
//            DISP=(MOD,DELETE,DELETE),                                 
//            SPACE=(TRK,(1,0))                                         
//**********************************************************************
//* INSERT DATA INTO DATASET BY IEBGENER                               *
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
/*                                                                      
//SYSUT2   DD DSN=Z73460.TASK10.INPUT.JCL,                              
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(1,1),RLSE),                                   
//            DCB=(RECFM=FB,DSORG=PS,LRECL=80)                          
//**********************************************************************
//* BYPASSES THIS STEP IF STEP020 FAILS WITH RETURN CODE > 4           *
//* FILTER ONLY DEVELOPER RECORDS AND SORT BY SALARY DESCENDING        *
//* OUTPUT SAVED TO TEMPORARY DATASET &&TEMP                           *
//**********************************************************************
//STEP030  EXEC PGM=SORT,COND=(04,LT,STEP020)                           
//SYSPRINT DD SYSOUT=*                                                  
//SYSOUT   DD SYSOUT=*                                                  
//SORTIN   DD DSN=Z73460.TASK10.INPUT.JCL,DISP=SHR                      
//SORTOUT  DD DSN=&&TEMP,                                               
//            DISP=(NEW,PASS,DELETE),                                   
//            SPACE=(TRK,(1,1),RLSE),                                   
//            DCB=(RECFM=FB,DSORG=PS,LRECL=80)                          
//SYSIN    DD *                                                         
  SORT FIELDS=(31,6,CH,D)                                               
  INCLUDE COND=(21,9,CH,EQ,C'DEVELOPER')                                
/*                                                                      
//**********************************************************************
//* BYPASSES THIS STEP IF STEP030 RETURN CODE IS NOT EQUAL TO 0        *
//* REFORMAT RECORDS FROM &&TEMP: LASTNAME + '|' + SALARY              *
//* OUTPUT RECORD LENGTH = 10 + 1 + 6 = 17 BYTES                       *
//**********************************************************************
//STEP040  EXEC PGM=SORT,COND=(00,NE,STEP030)                           
//SYSPRINT DD SYSOUT=*                                                  
//SYSOUT   DD SYSOUT=*                                                  
//SORTIN   DD DSN=&&TEMP,                                               
//            DISP=(OLD,DELETE,DELETE)                                  
//SORTOUT  DD DSN=Z73460.TASK10.FINAL.JCL,                              
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(1,1),RLSE),                                   
//            DCB=(RECFM=FB,DSORG=PS,LRECL=80)                          
//SYSIN    DD *                                                         
  SORT FIELDS=COPY                                                      
  OUTREC BUILD=(1,10,C'|',31,6,63X)                                     
/*                                                                      
//**********************************************************************
//* PRINT FINAL DATASET TO SYSOUT                                      *
//* RUNS EVEN ON FAILS COND=EVEN EXECUTES THE STEP EVEN IF PREVIOUS    *
//*   SHIPS COMPLETED WITH ERRORS TO SHOW LOG RESULTS                  *
//**********************************************************************
//STEP050  EXEC PGM=IEBGENER,COND=EVEN                                  
//SYSPRINT DD SYSOUT=*                                                  
//SYSUT1   DD DSN=Z73460.TASK10.FINAL.JCL,DISP=SHR                      
//SYSUT2   DD SYSOUT=*                                                  
//SYSIN    DD DUMMY                                                     
