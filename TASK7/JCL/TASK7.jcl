//TASK7    JOB (888),'OUTREC PRACTISE',CLASS=A,MSGCLASS=A,              
//             MSGLEVEL=(1,1),NOTIFY=&SYSUID                            
//**********************************************************************
//* TASK7: REFORMAT RECORDS USING OUTREC WITH LITERAL PREFIX           *
//* LOAD EMPLOYEE DATA WITH SALARY FIELD INTO INPUT DATASET, THEN      *
//* USE SORT OUTREC TO BUILD NEW FORMAT:                               *
//* 'REC:' + LASTNAME(10) + SALARY(6) = 20 BYTES OUTPUT                *
//**********************************************************************
//**********************************************************************
//* DELETE ALREADY EXISTING DATASETS IF THEY EXIST                     *
//* NOTE: SPACE PARAMETER USED IF DATASET DOES NOT EXIST               *
//**********************************************************************
//STEP010  EXEC PGM=IEFBR14                                             
//DELDD1   DD DSN=Z73460.TASK7.INPUT.JCL,                               
//            SPACE=(TRK,(1,0)),                                        
//            DISP=(MOD,DELETE,DELETE)                                  
//DELDD2   DD DSN=Z73460.TASK7.OUTPUT.JCL,                              
//            SPACE=(TRK,(1,0)),                                        
//            DISP=(MOD,DELETE,DELETE)                                  
//**********************************************************************
//* INSERT DATA INTO DATASET BY USING GENERATE MAXFLDS PARAMETER       *
//* ROWS ARE FORMATTED TO AN EXACT RECORD LENGTH OF 36 BYTES           *
//**********************************************************************
//STEP020  EXEC PGM=IEBGENER                                            
//SYSPRINT DD SYSOUT=*                                                  
//SYSIN    DD *                                                         
  GENERATE MAXFLDS=1                                                    
  RECORD FIELD=(36,1,,1)                                                
/*                                                                      
//SYSUT1   DD *                                                         
IVANOV    IVAN      DEVELOPER 005000                                    
PETROV    PETR      ANALYST   003200                                    
SIDOROV   SERGEY    MANAGER   007800                                    
KOZLOV    ALEXEY    DEVELOPER 004500                                    
MOROZOV   DMITRY    ANALYST   002900                                    
NOVIKOV   OLEG      DEVELOPER 006100                                    
POPOV     ANDREY    MANAGER   008200                                    
/*                                                                      
//SYSUT2   DD DSN=Z73460.TASK7.INPUT.JCL,                               
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(1,1),RLSE),                                   
//            DCB=(RECFM=FB,DSORG=PS,LRECL=36)                          
//**********************************************************************
//* BYPASSES THE STEP IF STEP020 FAILS WITH RETURN CODE > 4            *
//* REFORMAT INPUT FILE AND ADD CONSTANT PREFIX USING OUTREC BUILD     *
//* NEW LAYOUT: PREFIX 'REC:' + LASTNAME(1,10) + SALARY(31,6)          *
//**********************************************************************
    //STEP030  EXEC PGM=SORT,COND=(04,LT,STEP020)                           
//SYSPRINT DD SYSOUT=*                                                  
//SYSOUT   DD SYSOUT=*                                                  
//SORTIN   DD DSN=Z73460.TASK7.INPUT.JCL,DISP=SHR                       
//SORTOUT  DD DSN=Z73460.TASK7.OUTPUT.JCL,                              
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(1,1),RLSE),                                   
//            DCB=(RECFM=FB,DSORG=PS,LRECL=20)                          
//SYSIN    DD *                                                         
  SORT FIELDS=COPY                                                      
  OUTREC BUILD=(C'REC:',1,10,31,6)                                      
/*                                                                      
