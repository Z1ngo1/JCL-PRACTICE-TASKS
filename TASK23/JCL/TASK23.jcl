//TASK23   JOB (888),'GDG',CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1),           
//             NOTIFY=&SYSUID                                           
//**********************************************************************
//* TASK23: GDG - CREATE BASE, WRITE GENERATIONS, READ GENERATIONS     *
//* STEP010 - DELETE GDG BASE IF EXISTS (RC=8 IS NORMAL)               *
//* STEP020 - DEFINE GDG BASE WITH LIMIT(3) SCRATCH NOEMPTY            *
//* STEP030 - WRITE GENERATION (+1) - DATA VIA IEBGENER                *
//* STEP040 - WRITE GENERATION (+1) - DATA VIA IEBGENER                *
//* STEP050 - READ CURRENT GENERATION (0) - PRINT TO SYSOUT            *
//* STEP060 - READ PREVIOUS GENERATION (-1) - PRINT TO SYSOUT          *
//**********************************************************************
//**********************************************************************
//* DELETE GDG BASE IF IT ALREADY EXISTS                               *
//* GDG KEYWORD TELLS IDCAMS THIS IS A GDG BASE, NOT A REGULAR DATASET *
//* RC=8 = DATASET NOT FOUND - ACCEPTABLE, RESET MAXCC TO 0            *
//**********************************************************************
//STEP010  EXEC PGM=IDCAMS                                              
//SYSPRINT DD SYSOUT=*                                                  
//SYSIN    DD *                                                         
  DELETE Z73460.TASK23.HLQ.EMPGDG.JCL.*                                 
  DELETE Z73460.TASK23.HLQ.EMPGDG.JCL GDG PURGE                         
  IF MAXCC <=8 THEN SET MAXCC = 0                                       
/*                                                                      
//**********************************************************************
//* BYPASSED THIS STEP IF STEP010 RC > 8                               *
//* DEFINE GDG BASE - ONLY THE CATALOG ENTRY, NO ACTUAL DATASET YET    *
//* LIMIT(3)   - KEEP MAXIMUM 3 GENERATIONS AT A TIME                  *
//* SCRATCH    - PHYSICALLY DELETE OLDEST GENERATION WHEN LIMIT HIT    *
//*              WITHOUT SCRATCH - DATASET UNCATALOGED BUT NOT DELETED *
//* NOEMPTY    - WHEN LIMIT HIT, REMOVE ONLY OLDEST ONE GENERATION     *
//*              EMPTY WOULD DELETE ALL GENERATIONS AT ONCE            *
//**********************************************************************
//STEP020  EXEC PGM=IDCAMS,COND=(08,LT,STEP010)                         
//SYSPRINT DD SYSOUT=*                                                  
//SYSIN    DD *                                                         
  DEFINE GDG(NAME(Z73460.TASK23.HLQ.EMPGDG.JCL) -                       
         LIMIT(3) -                                                     
         SCRATCH -                                                      
         NOEMPTY)                                                       
/*                                                                      
//**********************************************************************
//* BYPASSED THIS STEP IF STEP020 RETURNED CODE NOT EQUAL 0            *
//* INSERT DATA INTO DATASET BY USING GENERATE MAXFLDS PARAMETER       *
//* ROWS ARE FORMATTED TO AN EXACT RECORD LENGTH OF 36 BYTES           *
//* (+1) - RELATIVE GENERATION NUMBER, CREATES NEW NEXT GENERATION     *
//* AT JOB END (+1) IS RESOLVED TO ABSOLUTE NAME: .G0001V00            *
//**********************************************************************
//STEP030  EXEC PGM=IEBGENER,COND=(00,NE,STEP020)                       
//SYSPRINT DD SYSOUT=*                                                  
//SYSIN    DD *                                                         
  GENERATE MAXFLDS=1                                                    
  RECORD FIELD=(36,1,,1)                                                
/*                                                                      
//SYSUT1   DD *                                                         
001IVANOV    DEVELOPER 005000                                           
002PETROV    ANALYST   003200                                           
003SIDOROV   MANAGER   007800                                           
/*                                                                      
//SYSUT2   DD DSN=Z73460.TASK23.HLQ.EMPGDG.JCL(+1),                     
//            DISP=(NEW,CATLG,DELETE),                                  
//            UNIT=SYSDA,                                               
//            SPACE=(TRK,(1,1)),                                        
//            DCB=(RECFM=FB,DSORG=PS,LRECL=36)                          
//**********************************************************************
//* BYPASSED THIS STEP IF STEP030 RETURNED CODE NOT EQUAL 0            *
//* SECOND PACK OF EMPLOYEE DATA (SALARY UPDATED)                      *
//* INSERT DATA INTO DATASET BY USING GENERATE MAXFLDS PARAMETER       *
//* ROWS ARE FORMATTED TO AN EXACT RECORD LENGTH OF 36 BYTES           *
//* (+1) IN SAME JOB - WILL BECOME G0002V00 AT JOB END                 *
//**********************************************************************
//STEP040  EXEC PGM=IEBGENER,COND=(00,NE,STEP030)                       
//SYSPRINT DD SYSOUT=*                                                  
//SYSIN    DD *                                                         
  GENERATE MAXFLDS=1                                                    
  RECORD FIELD=(36,1,,1)                                                
/*                                                                      
//SYSUT1   DD *                                                         
001IVANOV    DEVELOPER 005500                                           
002PETROV    ANALYST   003500                                           
003SIDOROV   MANAGER   008000                                           
004KOZLOV    DEVELOPER 004500                                           
/*                                                                      
//SYSUT2   DD DSN=Z73460.TASK23.HLQ.EMPGDG.JCL(+2),                     
//            DISP=(NEW,CATLG,DELETE),                                  
//            UNIT=SYSDA,                                               
//            SPACE=(TRK,(1,1)),                                        
//            DCB=(RECFM=FB,DSORG=PS,LRECL=36)                          
//**********************************************************************
//* BYPASSED THIS STEP IF STEP040 RETURNED CODE NOT EQUAL 0            *
//* READ CURRENT GENERATION (0) = FIRST PACK OF DATA (LATEST, G0002V00)*
//* (0) RESOLVES TO MOST RECENTLY CATALOGED GENERATION                 *
//**********************************************************************
//STEP050  EXEC PGM=IEBGENER,COND=(00,NE,STEP040)                       
//SYSPRINT DD SYSOUT=*                                                  
//SYSUT1   DD DSN=Z73460.TASK23.HLQ.EMPGDG.JCL(+1),DISP=SHR             
//SYSUT2   DD SYSOUT=*                                                  
//SYSIN    DD DUMMY                                                     
//**********************************************************************
//* BYPASSED THIS STEP IF STEP040 RETURNED CODE NOT EQUAL 0            *
//* READ PREVIOUS GENERATION (-1) = SECOND PACK OF DATA (G0001V00)     *
//* (-1) RESOLVES TO ONE GENERATION BEFORE CURRENT                     *
//**********************************************************************
//STEP060  EXEC PGM=IEBGENER,COND=(00,NE,STEP040)                       
//SYSPRINT DD SYSOUT=*                                                  
//SYSUT1   DD DSN=Z73460.TASK23.HLQ.EMPGDG.JCL(+2),DISP=SHR             
//SYSUT2   DD SYSOUT=*                                                  
//SYSIN    DD DUMMY                                                     
