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
Chd|  R2R_VOID                      source/coupling/rad2rad/r2r_void.F
Chd|-- called by -----------
Chd|        LECTUR                        source/starter/lectur.F       
Chd|-- calls ---------------
Chd|        ANCMSG                        source/output/message/message.F
Chd|        FREERR                        source/starter/freform.F      
Chd|        FRETITL                       source/starter/freform.F      
Chd|        INIT_MAT_WEIGHT               source/user_interface/set_dd_mat_weight.F
Chd|        DDWEIGHTS_MOD                 share/modules1/ddweights_mod.F
Chd|        MESSAGE_MOD                   share/message_module/message_mod.F
Chd|        R2R_MOD                       share/modules1/r2r_mod.F      
Chd|        RESTMOD                       share/modules1/restart_mod.F  
Chd|====================================================================
      SUBROUTINE R2R_VOID(IPARTL)
C-----------------------------------------------
C   M o d u l e s
C-----------------------------------------------
      USE RESTMOD
      USE R2R_MOD
      USE MESSAGE_MOD
      USE DDWEIGHTS_MOD
C-----------------------------------------------
C   I m p l i c i t   T y p e s
C-----------------------------------------------
#include      "implicit_f.inc"
C-----------------------------------------------
C   A n a l y s e   M o d u l e
C-----------------------------------------------
C-----------------------------------------------
C   C o m m o n   B l o c k s
C-----------------------------------------------
#include      "com01_c.inc"
#include      "com04_c.inc"
#include      "units_c.inc"
#include      "warn_c.inc"
#include      "scr03_c.inc"
#include      "scr17_c.inc"
#include      "param_c.inc"
#include      "r2r_c.inc"
C-----------------------------------------------
C   D u m m y   A r g u m e n t s
C-----------------------------------------------
      INTEGER IPARTL(LIPART1,*)   
C-----------------------------------------------
C   L o c a l   V a r i a b l e s
C-----------------------------------------------
      INTEGER STAT,I,J,LEN1,LEN2,NUM,LL,P,N,ANA,
     .        MAT_ID,K,ADD,COMPT,NB_PART,F2,IGTYP,L      
      INTEGER, DIMENSION(:,:), ALLOCATABLE :: IPM_TEMP,IGEO_TEMP
      CHARACTER TITR*nchartitle
      my_real
     .    ALPHAI
      my_real
     .       , DIMENSION(:,:), ALLOCATABLE :: PM_TEMP,GEO_TEMP
      my_real
     .       , DIMENSION(:,:,:), ALLOCATABLE :: DDW_TEMP      
C-----------------------------------------------          

      NUMMAT0 = NUMMAT
      NUMGEO0 = NUMGEO

C---------Remplissage de PM_R2R--------------------------------C
      ALLOCATE (PM_R2R(NUMMAT+NPART+1),STAT=stat)      
      IF (STAT /= 0) CALL ANCMSG(MSGID=268,ANMODE=ANINFO,
     .                           MSGTYPE=MSGERROR,
     .                         C1='PM_R2R')
      DO I=1,NUMMAT
        PM_R2R(I) = PM(NPROPM*(I-1)+20)      
      END DO
      
      IF (IPID.EQ.0) NSUBDOM = 1

C---------Pr   tag des parts externes----------------------------C

      DO P=1,NSUBDOM
        N = P
        IF (IPID.EQ.0) N = IDDOM
        ADD = ISUBDOM(3,N)
	DO K=1,NPART
          DO I=1,ISUBDOM(1,N)        
             IF(K == ISUBDOM_PART(I+ADD)) THEN
                TAG_PART(K)=1		  		  
             ENDIF
          ENDDO	   	
        END DO	         	
      END DO
      
      IF (IPID.EQ.0) THEN
      DO P=1,NPART
        IF (TAG_PART(P)==1) THEN
	   TAG_PART(P)=0
	ELSE   
	   TAG_PART(P)=1        	   
	ENDIF
      END DO
      ENDIF
      		 
C--------------------------------------------------------------C     
		 
      COMPT = 0
      
      DO K=1,NPART
        IPART_R2R(1,K) = IPARTL(1,K)
        IPART_R2R(2,K) = IPARTL(5,K)
        IPART_R2R(3,K) = 0		     
        IF (TAG_PART(K).EQ.1) THEN
	  COMPT=COMPT+1
          IGTYP = IGEO(NPROPGI*(IPARTL(2,K)-1)+11)
          IF ((IGTYP.EQ.11).OR.(IGTYP.EQ.16)) THEN
C-- Multilayer shells
             TAG_PART(K) = 2
          ENDIF
	ENDIF
      END DO
      
      IF (COMPT.EQ.0) GOTO 150

      WRITE(IOUT,1200)
      
C--------------------------------------------------------------C      
C--------------------------------------------------------------C
C--------------------------------------------------------------C
C--------------------------------------------------------------C      
C--------------------------------------------------------------C
C--------------------------------------------------------------C
      
C---------Allocation des tableaux temporaires------------------C
      
      NB_PART = COMPT    
      
      ALLOCATE (IPM_TEMP(NPROPMI,NUMMAT+NB_PART),STAT=stat)
      IF (STAT /= 0) CALL ANCMSG(MSGID=268,ANMODE=ANINFO,
     .                           MSGTYPE=MSGERROR,
     .                         C1='IPM_TEMP')   
      ALLOCATE (PM_TEMP(NPROPM,NUMMAT+NB_PART),STAT=stat)
      IF (STAT /= 0) CALL ANCMSG(MSGID=268,ANMODE=ANINFO,
     .                           MSGTYPE=MSGERROR,
     .                         C1='PM_TEMP')      
      ALLOCATE (DDW_TEMP(2,2,NUMMAT+NB_PART+1),STAT=stat)
      IF (STAT /= 0) CALL ANCMSG(MSGID=268,ANMODE=ANINFO,
     .                           MSGTYPE=MSGERROR,
     .                         C1='DDW_TEMP')
  
      IPM_TEMP(:,:)=0
      PM_TEMP(:,:)=0
      DDW_TEMP(:,:,:)=0
      
C---------Transfert tableau mat dans tableau temporaire--------C

      DO I=1,NUMMAT
        DO J=1,NPROPMI
          IPM_TEMP(J,I)=IPM(NPROPMI*(I-1)+J)	 
        END DO
      END DO
      
      DO I=1,NUMMAT
        DO J=1,NPROPM
          PM_TEMP(J,I)=PM(NPROPM*(I-1)+J)	 
        END DO     
      END DO 

      DO I=1,NUMMAT
        DO J=1,2
          DO L=1,2
            DDW_TEMP(J,L,I)=DDWEIGHTS(J,L,I)
          ENDDO	 
        END DO     
      END DO
C
      DO J=1,2
        DO L=1,2
          DDW_TEMP(J,L,NUMMAT+NB_PART+1)=DDWEIGHTS(J,L,NUMMAT+1)
        ENDDO	 
      END DO      

C--------------- offset numero user des futurs mate void-------C
      NUM = 0
      DO I=1,NUMMAT
        IF (NUM.LE.IPM_TEMP(1,I)) NUM=IPM_TEMP(1,I)
      END DO

C---------------Creation des nouveaux materiaux VOID--------------C

      DO K=1,NPART      
        IF (TAG_PART(K).GE.1) THEN

          NUM = NUM+1
          NUMMAT = NUMMAT+1

          IF (TAG_PART(K).EQ.1) THEN
C--> standard elements 
            F2 = IPARTL(1,K)         
            PM_TEMP(1,NUMMAT)= 1e-20	  
            PM_TEMP(19,NUMMAT) =ZERO	  	  		
            PM_TEMP(20,NUMMAT) = PM_TEMP(20,F2)
            PM_R2R(NUMMAT)= PM_TEMP(20,F2)	       	
            PM_TEMP(21,NUMMAT) = PM_TEMP(21,F2)
            PM_TEMP(32,NUMMAT) = PM_TEMP(32,F2)
            PM_TEMP(70,NUMMAT) =ZERO
            PM_TEMP(71,NUMMAT) =ZERO
            PM_TEMP(72,NUMMAT) =ZERO
            PM_TEMP(75,NUMMAT) = PM_TEMP(75,F2)
            PM_TEMP(76,NUMMAT) = PM_TEMP(76,F2)           
            PM_TEMP(89,NUMMAT) = PM_TEMP(1,NUMMAT)
            PM_TEMP(100,NUMMAT) = PM_TEMP(100,F2)
C
          ELSE
C-->  Multilayer shells
            PM_TEMP(1,NUMMAT)= 1e-20	  
            PM_TEMP(19,NUMMAT) =ZERO	  	  		       	
            PM_TEMP(70,NUMMAT) =ZERO
            PM_TEMP(71,NUMMAT) =ZERO
            PM_TEMP(72,NUMMAT) =ZERO
            PM_TEMP(89,NUMMAT) = PM_TEMP(1,NUMMAT)

            DO I=1,IGEO(NPROPGI*(IPARTL(2,K)-1)+4)
              F2 = IGEO(NPROPGI*(IPARTL(2,K)-1)+100+I)
              ALPHAI = GEO(NPROPG*(IPARTL(2,K)-1)+300+I)	  		
              PM_TEMP(20,NUMMAT) = PM_TEMP(20,NUMMAT) + ALPHAI*PM_TEMP(20,F2)
              PM_R2R(NUMMAT)= PM_R2R(NUMMAT) + ALPHAI*PM_TEMP(20,F2)       	
              PM_TEMP(21,NUMMAT) = PM_TEMP(21,NUMMAT) + ALPHAI*PM_TEMP(21,F2)
              PM_TEMP(32,NUMMAT) = PM_TEMP(32,NUMMAT) + ALPHAI*PM_TEMP(32,F2)
              PM_TEMP(75,NUMMAT) = PM_TEMP(75,NUMMAT) + ALPHAI*PM_TEMP(75,F2)
              PM_TEMP(76,NUMMAT) = PM_TEMP(76,NUMMAT) + ALPHAI*PM_TEMP(76,F2)           
              PM_TEMP(100,NUMMAT) = PM_TEMP(100,NUMMAT) + ALPHAI*PM_TEMP(100,F2)        
            END DO
C
          ENDIF
C     	  	  	  	  	
          IPM_TEMP(1,NUMMAT)= NUM
          IPM_TEMP(2,NUMMAT)= 0
          TITR = "Multidomains void material"      
          CALL FRETITL(TITR,IPM_TEMP(NPROPMI-LTITR,NUMMAT),LTITR)

          WRITE(IOUT,1300) NUM,PM_TEMP(1,NUMMAT)
     .       ,PM_TEMP(20,NUMMAT),PM_TEMP(21,NUMMAT),IPARTL(4,K)
          	                                
          IPARTL(5,K)= NUM
          IPARTL(1,K)= NUMMAT
C
        ENDIF
C
      END DO
        	   
C----------------Reallocation et remplissage IPM et PM---------C 
     
      LEN1 = NPROPMI*NUMMAT
      LEN2 = NPROPM*NUMMAT
       
      DEALLOCATE(IPM,PM,DDWEIGHTS)        
      ALLOCATE (IPM(LEN1),STAT=stat)       
      IF (STAT /= 0) CALL ANCMSG(MSGID=268,ANMODE=ANINFO,
     .                           MSGTYPE=MSGERROR,
     .                         C1='IPM')           
      ALLOCATE (PM(LEN2),STAT=stat)
      IF (STAT /= 0) CALL ANCMSG(MSGID=268,ANMODE=ANINFO,
     .                           MSGTYPE=MSGERROR,
     .                         C1='PM')
      CALL INIT_MAT_WEIGHT(NUMMAT)     
      
      DO I=1,NUMMAT
       DO J=1,NPROPMI
         IPM(NPROPMI*(I-1)+J)=IPM_TEMP(J,I)
       END DO
      END DO
      
      DO I=1,NUMMAT
       DO J=1,NPROPM
         PM(NPROPM*(I-1)+J)=PM_TEMP(J,I)
       END DO
      END DO

      DO I=1,NUMMAT+1
        DO J=1,2
          DO L=1,2
            DDWEIGHTS(J,L,I)=DDW_TEMP(J,L,I)
          ENDDO	 
        END DO     
      END DO 

      DEALLOCATE(IPM_TEMP,PM_TEMP,DDW_TEMP)

C--------------------------------------------------------------C      
C--------------------------------------------------------------C
C--------------------------------------------------------------C
C--------------------------------------------------------------C      
C--------------------------------------------------------------C
C--------------------------------------------------------------C

      DO K=1,NPART      
      IF (TAG_PART(K).EQ.2) THEN
      
C---------Allocation des tableaux temporaires------------------C
      
      NB_PART = 1    
      
      ALLOCATE (IGEO_TEMP(NPROPGI,NUMGEO+NB_PART),STAT=stat)
      IF (STAT /= 0) CALL ANCMSG(MSGID=268,ANMODE=ANINFO,
     .                           MSGTYPE=MSGERROR,
     .                         C1='IGEO_TEMP')   
      ALLOCATE (GEO_TEMP(NPROPG,NUMGEO+NB_PART),STAT=stat)
      IF (STAT /= 0) CALL ANCMSG(MSGID=268,ANMODE=ANINFO,
     .                           MSGTYPE=MSGERROR,
     .                         C1='GEO_TEMP')      

      IGEO_TEMP(:,:)=0
      GEO_TEMP(:,:)=0
      
C---------Transfert tableau prop dans tableau temporaire-------C

      DO I=1,NUMGEO
        DO J=1,NPROPGI
          IGEO_TEMP(J,I)=IGEO(NPROPGI*(I-1)+J)	 
        END DO
      END DO
      
      DO I=1,NUMGEO
        DO J=1,NPROPG
          GEO_TEMP(J,I)=GEO(NPROPG*(I-1)+J)	 
        END DO     
      END DO 

C----------- offset numero user des futurs prop shell ---------C
      NUM = 0
      DO I=1,NUMGEO
        IF (NUM.LE.IGEO_TEMP(1,I)) NUM=IGEO_TEMP(1,I)+1
      END DO

C-----------------Creation de la prop shell VOID---------------C

      F2 = IPARTL(2,K)
      NUMGEO = NUMGEO+1

      IGEO_TEMP(1,NUMGEO)=NUM         
      GEO_TEMP(1,NUMGEO)=GEO_TEMP(1,F2)

      TITR = "Multidomains void property"      
      CALL FRETITL(TITR,IGEO_TEMP(NPROPGI-LTITR,NUMGEO),LTITR)

      WRITE(IOUT,1400) NUM,GEO_TEMP(1,NUMGEO),IPARTL(4,K)
          
C---------------Affectation de la property shell---------------C	                                
      IPARTL(6,K)= NUM
      IPARTL(2,K)= NUMGEO
        	   
C----------------Reallocation et remplissage IPM et PM---------C 
     
      LEN1 = NPROPGI*NUMGEO
      LEN2 = NPROPG*NUMGEO
       
      DEALLOCATE(IGEO,GEO)        
      ALLOCATE (IGEO(LEN1),STAT=stat)       
      IF (STAT /= 0) CALL ANCMSG(MSGID=268,ANMODE=ANINFO,
     .                           MSGTYPE=MSGERROR,
     .                         C1='IGEO')           
      ALLOCATE (GEO(LEN2),STAT=stat)
      IF (STAT /= 0) CALL ANCMSG(MSGID=268,ANMODE=ANINFO,
     .                           MSGTYPE=MSGERROR,
     .                         C1='GEO')     
      
      DO I=1,NUMGEO
       DO J=1,NPROPGI
         IGEO(NPROPGI*(I-1)+J)=IGEO_TEMP(J,I)
       END DO
      END DO
      
      DO I=1,NUMGEO
       DO J=1,NPROPG
         GEO(NPROPG*(I-1)+J)=GEO_TEMP(J,I)
       END DO
      END DO

      DEALLOCATE(IGEO_TEMP,GEO_TEMP)

      ENDIF	
      END DO
      
C--------------------------------------------------------------C      
C--------------------------------------------------------------C
C--------------------------------------------------------------C      
C--------------------------------------------------------------C      
C--------------------------------------------------------------C
C--------------------------------------------------------------C
         
C--------------------------------------------------------------C
      TAG_PART(:)= 0
C--------------------------------------------------------------C

150   CONTINUE
 
      RETURN
 1200 FORMAT(
     . //'      MULTIDOMAINS SPECIAL TREATMENTS '/
     . '      --------------------------------- '/)    
 1300 FORMAT(
     & 5X,40HVOID MATERIAL CREATED                   ,/,
     & 5X,40H  -----------                           ,/,     
     & 5X,40HMATERIAL ID . . . .  . . . . . . . .  .=,I10/,      
     & 5X,40HDENSITY . . . .  . . . . . . . .  . . .=,E12.4/,
     & 5X,40HYOUNG'S MODULUS . . . . . . . . . . . .=,E12.4/,
     & 5X,40HPOISSON'S RATIO . . . . . . . . . . . .=,E12.4/,
     & 5X,40HAPPLIED ON PART . . . .  . . . . . . . =,I10//)
 1400 FORMAT(
     & 5X,40HVOID PROPERTY CREATED                   ,/,
     & 5X,40H  -----------                           ,/,     
     & 5X,40HPROPERTY ID . . . .  . . . . . . . .  .=,I10/,
     & 5X,40HTHICKNESS. . . . . . . . . . . . . .  .=,E12.4/,      
     & 5X,40HAPPLIED ON PART . . . .  . . . . . . . =,I10//)           
 999  CALL FREERR(3)
C-----------
      RETURN
      END

Chd|====================================================================
Chd|  R2R_VOID_1D                   source/coupling/rad2rad/r2r_void.F
Chd|-- called by -----------
Chd|        TAG_ELEM_VOID_R2R_LIN         source/coupling/rad2rad/tagelem_r2r.F
Chd|-- calls ---------------
Chd|        R2R_MOD                       share/modules1/r2r_mod.F      
Chd|        RESTMOD                       share/modules1/restart_mod.F  
Chd|====================================================================
      SUBROUTINE R2R_VOID_1D(ID_PART,IPARTL)
C-----------------------------------------------
C   M o d u l e s
C-----------------------------------------------
      USE RESTMOD
      USE R2R_MOD
C-----------------------------------------------
C   I m p l i c i t   T y p e s
C-----------------------------------------------
#include      "implicit_f.inc"
C-----------------------------------------------
C   A n a l y s e   M o d u l e
C-----------------------------------------------
C-----------------------------------------------
C   C o m m o n   B l o c k s
C-----------------------------------------------
#include      "com01_c.inc"
#include      "com04_c.inc"
#include      "units_c.inc"
#include      "warn_c.inc"
#include      "scr03_c.inc"
#include      "scr17_c.inc"
#include      "param_c.inc"
#include      "r2r_c.inc"
C-----------------------------------------------
C   D u m m y   A r g u m e n t s
C-----------------------------------------------
      INTEGER ID_PART,IPARTL(LIPART1,*)   
C-----------------------------------------------
C   L o c a l   V a r i a b l e s
C-----------------------------------------------
      INTEGER IMAT,IMAT0,J
C-----------------------------------------------
      
      IMAT = IPARTL(1,ID_PART)
      
C---------------Si part deja traitee ou mat non void on saute---C      
      IF (IPART_R2R(3,ID_PART).EQ.1) GOTO 150
      IF (IPM(NPROPMI*(IMAT-1)+2).NE.0) GOTO 150
        
C---------------On recupere l'id du materiau original-----------C      
      IMAT0 = IPART_R2R(1,ID_PART)
            
C---------------On remplace le mat void par un mat bidon--------C      
      DO J=1,NPROPM
         PM(NPROPM*(IMAT-1)+J)=PM(NPROPM*(IMAT0-1)+J)
      END DO          
      DO J=1,NPROPMI
         IPM(NPROPMI*(IMAT-1)+J)=IPM(NPROPMI*(IMAT0-1)+J)
      END DO
       	 
      PM(NPROPM*(IMAT-1)+1)= 1e-20
      PM(NPROPM*(IMAT-1)+19)= PM(NPROPM*(IMAT0-1)+19)    	 	 
      PM(NPROPM*(IMAT-1)+20)= 1e-20
      PM(NPROPM*(IMAT-1)+70)= ZERO
      PM(NPROPM*(IMAT-1)+71)= ZERO
      PM(NPROPM*(IMAT-1)+72)= ZERO                  
      PM(NPROPM*(IMAT-1)+89)= 1e-20
      PM_R2R(IMAT)= PM(NPROPM*(IMAT0-1)+20)
      IPART_R2R(3,ID_PART) = 1

150   CONTINUE
                        
C-----------
      RETURN
      END
