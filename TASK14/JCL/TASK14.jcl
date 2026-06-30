//TASK14   JOB (888),'INSTREAM PROC',CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1), 
//             NOTIFY=&SYSUID                                           
//         EXPORT SYMLIST=(ROLE,MINSAL)                                 
//**********************************************************************
//* TASK14: INSTREAM PROC WITH TWO STEPS - SORT FILTER + ICETOOL COUNT *
//* RPTPROC - FILTERS BY &ROLE AND &MINSAL, COUNTS RECORDS INTO &OUTDSN*
//* STEP010  - LOADS DATA AND COPIES TO GLOBAL TEMP FILE &&ALLIN       *
//* STEP020  - CALL RPTPROC: COUNT DEVELOPERS WITH SALARY >= 004500    *
//* STEP030  - CALL RPTPROC: COUNT MANAGERS WITH SALARY >= 006000      *
//* STEP040  - CONCATENATE &&DCNT AND &&MCNT, PRINT TO SYSOUT          *
//**********************************************************************
//RPTPROC  PROC ROLE=,MINSAL=,OUTDSN=                                   
//*--------------------------------------------------------------------*
//* STEP 1: FILTER BY &ROLE AND SALARY >= &MINSAL, SORT BY SALARY DESC *
//*--------------------------------------------------------------------*
//STEP1    EXEC PGM=SORT,PARM='JP1"&ROLE",JP2"&MINSAL"'                 
//SYSPRINT DD SYSOUT=*                                                  
//SYSOUT   DD SYSOUT=*                                                  
//SORTIN   DD DSN=&&ALLIN,DISP=(OLD,PASS)                               
//SORTOUT  DD DSN=&&FILTERED,                                           
//            DISP=(NEW,PASS,DELETE),                                   
//            SPACE=(TRK,(1,1)),                                        
//            DCB=(RECFM=FB,DSORG=PS,LRECL=80)                          
//SYSIN    DD *                                                         
  SORT FIELDS=(31,6,CH,D)                                               
  INCLUDE COND=(21,10,CH,EQ,JP1,AND,31,6,CH,GE,JP2)                     
/*                                                                      
//*-------------------------------------------------------------------* 
//* BYPASSES THIS STEP IF STEP1 FAILS WITH RETURN CODE NOT EQUAL 0    * 
//* STEP 2: COUNT RECORDS IN &&FILTERED AND WRITE RESULT TO &OUTDSN   * 
//*-------------------------------------------------------------------* 
//STEP2    EXEC PGM=ICETOOL,COND=(00,NE,STEP1)                          
//TOOLMSG  DD SYSOUT=*                                                  
//DFSMSG   DD SYSOUT=*                                                  
//INDD     DD DSN=&&FILTERED,DISP=(OLD,DELETE)                          
//OUTDD    DD DSN=&OUTDSN,                                              
//            DISP=(NEW,PASS,DELETE),                                   
//            SPACE=(TRK,(1,1),RLSE),                                   
//            DCB=(RECFM=FB,DSORG=PS,LRECL=80)                          
//TOOLIN   DD *                                                         
  COUNT FROM(INDD) WRITE(OUTDD)                                         
/*                                                                      
//         PEND                                                         
//**********************************************************************
//* COPY RAW INLINE DATA TO TEMPORARY DATASET &&ALLIN                  *
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
//* CALL RPTPROC: FILTER DEVELOPERS WITH SALARY >= 004500              *
//**********************************************************************
//STEP020  EXEC RPTPROC,                                                
//            ROLE='DEVELOPER ',                                        
//            MINSAL='004500',                                          
//            OUTDSN=&&DCNT                                             
//**********************************************************************
//* CALL RPTPROC: FILTER MANAGERS WITH SALARY >= 006000                *
//**********************************************************************
//STEP030  EXEC RPTPROC,                                                
//            ROLE='MANAGER   ',                                        
//            MINSAL='006000',                                          
//            OUTDSN=&&MCNT                                             
//**********************************************************************
//* BYPASSES STEP IF ANY OF THE PROC STEPS RETURN CODE NOT RC=0        *
//* CONCATENATE &&DCNT AND &&MCNT AND PRINT TO SYSOUT                  *
//**********************************************************************
//STEP040  EXEC PGM=IEBGENER,                                           
//            COND=((00,NE,STEP020.STEP2),(00,NE,STEP030.STEP2))        
//SYSPRINT DD SYSOUT=*                                                  
//SYSUT1   DD DSN=&&DCNT,DISP=(OLD,DELETE)                              
//         DD DSN=&&MCNT,DISP=(OLD,DELETE)                              
//SYSUT2   DD SYSOUT=*                                                  
//SYSIN    DD DUMMY                                                     
//
