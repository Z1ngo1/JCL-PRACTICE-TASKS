//TASK21   JOB (888),'IEBCOPY',CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1),       
//             NOTIFY=&SYSUID                                           
//**********************************************************************
//* TASK21: IEBCOPY - CREATE PDS, LOAD MEMBERS, COPY, COMPRESS         *
//* STEP010 - DELETE SRCLIB AND TGTLIB IF THEY EXIST (RC=8 IS NORMAL)  *
//* STEP020 - CREATE TWO EMPTY PDS LIBRARIES VIA IEFBR14               *
//* STEP030 - LOAD MEMBER1 (DEVELOPERS) INTO SRCLIB VIA IEBGENER       *
//* STEP033 - LOAD MEMBER2 (ANALYSTS) INTO SRCLIB VIA IEBGENER         *
//* STEP036 - LOAD MEMBER3 (MANAGERS) INTO SRCLIB VIA IEBGENER         *
//* STEP040 - IEBCOPY: COPY MEMBER1 AND MEMBER3 ONLY TO TGTLIB         *
//* STEP050 - IEBCOPY: COMPRESS SRCLIB IN PLACE                        *
//**********************************************************************
//**********************************************************************
//* DELETE BOTH PDS LIBRARIES IF THEY ALREADY EXIST                    *
//* NONVSAM SCRATCH PURGE - PHYSICAL REMOVE FROM VTOC                  *
//* RC=8 = DATASET NOT FOUND - ACCEPTABLE, RESET MAXCC TO 0            *
//**********************************************************************
//STEP010  EXEC PGM=IDCAMS                                              
//SYSPRINT DD SYSOUT=*                                                  
//SYSIN    DD *                                                         
  DELETE Z73460.TASK21.JCL.SRCLIB NONVSAM SCRATCH PURGE             
  DELETE Z73460.TASK21.JCL.TGTLIB NONVSAM SCRATCH PURGE             
  IF MAXCC <= 8 THEN SET MAXCC = 0                                      
/*                                                                      
//**********************************************************************
//* BYPASSED THIS STEP IF STEP010 RC > 8                               *
//* CREATE TWO EMPTY PDS LIBRARIES VIA IEFBR14 (DUMMY PROGRAM)         *
//* SPACE=(TRK,(2,2,10)):                                              *
//*   2  - PRIMARY   2 TRACKS ALLOCATED IMMEDIATELY                    *
//*   2  - SECONDARY 2 TRACKS ADDED WHEN PRIMARY IS EXHAUSTED          *
//*   10 - DIRECTORY 10 BLOCKS (6 MEMBERS PER BLOCK)                   *
//**********************************************************************
//STEP020  EXEC PGM=IEFBR14,COND=(08,LT,STEP010)                        
//CRTPDS1  DD DSN=Z73460.TASK21.JCL.SRCLIB,                         
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(2,2,10)),                                     
//            DCB=(RECFM=FB,DSORG=PO,LRECL=80,BLKSIZE=3200)             
//CRTPDS2  DD DSN=Z73460.TASK21.JCL.TGTLIB,                         
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(2,2,10)),                                     
//            DCB=(RECFM=FB,DSORG=PO,LRECL=80,BLKSIZE=3200)             
//**********************************************************************
//* BYPASSED THIS STEP IF STEP020 RETURNED CODE NOT EQUAL 0            *
//* LOAD MEMBER1 (DEVELOPERS) INTO SRCLIB VIA IEBGENER                 *
//**********************************************************************
//STEP030  EXEC PGM=IEBGENER,COND=(00,NE,STEP020)                       
//SYSPRINT DD SYSOUT=*                                                  
//SYSUT1   DD *                                                         
001IVANOV    DEVELOPER 005000                                           
004KOZLOV    DEVELOPER 004500                                           
006NOVIKOV   DEVELOPER 006100                                           
008SOKOLOV   DEVELOPER 005500                                           
/*                                                                      
//SYSUT2   DD DSN=Z73460.TASK21.JCL.SRCLIB(MEMBER1),DISP=SHR        
//SYSIN    DD DUMMY                                                     
//**********************************************************************
//* BYPASSED THIS STEP IF STEP020 RETURNED CODE NOT EQUAL 0            *
//* LOAD MEMBER2 (ANALYSTS) INTO SRCLIB VIA IEBGENER                   *
//**********************************************************************
//STEP033  EXEC PGM=IEBGENER,COND=(00,NE,STEP020)                       
//SYSPRINT DD SYSOUT=*                                                  
//SYSUT1   DD *                                                         
002PETROV    ANALYST   003200                                           
005MOROZOV   ANALYST   002900                                           
010ORLOV     ANALYST   003100                                           
/*                                                                      
//SYSUT2   DD DSN=Z73460.TASK21.JCL.SRCLIB(MEMBER2),DISP=SHR        
//SYSIN    DD DUMMY                                                     
//**********************************************************************
//* BYPASSED THIS STEP IF STEP020 RETURNED CODE NOT EQUAL 0            *
//* LOAD MEMBER3 (MANAGERS) INTO SRCLIB VIA IEBGENER                   *
//**********************************************************************
//STEP036  EXEC PGM=IEBGENER,COND=(00,NE,STEP020)                       
//SYSPRINT DD SYSOUT=*                                                  
//SYSUT1   DD *                                                         
003SIDOROV   MANAGER   007800                                           
007POPOV     MANAGER   008200                                           
009LEBEDEV   MANAGER   006800                                           
/*                                                                      
//SYSUT2   DD DSN=Z73460.TASK21.JCL.SRCLIB(MEMBER3),DISP=SHR        
//SYSIN    DD DUMMY                                                     
//**********************************************************************
//* BYPASSED IF STEP030, STEP033 OR STEP036 RETURNED CODE NOT EQUAL 0  *
//* IEBCOPY SELECTIVE COPY: MEMBER1 AND MEMBER3 ONLY -> TGTLIB         *
//* SELECT MEMBER=((NAME,,R)) - R=REPLACE IF ALREADY EXISTS IN OUTPUT  *
//* MEMBER2 (ANALYSTS) IS INTENTIONALLY EXCLUDED                       *
//**********************************************************************
//STEP040  EXEC PGM=IEBCOPY,                                            
//           COND=((00,NE,STEP030),(00,NE,STEP033),(00,NE,STEP036))     
//SYSPRINT DD SYSOUT=*                                                  
//INPUT    DD DSN=Z73460.TASK21.JCL.SRCLIB,DISP=SHR                 
//OUTPUT   DD DSN=Z73460.TASK21.JCL.TGTLIB,DISP=SHR                 
//SYSIN    DD *                                                         
  COPY INDD=INPUT,OUTDD=OUTPUT                                          
  SELECT MEMBER=((MEMBER1,,R),(MEMBER3,,R))                             
/*                                                                      
//**********************************************************************
//* BYPASSED THIS STEP IF STEP040 RETURNED CODE NOT EQUAL 0            *
//* IEBCOPY COMPRESS SRCLIB IN PLACE - RECLAIMS SPACE FROM DELETED     *
//* OR REPLACED MEMBERS. INDD=OUTDD=SYSUT1 = COMPRESS IN-PLACE SYNTAX  *
//* R IS REQUIRED - EACH MEMBER ALREADY EXISTS IN THE SAME DATASET     *
//**********************************************************************
//STEP050  EXEC PGM=IEBCOPY,COND=(00,NE,STEP040)                        
//SYSPRINT DD SYSOUT=*                                                  
//SYSUT1   DD DSN=Z73460.TASK21.JCL.SRCLIB,DISP=SHR                 
//SYSIN    DD *                                                         
  COPY INDD=SYSUT1,OUTDD=SYSUT1                                         
/*                                                                      
//
