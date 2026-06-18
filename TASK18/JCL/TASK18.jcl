//TASK18   JOB (888),'IDCAMS STEPS',CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1),  
//             NOTIFY=&SYSUID                                           
//**********************************************************************
//* TASK18: IDCAMS DELETE + IEFBR14 ALLOCATE + IDCAMS REPRO            *
//* STEP010 - DELETE DATASET IF EXISTS (RC=8 ACCEPTABLE - NOT FOUND)   *
//*           NONVSAM SCRATCH PURGE - PHYSICAL REMOVE FROM VTOC        *
//* STEP020 - CREATE NEW SEQUENTIAL FILE VIA IEFBR14                   *
//*           SKIPPED IF STEP010 RC > 8 (COND=(08,LT,STEP010))         *
//* STEP030 - LOAD INLINE EMPLOYEE DATA INTO DATASET VIA IDCAMS REPRO  *
//*           SKIPPED IF STEP020 RC != 0 (COND=(00,NE,STEP020))        *
//**********************************************************************
//STEP010  EXEC PGM=IDCAMS                                              
//SYSPRINT DD SYSOUT=*                                                  
//SYSIN    DD *                                                         
  DELETE Z73460.TASK18.HLQ.EMPFILE.JCL NONVSAM SCRATCH PURGE            
  IF LASTCC <= 8 THEN SET MAXCC = 0                                     
/*                                                                      
//**********************************************************************
//* BYPASSED THIS STEP IF STEP010 RC > 8                               *
//* ALLOCATE EMPTY SEQUENTIAL DATASET: RECFM=FB, LRECL=80, DSORG=PS    *
//**********************************************************************
//STEP020  EXEC PGM=IEFBR14,COND=(08,LT,STEP010)                        
//EMPFILE  DD DSN=Z73460.TASK18.HLQ.EMPFILE.JCL,                        
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(1,1)),                                        
//            DCB=(RECFM=FB,DSORG=PS,LRECL=80)                          
//**********************************************************************
//* BYPASSED THIS STEP IF STEP020 RETURNED CODE NOT EQUAL 0            *
//* REPRO COPIES INLINE RECORDS FROM INDD INTO TARGET DATASET OUTDD    *
//* FIELDS: LASTNAME(10) FIRSTNAME(10) POSITION(10) SALARY(6)          *
//**********************************************************************
//STEP030  EXEC PGM=IDCAMS,COND=(00,NE,STEP020)                         
//SYSPRINT DD SYSOUT=*                                                  
//INDD     DD *                                                         
IVANOV    IVAN      DEVELOPER 005000                                    
PETROV    PETR      ANALYST   003200                                    
SIDOROV   SERGEY    MANAGER   007800                                    
KOZLOV    ALEXEY    DEVELOPER 004500                                    
MOROZOV   DMITRY    ANALYST   002900                                    
/*                                                                      
//OUTDD    DD DSN=Z73460.TASK18.HLQ.EMPFILE.JCL,DISP=SHR                
//SYSIN    DD *                                                         
  REPRO INFILE(INDD) -                                                  
        OUTFILE(OUTDD)                                                  
/*                                                                      
