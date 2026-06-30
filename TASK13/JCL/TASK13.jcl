//TASK13   JOB (888),'INSTREAM PROC',CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1), 
//             NOTIFY=&SYSUID                                           
//         EXPORT SYMLIST=(ROLE)                                        
//**********************************************************************
//* TASK13: INSTREAM PROC WITH SYMBOLIC PARAMETERS + SORT + COND       *
//* FILTPROC - FILTERS BY &ROLE AND SORTS BY SALARY DESC INTO &OUTDSN  *
//* STEP010 - LOAD INPUT DATA AND COPY TO TEMP DATASET &&ALLIN         *
//* STEP020 - CALL FILTPROC: FILTER DEVELOPERS INTO &&DEVOUT           *
//* STEP030 - CALL FILTPROC: FILTER MANAGERS INTO &&MGROUT             *
//* STEP040 - CONCATENATE &&DEVOUT AND &&MGROUT, PRINT TO SYSOUT       *
//**********************************************************************
//FILTPROC PROC ROLE=,OUTDSN=                                           
//*-------------------------------------------------------------------* 
//* PROC STEP: FILTER BY ROLE AND SORT BY SALARY DESCENDING           * 
//*-------------------------------------------------------------------* 
//STEP1    EXEC PGM=SORT                                                
//SYSPRINT DD SYSOUT=*                                                  
//SYSOUT   DD SYSOUT=*                                                  
//SORTIN   DD DSN=&&ALLIN,DISP=(OLD,PASS)                               
//SORTOUT  DD DSN=&OUTDSN,                                              
//            DISP=(NEW,PASS,DELETE),                                   
//            SPACE=(TRK,(1,1),RLSE),                                   
//            DCB=(RECFM=FB,DSORG=PS,LRECL=80)                          
//SYSIN    DD *,SYMBOLS=JCLONLY                                         
  SORT FIELDS=(31,6,CH,D)                                               
  INCLUDE COND=(21,10,CH,EQ,C'&ROLE')                                   
/*                                                                      
//         PEND                                                         
//**********************************************************************
//* LOAD INPUT DATA AND COPY TO TEMPORARY DATASET &&ALLIN              *
//**********************************************************************
//STEP010  EXEC PGM=SORT                                                
//SYSPRINT DD SYSOUT=*                                                  
//SYSOUT   DD SYSOUT=*                                                  
//SORTIN   DD *                                                         
IVANOV    IVAN      DEVELOPER 005000                                    
PETROV    PETR      ANALYST   003200                                    
SIDOROV   SERGEY    MANAGER   007800                                    
KOZLOV    ALEXEY    DEVELOPER 004500                                    
MOROZOV   DMITRY    ANALYST   002900                                    
NOVIKOV   OLEG      DEVELOPER 006100                                    
POPOV     ANDREY    MANAGER   008200                                    
SOKOLOV   DENIS     DEVELOPER 005500                                    
LEBEDEV   ROMAN     MANAGER   006800                                    
ORLOV     NIKITA    ANALYST   003100                                    
/*                                                                      
//SORTOUT  DD DSN=&&ALLIN,                                              
//            DISP=(NEW,PASS,DELETE),                                   
//            SPACE=(TRK,(1,1)),                                        
//            DCB=(RECFM=FB,DSORG=PS,LRECL=80)                          
//SYSIN    DD *                                                         
  SORT FIELDS=COPY                                                      
/*                                                                      
//**********************************************************************
//* CALL FILTPROC: FILTER DEVELOPERS, SORT BY SALARY DESC              *
//**********************************************************************
//STEP020  EXEC FILTPROC,                                               
//            ROLE='DEVELOPER ',                                        
//            OUTDSN=&&DEVOUT                                           
//**********************************************************************
//* CALL FILTPROC: FILTER MANAGERS, SORT BY SALARY DESC                *
//* OVERRIDE SORTIN TO DELETE &&ALLIN AFTER LAST USE                   *
//**********************************************************************
//STEP030  EXEC FILTPROC,                                               
//            ROLE='MANAGER   ',                                        
//            OUTDSN=&&MGROUT                                           
//**********************************************************************
//* BYPASSES STEP IF ANY OF THE PROC STEPS RETURN CODE NOT RC=0        *
//* STEP040: CONCATENATE &&DEVOUT AND &&MGROUT DATASETS TO SYSOUT=*    *
//**********************************************************************
//STEP040  EXEC PGM=IEBGENER,                                           
//           COND=((00,NE,STEP020.STEP1),(00,NE,STEP030.STEP1))         
//SYSPRINT DD SYSOUT=*                                                  
//SYSUT1   DD DSN=&&DEVOUT,DISP=(OLD,DELETE)                            
//         DD DSN=&&MGROUT,DISP=(OLD,DELETE)                            
//SYSUT2   DD SYSOUT=*                                                  
//SYSIN    DD DUMMY                                                     
/*                                                                      
//
