Copyright>        OpenRadioss
Copyright>        Copyright (C) 1986-2022 Altair Engineering Inc.
Copyright>    
Copyright>        This program is free software: you can redistribute it and/or modify
Copyright>        it under the terms of the GNU Affero General Public License as published by
Copyright>        the Free Software Foundation, either version 3 of the License, or
Copyright>        (at your option) any later version.
Copyright>    
Copyright>        This program is distributed in the hope that it will be useful,
Copyright>        but WITHOUT ANY WARRANTY; without even the implied warranty of
Copyright>        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
Copyright>        GNU Affero General Public License for more details.
Copyright>    
Copyright>        You should have received a copy of the GNU Affero General Public License
Copyright>        along with this program.  If not, see <https://www.gnu.org/licenses/>.
Copyright>    
Copyright>    
Copyright>        Commercial Alternative: Altair Radioss Software 
Copyright>    
Copyright>        As an alternative to this open-source version, Altair also offers Altair Radioss 
Copyright>        software under a commercial license.  Contact Altair to discuss further if the 
Copyright>        commercial version may interest you: https://www.altair.com/radioss/.    
Chd|====================================================================
Chd|  READ_DFS_DETPOINT             source/initial_conditions/detonation/read_dfs_detpoint.F
Chd|-- called by -----------
Chd|        READ_DETONATORS               source/initial_conditions/detonation/read_detonators.F
Chd|-- calls ---------------
Chd|        ANCMSG                        source/output/message/message.F
Chd|        HM_GET_FLOATV                 source/devtools/hm_reader/hm_get_floatv.F
Chd|        HM_GET_INTV                   source/devtools/hm_reader/hm_get_intv.F
Chd|        HM_OPTION_IS_CRYPTED          source/devtools/hm_reader/hm_option_is_crypted.F
Chd|        REMOVE_DET                    source/initial_conditions/detonation/remove_det.F
Chd|        USR2SYS                       source/system/sysfus.F        
Chd|        DETONATORS_MOD                share/modules1/detonators_mod.F
Chd|        GROUPDEF_MOD                  ../common_source/modules/groupdef_mod.F
Chd|        HM_OPTION_READ_MOD            share/modules1/hm_option_read_mod.F
Chd|        MESSAGE_MOD                   share/message_module/message_mod.F
Chd|        SUBMODEL_MOD                  share/modules1/submodel_mod.F 
Chd|====================================================================
      SUBROUTINE READ_DFS_DETPOINT(DET_ID,DETONATORS,X,IGRNOD,IPM,ITABM1,UNITAB,LSUBMODEL,KEY,KEY2,I1,I2,I3,I4,I5)
C-----------------------------------------------
C   M o d u l e s
C----------------------------------------------- 
      USE UNITAB_MOD
      USE MESSAGE_MOD
      USE DETONATORS_MOD
      USE GROUPDEF_MOD
      USE HM_OPTION_READ_MOD
      USE SUBMODEL_MOD
C-----------------------------------------------
C   I m p l i c i t   T y p e s
C-----------------------------------------------
#include      "implicit_f.inc"
C-----------------------------------------------
C   C o m m o n   B l o c k s
C-----------------------------------------------
#include      "com01_c.inc"
#include      "com04_c.inc"
#include      "units_c.inc"
#include      "scr03_c.inc"
#include      "scr17_c.inc"
#include      "param_c.inc"
#include      "sysunit.inc"
#include      "tabsiz_c.inc"
#include      "submod_c.inc"
C-----------------------------------------------
C   D u m m y   A r g u m e n t s
C-----------------------------------------------
      TYPE (UNIT_TYPE_),INTENT(IN)      :: UNITAB 
      INTEGER                           :: ITABM1(SITABM1),ITAB(NUMNOD)
      INTEGER                           :: IPM(NPROPMI,NUMMAT)    
      my_real                           :: X(3,NUMNOD)
      CHARACTER*ncharkey                :: KEY, KEY2      
      TYPE(SUBMODEL_DATA),INTENT(IN)    :: LSUBMODEL(NSUBMOD)
      INTEGER            ,INTENT(INOUT) :: I1,I2,I3,I4,I5
      INTEGER,INTENT(IN)                :: DET_ID  
      TYPE(DETONATOR_STRUCT_)           :: DETONATORS          
C-----------------------------------------------
      TYPE (GROUP_)  , DIMENSION(NGRNOD)  :: IGRNOD
C-----------------------------------------------
C   L o c a l   V a r i a b l e s
C-----------------------------------------------
      INTEGER              :: I, MAT, J, NPEM,NPCM,K,IGU,IGS,JJ,MDET
      INTEGER              :: NODE_ID1, NODE_ID2,uID1,uID2
      INTEGER              :: FLAG_FMT,IMAT,IFLAGUNIT,UNUSED
      INTEGER              :: STAT
      my_real              :: XC, YC, ZC, ALT
      CHARACTER*40         :: MESS
      CHARACTER*64         :: chain1,chain2
      CHARACTER*nchartitle :: TITR
      LOGICAL              :: IS_ENCRYPTED, IS_AVAILABLE
      LOGICAL              :: IS_NODE_DEFINED
      INTEGER              :: NDETPS,NDETSG,NECRAN,NDETPL,NDETCORD
C-----------------------------------------------
C   E x t e r n a l   F u n c t i o n s
C-----------------------------------------------
      INTEGER,EXTERNAL     :: NODGRNR5, USR2SYS, NINTRI
      INTEGER              :: UNUSED_MAT_DETONATOR
      DATA MESS/'DETONATORS DEFINITION                   '/      
C-----------------------------------------------
C   S o u r c e   L i n e s
C-----------------------------------------------      
      NDETPS = DETONATORS%NDETPS
      NDETSG = DETONATORS%NDETSG
      NECRAN = DETONATORS%NECRAN
      NDETPL = DETONATORS%NDETPL
      NDETCORD = DETONATORS%NDETCORD

      IS_ENCRYPTED= .FALSE.                                                                  
      IS_AVAILABLE = .FALSE.                                                                 
      IS_NODE_DEFINED = .FALSE.                                                              
      IF(KEY2(1:4)=='NODE')IS_NODE_DEFINED = .TRUE.                                          
      CALL HM_OPTION_IS_CRYPTED(IS_ENCRYPTED)                                                                                       
      !---------------------------------!                                                    
      !             READING             !                                                    
      !---------------------------------!                                                    
      IF(IS_NODE_DEFINED)THEN                                                                
        CALL HM_GET_FLOATV('rad_det_time', ALT, IS_AVAILABLE, LSUBMODEL,UNITAB)              
        CALL HM_GET_INTV('rad_det_materialid', MAT, IS_AVAILABLE, LSUBMODEL)         
        CALL HM_GET_INTV('rad_det_node1', uID1, IS_AVAILABLE, LSUBMODEL)             
        XC=ZERO                                                                              
        YC=ZERO                                                                              
        ZC=ZERO                                                                              
      ELSE                                                                                   
        CALL HM_GET_FLOATV('rad_det_locationA_X', XC, IS_AVAILABLE, LSUBMODEL, UNITAB)       
        CALL HM_GET_FLOATV('rad_det_locationA_Y', YC, IS_AVAILABLE, LSUBMODEL, UNITAB)       
        CALL HM_GET_FLOATV('rad_det_locationA_Z', ZC, IS_AVAILABLE, LSUBMODEL, UNITAB)       
        CALL HM_GET_FLOATV('rad_det_time', ALT, IS_AVAILABLE, LSUBMODEL,UNITAB)              
        CALL HM_GET_INTV('rad_det_materialid', MAT, IS_AVAILABLE, LSUBMODEL)                 
      ENDIF                                                                                  
                                                                                             
      IF(IS_NODE_DEFINED)THEN                                                                
        NODE_ID1=USR2SYS(uID1,ITABM1,MESS,DET_ID)                                                
        IF(NODE_ID1 > 0)THEN                                                                
          XC = X(1,NODE_ID1)                                                                 
          YC = X(2,NODE_ID1)                                                                 
          ZC = X(3,NODE_ID1)                                                                 
        ENDIF                                                                                
        IF(NODE_ID1==0)THEN                                                                  
          CALL ANCMSG(MSGID   = 104,                                                         
     .                MSGTYPE = MSGERROR,                                                    
     .                ANMODE  = ANINFO,                                                      
     .                C1      = '/DFS/DETPOINT/NODE',                                        
     .                I1      = DET_ID,                                                          
     .                C2      = 'INVALID NODE_ID')                                           
        ENDIF                                                                                
      ENDIF                                                                                  
      !---------------------------------!                                                    
      !      CHECKING USER FLAGS        !                                                    
      !      +INTERNAL ID               !                                                    
      !---------------------------------!                                                    
      MDET=MAT !bak                                                                          
      IF (ALT > INFINITY) ALT=INFINITY 
      UNUSED=0                                                     
      IF(MAT > 0)UNUSED=UNUSED_MAT_DETONATOR(MAT,NUMMAT,IPM)                                
      IF (MAT < 0) THEN                                                                     
        CALL REMOVE_DET(KEY(1:7),I1,I2,I3,I4,I5,DETONATORS)      
        CALL ANCMSG(MSGID=102,                                                               
     .              MSGTYPE=MSGERROR,                                                        
     .              ANMODE=ANINFO,                                                           
     .              I1=DET_ID,                                                                   
     .              C1='DETONATOR IS REFERRING TO A NEGATIVE MATERIAL ID',                   
     .              C2='/DFS/DETPOINT',                                                      
     .              I2=MDET)                                                                 
      ELSEIF (UNUSED==1) THEN                                                                
        CALL REMOVE_DET(KEY(1:7),I1,I2,I3,I4,I5,DETONATORS)      
        CALL ANCMSG(MSGID=102,                                                               
     .              MSGTYPE=MSGERROR,                                                        
     .              ANMODE=ANINFO,                                                           
     .              I1=DET_ID,                                                                   
     .              C1='DETONATOR IS REFERRING TO AN UNKNOWN MATERIAL ID',                   
     .              C2='/DFS/DETPOINT',                                                      
     .              I2=MDET)                                                                 
      ELSEIF (UNUSED==2) THEN                                                                
        CALL REMOVE_DET(KEY(1:7),I1,I2,I3,I4,I5,DETONATORS)      
        CALL ANCMSG(MSGID=102,                                                               
     .              MSGTYPE=MSGERROR,                                                        
     .              ANMODE=ANINFO,                                                           
     .              I1=DET_ID,                                                                   
     .              C1='DETONATOR MUST REFER TO A JWL MATERIAL LAW (LAWS 5, 51, 97, 151)',          
     .              C2='/DFS/DETPOINT',                                                      
     .              I2=MDET)                                                                 
      ELSE                                                                                   
      !---------------------------------!                                                    
      !        LISTING PRINTOUT         !                                                    
      !---------------------------------!                                                    
        I1=I1+1 !one more detpoint                                                           
        IF(IS_ENCRYPTED)THEN                                                                 
          WRITE(IOUT,1001)                                                                   
        ELSEIF(IS_NODE_DEFINED)THEN                                                          
          WRITE(IOUT,1401) DET_ID,uID1,XC,YC,ZC,ALT,MDET                                         
        ELSE                                                                                 
          WRITE(IOUT,1400) DET_ID,XC,YC,ZC,ALT,MDET                                              
        ENDIF                                                                                
        DETONATORS%BURN(1,I1) = ALT                                                                        
        DETONATORS%BURN(2,I1) = MAT                                                                        
        DETONATORS%BURN(3,I1) = XC                                                                         
        DETONATORS%BURN(4,I1) = YC                                                                         
        DETONATORS%BURN(5,I1) = ZC                                                                         
        DETONATORS%BURN(6,I1) = 0 !unused                                                                  
        DETONATORS%BURN(7,I1) = 0 !unused                                                                  
        DETONATORS%BURN(8,I1) = 0 !unused                                                                  
      END IF                                                                                 

C-----------------------------------------------
C   O u t p u t   F o r m a t
C-----------------------------------------------
 1001 FORMAT(///'DETONATION POINT           ',I10,/5X,
     &          '----------------           ',/5X,
     &          'CONFIDENTIAL DATA')    
 1400 FORMAT(///'DETONATION POINT           ',I10,/5X,
     &          '----------------           ',/5X,
     &          'X-COORDINATE              =',1PG20.13,/5X,
     &          'Y-COORDINATE              =',1PG20.13,/5X,
     &          'Z-COORDINATE              =',1PG20.13,/5X,
     &          'LIGHTING TIME             =',1PG20.13,/5X,
     &          'EXPLOSIVE MATERIAL NUMBER =',I10 )
 1401 FORMAT(///'DETONATION POINT           ',I10,/5X,
     &          '----------------           ',/5X,
     &          'NODE ID                   =',I10     ,/5X,
     &          ' X-COORDINATE             =',1PG20.13,/5X,
     &          ' Y-COORDINATE             =',1PG20.13,/5X,
     &          ' Z-COORDINATE             =',1PG20.13,/5X,
     &          'LIGHTING TIME             =',1PG20.13,/5X,
     &          'EXPLOSIVE MATERIAL NUMBER =',I10 ) 
C-----------------------------------------------            
      END SUBROUTINE
