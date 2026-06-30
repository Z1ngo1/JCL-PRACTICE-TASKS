//TASK9    JOB (888),'INCLUDE AND OUTREC',CLASS=A,MSGCLASS=A,           
//             MSGLEVEL=(1,1),NOTIFY=&SYSUID                            
//**********************************************************************
//* TASK9: FILTER BY POSITION AND REFORMAT EMPLOYEES RECORD            *
//* READ DATA FROM TASK7, EXTRACT ONLY MANAGERS AND BUILD NEW LAYOUT:  *
//* FIRSTNAME(10) + ' ' + SALARY(6) + 'RUB' = 20 BYTES OUTPUT          *
//**********************************************************************
//**********************************************************************
//* DELETE ALREADY EXISTING DATASETS IF THEY EXIST                     *
//* NOTE: SPACE PARAMETER USED IF DATASET DOES NOT EXIST               *
//**********************************************************************
//STEP010  EXEC PGM=IEFBR14                                             
//DELDD1   DD DSN=Z73460.TASK9.INCLOUTR.JCL,                            
//            DISP=(MOD,DELETE,DELETE),                                 
//            SPACE=(TRK,(1,0))                                         
//**********************************************************************
//* FILTER INPUT FILE BY POSITION AND REFORMAT MATCHING RECORDS        *
//* INCLUDE EXTRACTS MANAGERS, OUTREC BUILD REORDERS INTO 20 BYTE ROW  *
//**********************************************************************
//STEP020  EXEC PGM=SORT,COND=(04,LT,STEP010)                                               
//SYSPRINT DD SYSOUT=*                                                  
//SYSOUT   DD SYSOUT=*                                                  
//SORTIN   DD DSN=Z73460.TASK7.INPUT.JCL,DISP=SHR                       
//SORTOUT  DD DSN=Z73460.TASK9.INCLOUTR.JCL,                            
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(1,1),RLSE),                                   
//            DCB=(RECFM=FB,DSORG=PS,LRECL=20)                          
//SYSIN    DD *                                                         
  SORT FIELDS=COPY                                                      
  INCLUDE COND=(21,7,CH,EQ,C'MANAGER')                                  
  OUTREC BUILD=(11,10,C' ',31,6,C'RUB')                                 
/*                                                                      
