//TASK22   JOB (888),'IEBUPDATE',CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1),     
//             NOTIFY=&SYSUID                                           
//**********************************************************************
//* TASK22: PDS MAINTENANCE VIA IEBUPDTE - ADDING AND CHANGING MEMBERS *
//* STEP010 - DELETE UPDLIB IF THET EXISTS (RC=8 IS NORMAL)            *
//* STEP020 - CREATE NEW PDS LIBRARY VIA IEFBR14                       *
//* STEP030 - EXECUTE IEBUPDTE PARM=NEW TO ADD EMPDATA & SALDATA       *
//* STEP040 - EXECUTE IEBUPDTE PARM=MOD TO UPDATE EMPDATA MEMBER       *
//* STEP050 - PRINT UPDATED EMPDATA VIA IEBGENER TO SYSOUT             *
//**********************************************************************
//**********************************************************************
//* DELETE UPDLIB IF IT ALREADY EXISTS                                 *
//* NONVSAM SCRATCH PURGE - PHYSICAL REMOVE FROM VTOC                  *
//* RC=8 = DATASET NOT FOUND - ACCEPTABLE, RESET MAXCC TO 0            *
//**********************************************************************
//STEP010  EXEC PGM=IDCAMS                                              
//SYSPRINT DD SYSOUT=*                                                  
//SYSIN    DD *                                                         
  DELETE Z73460.TASK22.HLQ.UPDLIB.JCL NONVSAM SCRATCH PURGE             
  IF MAXCC <=8 THEN SET MAXCC = 0                                       
/*                                                                      
//**********************************************************************
//* BYPASSED THIS STEP IF STEP010 RC > 8                               *
//* CREATE ONE EMPTY PDS LIBRARY VIA IEFBR14                           *
//* SPACE=(TRK,(2,2,10)):                                              *
//*   2  - PRIMARY   2 TRACKS ALLOCATED IMMEDIATELY                    *
//*   2  - SECONDARY 2 TRACKS ADDED WHEN PRIMARY IS EXHAUSTED          *
//*   10 - DIRECTORY 10 BLOCKS (~6 MEMBERS PER BLOCK)                  *
//**********************************************************************
//STEP020  EXEC PGM=IEFBR14,COND=(08,LT,STEP010)                                            
//CRTPDS   DD DSN=Z73460.TASK22.HLQ.UPDLIB.JCL,                         
//            DISP=(NEW,CATLG,DELETE),                                  
//            UNIT=SYSDA,                                               
//            SPACE=(TRK,(2,2,10)),                                     
//            DCB=(RECFM=FB,DSORG=PO,LRECL=80,BLKSIZE=3200)             
//**********************************************************************
//* BYPASSED THIS STEP IF STEP020 RETURNED CODE NOT EQUAL 0            *
//* IEBUPDTE PARM=NEW - INPUT IS SYSIN ONLY (SYSUT1=DUMMY)             *
//* CREATES TWO NEW PDS MEMBERS                                        *
//* NUMBER CONTROL - ASSIGNS SEQUENCE NUMBERS 10,20,30...              *
//**********************************************************************
//STEP030  EXEC PGM=IEBUPDTE,COND=(00,NE,STEP020),PARM=NEW              
//SYSPRINT DD SYSOUT=*                                                  
//SYSUT1   DD DUMMY                                                     
//SYSUT2   DD DSN=Z73460.TASK22.HLQ.UPDLIB.JCL,DISP=OLD                 
//SYSIN    DD DATA                                                      
./ ADD NAME=EMPDATA                                                     
./ NUMBER NEW1=00000010,INCR=00000010                                   
001IVANOV    DEVELOPER 005000                                           
002PETROV    ANALYST   003200                                           
003SIDOROV   MANAGER   007800                                           
004KOZLOV    DEVELOPER 004500                                           
005MOROZOV   ANALYST   002900                                           
./ ADD NAME=SALDATA                                                     
./ NUMBER NEW1=00000010,INCR=00000010                                   
001005000RUB                                                            
002003200RUB                                                            
003007800RUB                                                            
004004500RUB                                                            
005002900RUB                                                            
./ ENDUP                                                                
/*                                                                      
//**********************************************************************
//* BYPASSED THIS STEP IF STEP030 RETURNED CODE NOT EQUAL 0            *
//* IEBUPDTE PARM=MOD - UPDATES EXISTING MEMBER IN PDS                 *
//* SYSUT1=SYSUT2=SAME DATASET - IN-PLACE UPDATE                       *
//* ./ CHANGE NAME=EMPDATA - SWITCH TO THIS MEMBER FOR EDITING         *
//* ./ DELETE SEQ1=20,SEQ2=20 - REMOVE SEQUENCE LINE 20 (PETROV)       *
//* NEW RECORDS NOVIKOV AND POPOV APPENDED AFTER LAST EXISTING LINE    *
//**********************************************************************
//STEP040  EXEC PGM=IEBUPDTE,COND=(00,NE,STEP030),PARM=MOD              
//SYSPRINT DD SYSOUT=*                                                  
//SYSUT1   DD DSN=Z73460.TASK22.HLQ.UPDLIB.JCL,DISP=SHR                 
//SYSUT2   DD DSN=Z73460.TASK22.HLQ.UPDLIB.JCL,DISP=OLD                 
//SYSIN    DD DATA                                                      
./ CHANGE NAME=EMPDATA                                                  
./ DELETE SEQ1=00000020,SEQ2=00000020                                   
006NOVIKOV   DEVELOPER 006100                                           
007POPOV     MANAGER   008200                                           
./ ENDUP                                                                
/*                                                                      
//**********************************************************************
//* BYPASSED THIS STEP IF STEP040 RETURNED CODE NOT EQUAL 0            *
//* PRINT FINAL CONTENT OF EMPDATA MEMBER TO SYSOUT FOR VERIFICATION   *
//**********************************************************************
//STEP050  EXEC PGM=IEBGENER,COND=(00,NE,STEP040)                       
//SYSPRINT DD SYSOUT=*                                                  
//SYSUT1   DD DSN=Z73460.TASK22.HLQ.UPDLIB.JCL(EMPDATA),DISP=SHR        
//SYSUT2   DD SYSOUT=*                                                  
//SYSIN    DD DUMMY                                                     
//
