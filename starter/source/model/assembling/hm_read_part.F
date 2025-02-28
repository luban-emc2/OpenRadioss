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
Chd|  HM_READ_PART                  source/model/assembling/hm_read_part.F
Chd|-- called by -----------
Chd|        LECTUR                        source/starter/lectur.F       
Chd|-- calls ---------------
Chd|        ANCMSG                        source/output/message/message.F
Chd|        FREERR                        source/starter/freform.F      
Chd|        FRETITL                       source/starter/freform.F      
Chd|        FRETITL2                      source/starter/freform.F      
Chd|        HM_GET_FLOATV                 source/devtools/hm_reader/hm_get_floatv.F
Chd|        HM_GET_INTV                   source/devtools/hm_reader/hm_get_intv.F
Chd|        HM_OPTION_READ_KEY            source/devtools/hm_reader/hm_option_read_key.F
Chd|        HM_OPTION_START               source/devtools/hm_reader/hm_option_start.F
Chd|        UDOUBLE                       source/system/sysfus.F        
Chd|        GET_U_GEO                     source/user_interface/uaccess.F
Chd|        NINTRI                        source/system/nintrr.F        
Chd|        HM_OPTION_READ_MOD            share/modules1/hm_option_read_mod.F
Chd|        MESSAGE_MOD                   share/message_module/message_mod.F
Chd|        MULTI_FVM_MOD                 ../common_source/modules/multi_fvm_mod.F
Chd|        SUBMODEL_MOD                  share/modules1/submodel_mod.F 
Chd|====================================================================
      SUBROUTINE HM_READ_PART(IPART,PM,GEO,IPM,IGEO,IWA,THK_PART,
     .           UNITAB,LSUBMODEL,MULTI_FVM)
C-----------------------------------------------
C   ROUTINE DESCRIPTION :
C   ===================
C   READ /PART USING HM_READER
C-----------------------------------------------
C   DUMMY ARGUMENTS DESCRIPTION:
C   ===================
C
C     NAME            DESCRIPTION                         
C
C     IPART           PART ARRAY 
C     PM              MATERIAL ARRAY(REAL)
C     GEO             PROPERTY ARRAY(REAL)
C     IPM             MATERIAL ARRAY(INTEGER)
C     IGEO            PROPERTY ARRAY(INTEGER)
C     THK_PART        VIRTUAL THICKNESS FOR PART ( USE BY CONTACT INTERFACES )
C     UNITAB          UNITS ARRAY
C     LSUBMODEL       SUBMODEL STRUCTURE    
C============================================================================
C-----------------------------------------------
C   M o d u l e s
C-----------------------------------------------
      USE UNITAB_MOD
      USE MESSAGE_MOD           
      USE SUBMODEL_MOD           
      USE HM_OPTION_READ_MOD
      USE MULTI_FVM_MOD
C-----------------------------------------------
C   I m p l i c i t   T y p e s
C-----------------------------------------------
#include      "implicit_f.inc"
C-----------------------------------------------
C   C o m m o n   B l o c k s
C-----------------------------------------------
#include      "scr03_c.inc"
#include      "scr17_c.inc"
#include      "units_c.inc"
#include      "com01_c.inc"
#include      "com04_c.inc"
#include      "com10_c.inc"
#include      "com_xfem1.inc"
#include      "param_c.inc"
#include      "warn_c.inc"
#include      "fluid_scr_c.inc"
#include      "submod_c.inc"
#include      "sysunit.inc"
C-----------------------------------------------
C   D u m m y   A r g u m e n t s
C-----------------------------------------------
C INPUT ARGUMENTS
      TYPE (UNIT_TYPE_),INTENT(IN) ::UNITAB 
      my_real,INTENT(IN)::GEO(NPROPG,NUMGEO)
      TYPE(SUBMODEL_DATA),INTENT(IN)::LSUBMODEL(*)
C OUTPUT ARGUMENTS
      INTEGER,INTENT(OUT)::IPART(LIPART1,*)
      INTEGER,INTENT(OUT)::IWA(*)
      my_real,INTENT(OUT)::THK_PART(*)
C MODIFIED ARGUMENT
      INTEGER,INTENT(INOUT)::IGEO(NPROPGI,NUMGEO)
      INTEGER,INTENT(INOUT)::IPM(NPROPMI,NUMMAT)
      my_real,INTENT(INOUT)::PM(NPROPM,NUMMAT)
      TYPE(MULTI_FVM_STRUCT),INTENT(INOUT)::MULTI_FVM     
C-----------------------------------------------
C   L o c a l   V a r i a b l e s
C-----------------------------------------------
      CHARACTER MESS*40
      CHARACTER*nchartitle,TITR,TITR1,TITR2,LINE1
      LOGICAL IS_AVAILABLE, USER_LAW, IS_ASSOCIATED_LAW51
      INTEGER PID,MID,SID,ID,ID1,ID2,I,IMID,IPID,ISID,K,ITH, IGTYP,XFEMFLG,
     .        IXFEM,IHBE,ILAW,UID,IFLAGUNIT,J,FLG_SPH_THERM_UPDT,IDMAT_PLY,
     .        ILAW_PLY,IPMAT,NPT,IDPARTSPH,SUB_INDEX,SIZE, IDS, CNT, 
     .        IFIX_TMP, IGFLU, JALE,JTHE,STAT
      my_real BID, THICK,FAC_L,MP,VOL,DIAM
C-----------------------------------------------
C   E x t e r n a l   F u n c t i o n s
C-----------------------------------------------
      LOGICAL LOI_FLUID
      EXTERNAL LOI_FLUID
      my_real GET_U_GEO
      EXTERNAL GET_U_GEO
      INTEGER NINTRI
      DATA MESS/' PART DEFINITION                        '/
C-----------------------------------------------
C   S o u r c e   L i n e s
C-----------------------------------------------
      IS_ASSOCIATED_LAW51 = .FALSE.
      IS_AVAILABLE = .FALSE.
      SUB_INDEX = 0
      UID = 0
      FAC_L = ONE
      XFEMFLG = 0
      IXFEM   = 0

      WRITE(IOUT,'(//A)')'       PARTS' 
      WRITE(IOUT,'(A//)')'       -----' 

      FLG_SPH_THERM_UPDT = 0
      DO I=1,NUMGEO
         IWA(I) = 0
      ENDDO
      DO I=1,NUMMAT
         IWA(NUMGEO+I) = 0
      ENDDO
C--------------------------------------------------
C START BROWSING MODEL PARTS
C--------------------------------------------------
      CALL HM_OPTION_START('PART')
C--------------------------------------------------
C BROWSING MODEL PARTS 1->NPART
C--------------------------------------------------
      DO I=1,NPART
        TITR = ''
C--------------------------------------------------
C EXTRACT DATAS OF /PART/... LINE
C--------------------------------------------------
        CALL HM_OPTION_READ_KEY(LSUBMODEL,
     .                       OPTION_ID = ID,
     .                       UNIT_ID = UID,
     .                       SUBMODEL_INDEX = SUB_INDEX,
     .                       OPTION_TITR = TITR)
C--------------------------------------------------
C EXTRACT DATAS (INTEGER VALUES)
C--------------------------------------------------
        CALL HM_GET_INTV('propertyid',PID,IS_AVAILABLE,LSUBMODEL)
        CALL HM_GET_INTV('materialid',MID,IS_AVAILABLE,LSUBMODEL)
        CALL HM_GET_INTV('subsetid',SID,IS_AVAILABLE,LSUBMODEL)
C--------------------------------------------------
C EXTRACT DATAS (REAL VALUES)
C--------------------------------------------------
        CALL HM_GET_FLOATV('THICK',THICK,IS_AVAILABLE,LSUBMODEL,UNITAB)
C--------------------------------------------------
        WRITE(IOUT,'(/A,I10,2A)')'PART:',ID,',',TRIM(TITR)
        WRITE(IOUT,'(A)')       '----'

        CALL FRETITL(TITR,IPART(LIPART1-LTITR+1,I),LTITR)

        THK_PART(I) = THICK
        IPID = NINTRI(PID,IGEO,NPROPGI,NUMGEO,1)
        IF(IPID == 0) THEN
           IPID=1
           CALL ANCMSG(MSGID=178,
     .                 MSGTYPE=MSGERROR,
     .                 ANMODE=ANINFO,
     .                 I1=ID,
     .                 C1=TITR,
     .                 I2=PID)
           TITR1=' '
        ELSE
            CALL FRETITL2(TITR1,IGEO(NPROPGI-LTITR+1,IPID),LTITR)
        ENDIF

        WRITE(IOUT,'(A,I10,2A)')'     PROPERTY:',PID,',',TRIM(TITR1)

        IGTYP=NINT(GEO(12,IPID))
        IF(IGTYP == 17 .OR. IGTYP == 51) IPART_STACK = 1
        IF(IGTYP ==  52) IPART_PCOMPP = 1
        IF( (IGTYP == 0).OR.
     .      (IGTYP == 1).OR.(IGTYP == 2).OR.(IGTYP == 3).OR.
     .      (IGTYP == 6).OR.(IGTYP == 9).OR.(IGTYP == 10).OR.
     .      (IGTYP == 11).OR.(IGTYP == 14).OR.(IGTYP == 16).OR.
     .      (IGTYP == 18).OR.(IGTYP == 20).OR.(IGTYP == 21).OR.
     .      (IGTYP == 22).OR.(IGTYP == 34).OR.(IGTYP == 11).OR.
     .      (IGTYP == 17).OR.(IGTYP == 51).OR.(IGTYP == 52).OR. 
     .      (IGTYP == 23).OR.(IGTYP == 43)) THEN
            IF(MID == 0) THEN
               CALL ANCMSG(MSGID=179,
     .                     MSGTYPE=MSGERROR,
     .                     ANMODE=ANINFO,
     .                     I1=ID,
     .                     C1=TITR,
     .                     I2=MID)
            ENDIF          
        ENDIF
        !--- check material identifier
        IF(MID == 0) THEN
         !fictious material law for spring elements
         IMID=NUMMAT
         ILAW=IPM(2,IMID)
        ELSE
         IMID = NINTRI(MID,IPM,NPROPMI,NUMMAT,1)
         IF(IMID == 0) THEN
            CALL ANCMSG(MSGID=179,
     .                  MSGTYPE=MSGERROR,
     .                  ANMODE=ANINFO,
     .                  I1=ID,
     .                  C1=TITR,
     .                  I2=MID)
           ILAW=0
         ELSE
           ILAW  = IPM(2,IMID)
           IXFEM = IPM(236,IMID)
           CALL FRETITL2(TITR2,IPM(NPROPMI-LTITR+1,IMID),LTITR)
         ENDIF
         !check if law151 is used
         IF(ILAW == 151)IS_ASSOCIATED_LAW51=.TRUE.
         !--- check property identifier
         IGTYP=0
         IF(IPID > 0) IGTYP=IGEO(11,IPID)
         IF (IXFEM > 0 .and. (IGTYP==1  .or. IGTYP==9 .or. IGTYP==10 .or. 
     .                        IGTYP==11 .or. IGTYP==51)) THEN
           XFEMFLG = XFEMFLG + IXFEM
         END IF
         IF (ILAW == 99.AND.IGTYP == 14) THEN
           IHBE=IGEO(10,IPID)
           IF (IHBE == 12) THEN
            CALL ANCMSG(MSGID=768,
     .                  MSGTYPE=MSGERROR,
     .                  ANMODE=ANINFO,
     .                  I1=ID,
     .                  C1=TITR,
     .                  I2=PID,
     .                  C2=TITR1,
     .                  I3=MID,
     .                  C3=TITR2,
     .                  C4='SOLID',
     .                  I4=IHBE)
           END IF
         END IF
         IF (ILAW==29 .or. ILAW==30 .or. ILAW==31 .or. ILAW==99) THEN
           USER_LAW = .true.
         ELSE
           USER_LAW = .false.
         ENDIF
         IF (((IGTYP==43) .and. ((ILAW/=59 .and. ILAW/=83 .and. ILAW/=116 .and. ILAW/=117 .AND. ILAW /=120) .and. 
     .       (USER_LAW .eqv. .false. ) ).eqv. .true.) .or.
     .       ((ILAW==59 .or. ILAW==83 .or. ILAW==116 .or. ILAW==117) .and. IGTYP/=43) .eqv. .true.) THEN
           CALL ANCMSG(MSGID=658,
     .                 MSGTYPE=MSGERROR,
     .                 ANMODE=ANINFO_BLIND_2,
     .                 I1=PID,
     .                 C1=TITR1,
     .                 I2=ILAW,
     .                 I3=IGTYP)
         ENDIF
         IF (ILAW == 87 .AND. IGTYP /= 9) THEN
           CALL ANCMSG(MSGID=1110,
     .                 MSGTYPE=MSGWARNING,
     .                 ANMODE=ANINFO_BLIND_1,
     .                 I1=ID,
     .                 C1=TITR,
     .                 I2=ILAW,
     .                 I3=IGTYP)
         ENDIF
         IF (ILAW == 187 .AND. IGTYP /= 6) THEN
           CALL ANCMSG(MSGID=1110,
     .                 MSGTYPE=MSGWARNING,
     .                 ANMODE=ANINFO_BLIND_1,
     .                 I1=ID,
     .                 C1=TITR,
     .                 I2=ILAW,
     .                 I3=IGTYP)
         ENDIF

         IF(ILAW == 13 .AND. IRODDL == 0) IRODDL = 1
         IF( IMID .NE. 0)
     .        WRITE(IOUT,'(A,I10,2A)')'     MATERIAL:',MID,',',TRIM(TITR2)
        ENDIF
C compatibility of global material and ply material for type11
        IF(IGTYP == 11) THEN
            NPT=IGEO(4,IPID)
            IPMAT = 100
           DO J=1,NPT
             IDMAT_PLY= IGEO(IPMAT+J,IPID)
             ILAW_PLY = IPM(2,IDMAT_PLY)
             IF(ILAW_PLY /= ILAW) THEN
                 CALL ANCMSG(MSGID=1083,
     .                  MSGTYPE=MSGERROR,
     .                  ANMODE=ANINFO,
     .                  I1=ID,
     .                  C1=TITR,
     .                  I2=PID,
     .                  C2=TITR1,
     .                  I3=MID,
     .                  C3=TITR2)
             ENDIF
           ENDDO
        ENDIF        

        IF(IGTYP == 23) THEN
           IMID = NINTRI(MID,IPM,NPROPMI,NUMMAT,1)
           ILAW=IPM(2,IMID)
           IF(ILAW /= 108 .AND. ILAW /=113.AND. ILAW /=114 .AND. ILAW /= 0 ) THEN
             CALL ANCMSG(MSGID = 1715,
     .                  MSGTYPE=MSGERROR,
     .                  ANMODE=ANINFO,
     .                  I1=ID,
     .                  C1=TITR)
           ENDIF
        ENDIF

        IF(ILAW == 70 .AND. IGEO(31,IPID) == 1) WRITE(IOUT,2000)

        !################################################################!   !(14)'SOLID'     
        !  EULERIAN AND ALE CASES : ALLOWS ONLY IGTYP=14 & IGTYP=15      !   !(14)'FLUID'
        !################################################################!   !(15)'POROUS'                
        ILAW=0
        JALE=0
        IF(IMID > 0)THEN
          ILAW=IPM(2,IMID)
          JALE=NINT(PM(72,IMID) ) 
        ENDIF
        IF(JALE > 0)THEN
           IF (ILAW  ==  151 .AND. N2D .NE. 0) THEN
C     Allow SHELL3N for 2D law 151
              IF(IGTYP.NE.14.AND.IGTYP.NE.15.AND.IGTYP.NE.1)THEN  
                 CALL ANCMSG(MSGID=42,
     .                MSGTYPE=MSGERROR,
     .                ANMODE=ANINFO,
     .                I1=ID) 
                 MID=0 
                 PM(1:NPROPM,IMID) =  ZERO
                 IPM(1:NPROPMI,IMID) = 0                  
              ENDIF
           ELSE
              IF(IGTYP.NE.14.AND.IGTYP.NE.15)THEN  
                 CALL ANCMSG(MSGID=42,
     .                MSGTYPE=MSGERROR,
     .                ANMODE=ANINFO,
     .                I1=ID) 
!material set to void for normal termination otherwise engine will set value to non allocated arrays.
                 MID=0 
                 PM(1:NPROPM,IMID) =  ZERO
                 IPM(1:NPROPMI,IMID) = 0                  
              ENDIF
           ENDIF
        ENDIF
       
        WRITE(IOUT,'(A,I10,2A)')'     SUBSET  :',SID
        WRITE(IOUT,'(A,1PG20.13,2A)')' VIRT. THICKN:',THK_PART(I)

C       SPH : special treatments
        IF (IGEO(11,IPID) == 34) THEN
          DIAM =GET_U_GEO(6,IPID)
          JTHE = NINT(PM(71,IMID))
C         SPH : printout of the smoothing length
          IF(DIAM == ZERO) THEN
            MP  = GET_U_GEO(1,IPID)
            VOL = MP/PM(1,IMID)
            DIAM= (SQR2*VOL)**THIRD
            WRITE(IOUT,'(A,1PG20.13,2A)')' SPH SMOOTHING LENGTH:',DIAM
          ENDIF
C         SPH : update of thermal flags
          IF (JTHE > 0) FLG_SPH_THERM_UPDT = 1
        ENDIF

        IPART(1,I)=IMID
        IPART(2,I)=IPID
        ISID=0
        IPART(3,I)=ISID
        IPART(4,I)=ID
        IPART(5,I)=MID
        IPART(6,I)=PID
        IPART(7,I)=SID
        ITH=0
        IPART(8,I)=ITH
        IPART(9,I)=SUB_INDEX

        IF(IPART(4,I) == 0) THEN
          CALL ANCMSG(MSGID=494,
     .                MSGTYPE=MSGERROR,
     .                ANMODE=ANINFO_BLIND_1,
     .                C1=LINE1)
        ENDIF

       !################################################################!   
       !  CFD CONSISTENCY                                               !
       !################################################################!
       ILAW=0
       IGFLU=0
       IF(IMID > 0)ILAW =IPM(2,IMID)
       IF(IPID > 0)IGFLU=IGEO(36,IPID)
       !IGTYP = IGEO(11,I)
       !### CAA without fluid material (CAA is obsolete)
       IF(ICAA.NE.0)THEN
         IF(JALE==1 .OR. JALE==2)THEN !ALE or EULER
           IF(loi_fluid(ilaw).eqv..false.) THEN
             CALL ANCMSG(MSGID=37,
     .                   MSGTYPE=MSGWARNING,
     .                   ANMODE=ANINFO_BLIND_1,
     .                   I1=ID,
     .                   C1=TITR,
     .                   I2=MID,
     .                   C2=TITR2,
     .                   I3=ILAW)
           ENDIF
         ENDIF
       ENDIF
       !### /PROP/FLUID without FLUID material 
       IF(      (IGFLU==1) 
     .    .AND. (loi_fluid(ilaw).eqv. .false.) 
     .    .AND. (ICAA == 0)
     .    .AND. (IGTYP == 14)
     .  )THEN
          CALL ANCMSG(MSGID=38,
     .                MSGTYPE=MSGERROR,
     .                ANMODE=ANINFO_BLIND_1,
     .                I1=ID,
     .                C1=TITR,
     .                I2=PID,
     .                C2=TITR1,
     .                I3=MID,
     .                C3=TITR2,
     .                I4=ILAW )
       ENDIF
      !-------------------------------------

      ENDDO ! NPART
      
      MULTI_FVM%IS_USED = IS_ASSOCIATED_LAW51
      
      IMULTI_FVM = 0
      IF (MULTI_FVM%IS_USED) THEN
         IMULTI_FVM = 1     
         IF (N2D == 0) THEN
            ALLOCATE(MULTI_FVM%VEL(3, NUMELS), STAT=stat)
         ELSE
            ALLOCATE(MULTI_FVM%VEL(3, NUMELQ + NUMELTG), STAT=stat)
         ENDIF
         IF (STAT /= 0) CALL ANCMSG(MSGID   = 268,
     .        ANMODE  = ANINFO,
     .        MSGTYPE = MSGERROR,
     .        C1      = 'MULTI_FVM%VEL')
         MULTI_FVM%VEL(: ,:) = ZERO
      ENDIF      
      
      IF (XFEMFLG == 0) ICRACK3D = 0

      DO I=1,NPART
         IWA(IPART(2,I)) = 1
         IWA(NUMGEO+IPART(1,I)) = 1
      ENDDO

      CNT = 0
      DO I=1,NUMGEO
         IF (IWA(I) ==  0) CNT = CNT+1
      ENDDO
      IDS = 52
      CNT = 0
      DO I=1,NUMMAT
         IF (IWA(NUMGEO+I) ==  0) CNT = CNT+1
      ENDDO
      IDS = 3

C     SPH : switch to fem thermal formulation - update of thermal flags
      IF (FLG_SPH_THERM_UPDT == 1) THEN
        ITHERM_FE = 0
        ITHERMC = 0
        DO I=1,NPART
          JTHE = NINT(PM(71,IPART(1,I)))
          IF (IGEO(11,IPART(2,I)) == 34) JTHE = -1*ABS(JTHE)
          IF(JTHE > 0) ITHERM=MAX(ITHERM,ABS(JTHE))
          IF(JTHE < 0) ITHERM_FE=MAX(ITHERM_FE,ABS(JTHE))
        ENDDO      
      ENDIF
      
C     SOL2SPH : Orthotropic flag transfered to SPH property
      DO I=1,NPART
        IDPARTSPH = IGEO(38,IPART(2,I))
        IF (IDPARTSPH > 0) THEN
          IGEO(17,IPART(2,IDPARTSPH)) = IGEO(17,IPART(2,I))
        ENDIF
      ENDDO
C
C-------------------------------------
C Recherche des ID doubles
C-------------------------------------
      CALL UDOUBLE(IPART(4,1),LIPART1,NPART,MESS,0,BID)

      RETURN
 999  CALL FREERR(1)
      RETURN
 2000 FORMAT(
     & 5X,'FOR LAW 70 THE DEFAULT VALUE OF Qa and Qb IS 0' )
C
      END
Chd|====================================================================
Chd|  HM_PREREAD_PART               source/model/assembling/hm_read_part.F
Chd|-- called by -----------
Chd|        CONTRL                        source/starter/contrl.F       
Chd|        LECTUR                        source/starter/lectur.F       
Chd|-- calls ---------------
Chd|        FREERR                        source/starter/freform.F      
Chd|        HM_GET_INTV                   source/devtools/hm_reader/hm_get_intv.F
Chd|        HM_OPTION_READ_KEY            source/devtools/hm_reader/hm_option_read_key.F
Chd|        HM_OPTION_START               source/devtools/hm_reader/hm_option_start.F
Chd|        NINTRI                        source/system/nintrr.F        
Chd|        HM_OPTION_READ_MOD            share/modules1/hm_option_read_mod.F
Chd|        MESSAGE_MOD                   share/message_module/message_mod.F
Chd|        SUBMODEL_MOD                  share/modules1/submodel_mod.F 
Chd|====================================================================
      SUBROUTINE HM_PREREAD_PART(IPART,IGEO,LSUBMODEL)
C============================================================================
C   M o d u l e s
C-----------------------------------------------
      USE MESSAGE_MOD       
      USE SUBMODEL_MOD
      USE HM_OPTION_READ_MOD
C-----------------------------------------------
C   I m p l i c i t   T y p e s
C-----------------------------------------------
#include      "implicit_f.inc"
C-----------------------------------------------
C   C o m m o n   B l o c k s
C-----------------------------------------------
#include      "scr03_c.inc"
#include      "scr17_c.inc"
#include      "units_c.inc"
#include      "com04_c.inc"
#include      "com10_c.inc"
#include      "param_c.inc"
#include      "warn_c.inc"
#include      "com01_c.inc"
#include      "submod_c.inc"
C-----------------------------------------------
C   D u m m y   A r g u m e n t s
C-----------------------------------------------
      INTEGER IPART(LIPART1,*),IGEO(NPROPGI,*)
C-----------------------------------------------
C   A n a l y s e   M o d u l e
C-----------------------------------------------
C-----------------------------------------------
C   L o c a l   V a r i a b l e s
C-----------------------------------------------
      INTEGER PID,ID,I,IPID,UID,SUB_INDEX
      CHARACTER MESS*40
      INTEGER  IFIX_TMP
      CHARACTER*nchartitle,
     .   TITR
      TYPE(SUBMODEL_DATA) LSUBMODEL(*)
      LOGICAL IS_AVAILABLE
C-----------------------------------------------
C   E x t e r n a l   F u n c t i o n s
C-----------------------------------------------
      INTEGER NINTRI
      DATA MESS/' PART PRE-READING                       '/
C=======================================================================
      IS_AVAILABLE = .FALSE.
      CALL HM_OPTION_START('PART')
C--------------------------------------------------
      DO I=1,NPART
        TITR = ''
        CALL HM_OPTION_READ_KEY(LSUBMODEL,
     .                       OPTION_ID = ID,
     .                       UNIT_ID = UID,
     .                       SUBMODEL_INDEX = SUB_INDEX,
     .                       OPTION_TITR = TITR)

        CALL HM_GET_INTV('propertyid',PID,IS_AVAILABLE,LSUBMODEL)
        IPID = NINTRI(PID,IGEO,NPROPGI,NUMGEO,1)

        IPART(2,I)=IPID
        IPART(4,I)=ID
        IPART(9,I)=SUB_INDEX
      ENDDO

      RETURN
 999  CALL FREERR(1)
      RETURN
						
      END
