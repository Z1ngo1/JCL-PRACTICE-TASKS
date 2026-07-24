//TASK8    JOB (888),'SWAP DATA',CLASS=A,MSGCLASS=A,MSGLEVEL=(1,1),     
//             NOTIFY=&SYSUID                                           
//**********************************************************************
//* TASK8: REFORMAT AND SWAP FIELDS USING SORT OUTREC BUILD            *
//* READ DATASET FROM TASK7, THEN REORDER FIELDS INTO NEW LAYOUT:      *
//* SALARY(6) + '|' + LASTNAME(10) + '|' + POSITION(10) = 28 BYTES     *
//**********************************************************************
//**********************************************************************
//* DELETE ALREADY EXISTING DATASETS IF THEY EXIST                     *
//* NOTE: SPACE PARAMETER USED IF DATASET DOES NOT EXIST               *
//**********************************************************************
//STEP010  EXEC PGM=IEFBR14                                             
//DELDD1   DD DSN=Z73460.TASK8.JCL.SWAP,                                
//            DISP=(MOD,DELETE,DELETE),                                 
//            SPACE=(TRK,(1,0))                                         
//**********************************************************************
//* BYPASSED THIS STEP IF STEP010 RC > 4                               *
//* REFORMAT RECORDS USING OUTREC BUILD TO REORDER THE FIELDS          *
//* OUTPUT RECORD LENGTH = 6 + 1 + 10 + 1 + 10 = 28 BYTES              *
//**********************************************************************
//STEP020  EXEC PGM=SORT,COND=(04,LT,STEP010)                                                
//SYSPRINT DD SYSOUT=*                                                  
//SYSOUT   DD SYSOUT=*                                                  
//SORTIN   DD DSN=Z73460.TASK7.JCL.INPUT,DISP=SHR                       
//SORTOUT  DD DSN=Z73460.TASK8.JCL.SWAP,                                
//            DISP=(NEW,CATLG,DELETE),                                  
//            SPACE=(TRK,(1,1),RLSE),                                   
//            DCB=(RECFM=FB,DSORG=PS,LRECL=28)                          
//SYSIN    DD *                                                         
  SORT FIELDS=COPY                                                      
  OUTREC BUILD=(31,6,C'|',1,10,C'|',21,10)                              
/*                                                                      
//
