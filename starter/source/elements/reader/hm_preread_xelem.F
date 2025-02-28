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
Chd|  HM_PREREAD_XELEM              source/elements/reader/hm_preread_xelem.F
Chd|-- called by -----------
Chd|        LECTUR                        source/starter/lectur.F       
Chd|-- calls ---------------
Chd|        ANCMSG                        source/output/message/message.F
Chd|        NGR2USRN                      source/system/nintrr.F        
Chd|        GROUPDEF_MOD                  ../common_source/modules/groupdef_mod.F
Chd|        MESSAGE_MOD                   share/message_module/message_mod.F
Chd|        SUBMODEL_MOD                  share/modules1/submodel_mod.F 
Chd|====================================================================
      SUBROUTINE HM_PREREAD_XELEM(NUM,IGRNOD,LSUBMODEL)
C-----------------------------------------------
C   ROUTINE DESCRIPTION :
C   ===================
C   PRE READ /XELEM ELEMENTS USING HM_READER
C-----------------------------------------------
C   DUMMY ARGUMENTS DESCRIPTION:
C   ===================
C
C     NAME            DESCRIPTION                         
C
C     NUM             TOTAL NODE NUMBERS
C     IGRNOD          NODE GROUP ARRAY
C     LSUBMODEL       SUBMODEL STRUCTURE     
C-----------------------------------------------
C   M o d u l e s
C-----------------------------------------------
      USE MESSAGE_MOD
      USE SUBMODEL_MOD
      USE GROUPDEF_MOD
C----------------------------------------------------------
C     PREREAD XELEM ELEMENT
C----------------------------------------------------------
C-----------------------------------------------
C   I m p l i c i t   T y p e s
C-----------------------------------------------
#include      "implicit_f.inc"
C-----------------------------------------------
C   A n a l y s e   M o d u l e
C-----------------------------------------------
#include      "analyse_name.inc"
C-----------------------------------------------
C   C o m m o n   B l o c k s
C-----------------------------------------------
#include      "units_c.inc"
#include      "param_c.inc"
#include      "scr17_c.inc"
#include      "com04_c.inc"
#include      "submod_c.inc"
C-----------------------------------------------
C   D u m m y   A r g u m e n t s
C-----------------------------------------------
C INPUT ARGUMENTS
      TYPE(GROUP_),INTENT(IN)::IGRNOD(NGRNOD)
      TYPE(SUBMODEL_DATA),INTENT(IN)::LSUBMODEL(*)
C OUTPUT ARGUMENTS
      INTEGER,INTENT(OUT)::NUM
C-----------------------------------------------
C   L o c a l   V a r i a b l e s
C-----------------------------------------------
      INTEGER I,NN,IGU(NUMELX),IGS,OFF_DEF(NSUBMOD),STAT
      INTEGER, DIMENSION(:), ALLOCATABLE :: SUB_XELEM
C-----------------------------------------------
C   E x t e r n a l   F u n c t i o n s
C-----------------------------------------------
      INTEGER NGR2USRN
C=======================================================================
C--------------------------------------------------
C      HM OFFSETS IDs
C--------------------------------------------------
      DO I=1,NSUBMOD
        OFF_DEF(I) = LSUBMODEL(I)%OFF_DEF
      ENDDO
C--------------------------------------------------
C      ALLOCS & INITS
C--------------------------------------------------
      ALLOCATE (SUB_XELEM(NUMELX),STAT=stat)
      IF (STAT /= 0) CALL ANCMSG(MSGID=268,ANMODE=ANINFO,
     .                             MSGTYPE=MSGERROR,
     .                             C1='SUB_XELEM') 
      SUB_XELEM(1:NUMELX) = 0
C--------------------------------------------------
      NUM  = 0
      CALL CPP_XELEM_PREREAD(IGU,SUB_XELEM)
C--------------------------------------------------
C      SUBMODEL OFFSET
C--------------------------------------------------
      DO I=1,NUMELX
C--------------------------------------------------
C      SUBMODEL OFFSET
C--------------------------------------------------
        IF(SUB_XELEM(I) .NE. 0)THEN
          IF(IGU(I) .NE. 0) IGU(I) = IGU(I) + OFF_DEF(SUB_XELEM(I)) 
        ENDIF
      ENDDO
C--------------------------------------------------
      DO I=1,NUMELX
        IGS = NGR2USRN(IGU(I),IGRNOD,NGRNOD,NN)
        NUM = NUM + NN
      ENDDO
C-------------------------------------
      RETURN
      END
