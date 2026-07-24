//TASK20   JOB (888),'VERIFT + REPRO',CLASS=A,MSGCLASS=A,               
//             MSGLEVEL=(1,1),NOTIFY=&SYSUID                            
//**********************************************************************
//* TASK20: VERIFY + REPRO EXPORT + ALTER FREESPACE + REPRO INSERT     *
//* STEP010 - EXECUTE VERIFY TO VALIDATE KSDS CLUSTER STRUCTURE        *
//* STEP015 - DELETE EMPBKUP IF EXISTS                                 *
//* STEP020 - REPRO: UNLOAD KSDS TO SEQ BACKUP FILE (EMPBKUP)          *
//* STEP030 - ALTER CLUSTER FREESPACE TO (10 30)                       *
//* STEP035 - SORT: TRIM INLINE 80-BYTE CARDS -> TEMPFILE LRECL=36     *
//* STEP040 - REPRO: INSERT 3 NEW RECORDS FROM TEMPFILE INTO KSDS      *
//**********************************************************************
//**********************************************************************
//* VERIFY CHECKS KSDS END-OF-FILE POINTERS AFTER POSSIBLE CRASH       *
//* MUST RUN BEFORE ANY READ/WRITE OPERATION ON THE CLUSTER            *
//**********************************************************************
//STEP010  EXEC PGM=IDCAMS                                              
//SYSPRINT DD SYSOUT=*                                                  
//SYSIN    DD *                                                         
  VERIFY DATASET(Z73460.TASK19.JCL.EMPKSDS)                         
/*                                                                      
//**********************************************************************
//* DELETE ALREADY EXISTING DATASES IF EXIST                           *
//* NOTE: SPACE PARAMETER USED IF DATASET DOES NOT EXIST               *
//**********************************************************************
//STEP015  EXEC PGM=IEFBR14                                             
//DELDD1   DD DSN=Z73460.TASK20.JCL.EMPBKUP,                        
//            DISP=(MOD,DELETE,DELETE),                                 
//            SPACE=(TRK,(1,1))                                         
//**********************************************************************
//* BYPASSED THIS STEP IF STEP010 OR STEP015 RETURNED CODE NOT EQUAL 0 *
//* UNLOAD VSAM KSDS CONTENT TO SEQUENTIAL BACKUP FILE                 *
//**********************************************************************
//STEP020  EXEC PGM=IDCAMS,COND=((00,NE,STEP010),(00,NE,STEP015))                     
//SYSPRINT DD SYSOUT=*                                                  
//INDD     DD DSN=Z73460.TASK19.JCL.EMPKSDS,DISP=SHR                
//OUTDD    DD DSN=Z73460.TASK20.JCL.EMPBKUP,                        
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(1,1),RLSE),                                   
//            DCB=(RECFM=FB,DSORG=PS,LRECL=36)                          
//SYSIN    DD *                                                         
  REPRO INFILE(INDD) -                                                  
        OUTFILE(OUTDD)                                                  
/*                                                                      
//**********************************************************************
//* BYPASSED THIS STEP IF STEP030 RETURNED CODE NOT EQUAL 0            *
//* ALTER FREESPACE ON DATA COMPONENT:                                 *
//*   FREESPACE(10 30) = 10% FREE PER CI, 30% FREE PER CA              *
//**********************************************************************
//STEP030  EXEC PGM=IDCAMS,COND=(00,NE,STEP020)                         
//SYSPRINT DD SYSOUT=*                                                  
//SYSIN    DD *                                                         
  ALTER Z73460.TASK19.JCL.EMPKSDS.DATA -                            
        FREESPACE(10,30)                                                
/*                                                                      
//**********************************************************************
//* BYPASSED THIS IF STEP035 RETURNED CODE NOT EQUAL 0                 *
//* SORT TRIMS INLINE 80-BYTE JCL CARDS TO LRECL=36 VIA OUTREC         *
//**********************************************************************
//STEP035  EXEC PGM=SORT,COND=(00,NE,STEP030)                           
//SYSPRINT DD SYSOUT=*                                                  
//SYSOUT   DD SYSOUT=*                                                  
//SORTIN   DD *                                                         
008SOKOLOV   DEVELOPER 005500                                           
009LEBEDEV   MANAGER   006800                                           
010ORLOV     ANALYST   003100                                           
/*                                                                      
//SORTOUT  DD DSN=&&TEMPFILE,                                           
//            DISP=(NEW,PASS,DELETE),                                   
//            SPACE=(TRK,(1,1)),                                        
//            DCB=(RECFM=FB,DSORG=PS,LRECL=36)                          
//SYSIN    DD *                                                         
  SORT FIELDS=COPY                                                      
  OUTREC BUILD=(1,36)                                                   
/*                                                                      
//**********************************************************************
//* BYPASSED THIS STEP IF STEP040 RETURNED CODE NOT EQUAL 0            *
//* REPRODUCE NEW FORMATTED RECORDS INTO CURRENT KSDS CLUSTE           *
//**********************************************************************
//STEP040  EXEC PGM=IDCAMS,COND=((00,NE,STEP030),(00,NE,STEP035))       
//SYSPRINT DD SYSOUT=*                                                  
//TEMPREC  DD DSN=&&TEMPFILE,DISP=(OLD,DELETE)                          
//OUTKSDS  DD DSN=Z73460.TASK19.JCL.EMPKSDS,DISP=SHR                
//SYSIN    DD *                                                         
  REPRO INFILE(TEMPREC) -                                               
        OUTFILE(OUTKSDS)                                                
/*                                                                      
//
