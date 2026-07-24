//TASK11   JOB (888),'MULTI STEPS',CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1),   
//             NOTIFY=&SYSUID                                           
//**********************************************************************
//* TASK11: MULTI-STEP JOB WITH OUTFIL, ICETOOL AND DATA MERGE         *
//* STEP010 - DELETE ALREADY EXISTING DATASETS (IF EXIST)              *
//* STEP020 - LOAD INPUT DATA INTO INITIAL DATASET                     *
//* STEP030 - SPLIT INTO DEVS AND MGRS FILES, SORT BY SALARY DESC      *
//* STEP040 - COUNT DEVELOPER RECORDS USING ICETOOL, WRITE TO DEVSCNT  *
//* STEP050 - MERGE DEVS AND MGRS BY SALARY DESC INTO MERGED DATASET   *
//* STEP060 - PRINT MERGED DATASET TO SYSOUT (RUNS ALWAYS)             *
//**********************************************************************
//**********************************************************************
//* DELETE ALREADY EXISTING DATASETS IF THEY EXIST                     *
//* NOTE: SPACE PARAMETER USED IF DATASET DOES NOT EXIST               *
//**********************************************************************
//STEP010  EXEC PGM=IEFBR14                                             
//DELDD1   DD DSN=Z73460.TASK11.JCL.INITIAL,                            
//            DISP=(MOD,DELETE,DELETE),                                 
//            SPACE=(TRK,(1,0))                                         
//DELDD2   DD DSN=Z73460.TASK11.JCL.DEVS,                               
//            DISP=(MOD,DELETE,DELETE),                                 
//            SPACE=(TRK,(1,0))                                         
//DELDD3   DD DSN=Z73460.TASK11.JCL.MGRS,                               
//            DISP=(MOD,DELETE,DELETE),                                 
//            SPACE=(TRK,(1,0))                                         
//DELDD4   DD DSN=Z73460.TASK11.JCL.DEVSCNT,                            
//            DISP=(MOD,DELETE,DELETE),                                 
//            SPACE=(TRK,(1,0))                                         
//DELDD5   DD DSN=Z73460.TASK11.JCL.MERGED,                             
//            DISP=(MOD,DELETE,DELETE),                                 
//            SPACE=(TRK,(1,0))                                         
//**********************************************************************
//* BYPASSES THIS STEP IF STEP010 FAILS WITH RETURN CODE > 4           *
//* INSERT DATA INTO DATASET BY IEBGENER                               *
//**********************************************************************
//STEP020  EXEC PGM=IEBGENER,COND=(04,LT,STEP010)                                            
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
LEBEDEV   ROMAN     MANAGER   006800                                    
ORLOV     NIKITA    ANALYST   003100                                    
/*                                                                      
//SYSUT2   DD DSN=Z73460.TASK11.JCL.INITIAL,                            
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(1,1),RLSE),                                   
//            DCB=(RECFM=FB,DSORG=PS,LRECL=80)                          
//**********************************************************************
//* BYPASSES THIS STEP IF STEP020 FAILS WITH RETURN CODE > 4           *
//* SORT BY SALARY DESC AND SPLIT INTO DEVS AND MGRS FILES             *
//**********************************************************************
//STEP030  EXEC PGM=SORT,COND=(04,LT,STEP020)                           
//SYSPRINT DD SYSOUT=*                                                  
//SYSOUT   DD SYSOUT=*                                                  
//SORTIN   DD DSN=Z73460.TASK11.JCL.INITIAL,DISP=SHR                    
//OUT1     DD DSN=Z73460.TASK11.JCL.DEVS,                               
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(1,1),RLSE),                                   
//            DCB=(RECFM=FB,DSORG=PS,LRECL=80)                          
//OUT2     DD DSN=Z73460.TASK11.JCL.MGRS,                               
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(1,1),RLSE),                                   
//            DCB=(RECFM=FB,DSORG=PS,LRECL=80)                          
//SYSIN    DD *                                                         
  SORT FIELDS=(31,6,CH,D)                                               
  OUTFIL FNAMES=OUT1,INCLUDE=(21,9,CH,EQ,C'DEVELOPER')                  
  OUTFIL FNAMES=OUT2,INCLUDE=(21,7,CH,EQ,C'MANAGER')                    
/*                                                                      
//**********************************************************************
//* BYPASSES THIS STEP IF STEP030 RETURN CODE NOT EQUAL 0              *
//* COUNT RECORDS IN DEVS DATASET AND WRITE TO DEVSCNT FILE            *
//**********************************************************************
//STEP040  EXEC PGM=ICETOOL,COND=(00,NE,STEP030)                        
//TOOLMSG  DD SYSOUT=*                                                  
//DFSMSG   DD SYSOUT=*                                                  
//IN       DD DSN=Z73460.TASK11.JCL.DEVS,DISP=SHR                       
//CNTDD    DD DSN=Z73460.TASK11.JCL.DEVSCNT,                            
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(1,1),RLSE),                                   
//            DCB=(RECFM=FB,DSORG=PS,LRECL=80)                          
//TOOLIN   DD *                                                         
  COUNT FROM(IN) WRITE(CNTDD)                                           
/*                                                                      
//**********************************************************************
//* BYPASSES THIS STEP IF STEP040 RETURN CODE NOT EQUAL 0              *
//* MERGE DEVS AND MGRS INTO ONE FILE SORTED BY SALARY DESC            *
//**********************************************************************
//STEP050  EXEC PGM=SORT,COND=(00,NE,STEP040)                           
//SYSPRINT DD SYSOUT=*                                                  
//SYSOUT   DD SYSOUT=*                                                  
//SORTIN01 DD DSN=Z73460.TASK11.JCL.DEVS,DISP=SHR                       
//SORTIN02 DD DSN=Z73460.TASK11.JCL.MGRS,DISP=SHR                       
//SORTOUT  DD DSN=Z73460.TASK11.JCL.MERGED,                             
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(1,1),RLSE),                                   
//            DCB=(RECFM=FB,DSORG=PS,LRECL=80)                          
//SYSIN    DD *                                                         
  MERGE FIELDS=(31,6,CH,D)                                              
/*                                                                      
//**********************************************************************
//* PRINT MERGED DATASET TO SYSOUT - EXECUTES ALWAYS (COND=EVEN)       *
//**********************************************************************
//STEP060  EXEC PGM=IEBGENER,COND=EVEN                                  
//SYSPRINT DD SYSOUT=*                                                  
//SYSUT1   DD DSN=Z73460.TASK11.JCL.MERGED,DISP=SHR                     
//SYSUT2   DD SYSOUT=*                                                  
//SYSIN    DD DUMMY                                                     
//
