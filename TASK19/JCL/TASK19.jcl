//TASK19   JOB (888),'REPRO + LISTCAT',CLASS=A,MSGCLASS=A,              
//             MSGLEVEL=(1,1),NOTIFY=&SYSUID                            
//**********************************************************************
//* TASK19: IDCAMS DEFINE KSDS + IEBGENER + REPRO + LISTCAT            *
//* STEP010 - DELETE CLUSTER AND INFILE IF THEY EXIST (RC=8 IS NORMAL) *
//* STEP020 - DEFINE VSAM KSDS CLUSTER                                 *
//* STEP030 - CREATE SEQ INFILE FROM INLINE DATA USING IEBGENER        *
//* STEP040 - REPRO: COPY FROM INFILE INTO KSDS CLUSTER                *
//* STEP050 - LISTCAT ALL: VERIFY CLUSTER EXISTS WITH CORRECT PARAMS   *
//**********************************************************************
//**********************************************************************
//* DELETE CLUSTER AND SEQUENTIAL INFILE IF THEY ALREADY EXIST         *
//* RC=8 FROM DELETE = DATASET NOT FOUND - ACCEPTABLE, RESET TO 0      *
//**********************************************************************
//STEP010  EXEC PGM=IDCAMS                                              
//SYSPRINT DD SYSOUT=*                                                  
//SYSIN    DD *                                                         
  DELETE Z73460.TASK19.HLQ.EMPKSDS.JCL CLUSTER PURGE                    
  DELETE Z73460.TASK19.INFILE.JCL NONVSAM SCRATCH PURGE                 
  IF LASTCC <= 8 THEN SET MAXCC = 0                                     
/*                                                                      
//**********************************************************************
//* BYPASSED THIS STEP IF STEP010 RC > 8                               *
//* DEFINE VSAM KSDS CLUSTER: KEY LENGTH=3, FIXED 36 BYTES LENGHT      *
//* PRIMARY 1 TRACK                                                    *
//* 10% CI FREE, 20% CA FREE FOR FUTURE INSERTS                        *
************************************************************************
//STEP020  EXEC PGM=IDCAMS,COND=(08,LT,STEP010)                         
//SYSPRINT DD SYSOUT=*                                                  
//SYSIN    DD *                                                         
  DEFINE CLUSTER -                                                      
    (NAME(Z73460.TASK19.HLQ.EMPKSDS.JCL) -                              
     KEYS(3 0) -                                                        
     RECORDSIZE(36,36) -                                                
     TRACKS(1 1) -                                                      
     INDEXED -                                                          
     FREESPACE(10,20)) -                                                
    DATA -                                                              
    (NAME(Z73460.TASK19.HLQ.EMPKSDS.JCL.DATA)) -                        
    INDEX -                                                             
    (NAME(Z73460.TASK19.HLQ.EMPKSDS.JCL.INDEX))                         
/*                                                                      
//**********************************************************************
//* BYPASSED THIS STEP IF STEP010 RC > 8                               *
//* ROWS ARE FORMATTED TO AN EXACT RECORD LENGTH OF 36 BYTES           *
//**********************************************************************
//STEP030  EXEC PGM=IEBGENER,COND=(08,LT,STEP010)                       
//SYSPRINT DD SYSOUT=*                                                  
//SYSUT1   DD *                                                         
001IVANOV    DEVELOPER 005000                                           
002PETROV    ANALYST   003200                                           
003SIDOROV   MANAGER   007800                                           
004KOZLOV    DEVELOPER 004500                                           
005MOROZOV   ANALYST   002900                                           
006NOVIKOV   DEVELOPER 006100                                           
007POPOV     MANAGER   008200                                           
/*                                                                      
//SYSUT2   DD DSN=Z73460.TASK19.INFILE.JCL,                             
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(1,1),RLSE),                                   
//            DCB=(RECFM=FB,DSORG=PS,LRECL=36)                          
//SYSIN    DD *                                                         
  GENERATE MAXFLDS=1                                                    
  RECORD FIELD=(36,1,,1)                                                
/*                                                                      
//**********************************************************************
//* BYPASSED THIS STEP IF STEP020 OR STEP030 RETURNED CODE NOT EQUAL 0 *
//* REPRO COPIES 36-BYTE RECORDS FROM SEQ INFILE INTO KSDS CLUSTER     *
//**********************************************************************
//STEP040  EXEC PGM=IDCAMS,COND=((00,NE,STEP020),(00,NE,STEP030))       
//SYSPRINT DD SYSOUT=*                                                  
//SYSIN    DD *                                                         
  REPRO INFILE(INDD) -                                                  
         OUTFILE(OUTDD)                                                 
/*                                                                      
//INDD     DD DSN=Z73460.TASK19.INFILE.JCL,DISP=SHR                     
//OUTDD    DD DSN=Z73460.TASK19.HLQ.EMPKSDS.JCL,DISP=SHR                
//**********************************************************************
//* BYPASSED THIS STEP IF STEP040 RETURNED CODE NOT EQUAL 0            *
//* LISTCAT ALL: PRINTS CLUSTER DEFINITION, DATA/INDEX COMPONENT INFO  *
//* VERIFIES CLUSTER EXISTS WITH CORRECT KEYS AND RECORDSIZE PARAMS    *
//**********************************************************************
//STEP050  EXEC PGM=IDCAMS,COND=(00,NE,STEP040)                         
//SYSPRINT DD SYSOUT=*                                                  
//SYSIN    DD *                                                         
  LISTCAT ENTRIES(Z73460.TASK19.HLQ.EMPKSDS.JCL) ALL                    
/*                                                                      
