!/===========================================================================/
! Copyright (c) 2007, The University of Massachusetts Dartmouth 
! Produced at the School of Marine Science & Technology 
! Marine Ecosystem Dynamics Modeling group
! All rights reserved.
!
! FVCOM has been developed by the joint UMASSD-WHOI research team. For 
! details of authorship and attribution of credit please see the FVCOM
! technical manual or contact the MEDM group.
!
! 
! This file is part of FVCOM. For details, see http://fvcom.smast.umassd.edu 
! The full copyright notice is contained in the file COPYRIGHT located in the 
! root directory of the FVCOM code. This original header must be maintained
! in all distributed versions.
!
! THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
! AND ANY EXPRESS OR  IMPLIED WARRANTIES, INCLUDING,  BUT NOT  LIMITED TO,
! THE IMPLIED WARRANTIES OF MERCHANTABILITY AND  FITNESS FOR A PARTICULAR
! PURPOSE ARE DISCLAIMED.  
!
!/---------------------------------------------------------------------------/
! CVS VERSION INFORMATION
! $Id$
! $Name$
! $Revision$
!/===========================================================================/

SUBROUTINE GRID_METRICS
  USE MOD_PAR
  USE MOD_OBCS
  USE ALL_VARS
  USE MOD_NORTHPOLE
  USE MOD_SETUP
  USE MOD_STATION_TIMESERIES
  USE MOD_NESTING, ONLY: NESTING_ON

# if defined (THIN_DAM)
  USE MOD_DAM
# endif

  IMPLICIT NONE
  
  INTEGER:: STATUS
  INTEGER:: I

  ! THESE SUBROUTINES SHOULD BE FURTHER BROKEN DOWN INTO THEIR
  ! COMPONENT OPERATIONS AND THE WHOLE THING SHOULD BE MODULAR
  
  
!============================================
!Set up fluxes and control Volumes
!============================================
  CALL TRIANGLE_GRID_EDGE
  IF(OUT_STATION_TIMESERIES_ON)CALL TRIANGLE_GRID_EDGE_GL    
!============================================
!Calculate Element and Control Volume Areas
!============================================
  CALL CELL_AREA            


!====================================================
! Calculate Shape Coefficients for Flux Construction
!====================================================
# if defined (GCN)
  CALL SHAPE_COEF_GCN       
# else
  CALL SHAPE_COEF_GCY  
# endif

#  if defined (SPHERICAL)
  CALL FIND_NORTHPOLE
  CALL SHAPE_COEF_XY 
  CALL FIND_CELLSIDE
#  endif

!============================================
!Calculate Node Control Volume Edge Lengths
!============================================
  CALL EDGE_LEN

!============================================ mdeb 11/26/2019
! PORO ----> reading the original bottom elevation to estimate the slot height
! for realistic BH case, only the depression elevations were kept as it is, other
! elevations are predefined to zero to make zstar count only at the depressions 
!============================================

! SLOT HEIGHT ----> ZSTAR
  
   DO I = 1,M  
  	 IF (PORO(I) .GE. 0.0_SP) THEN          ! In open water, there are no slots
	    ZSTAR(I) = 0.0_SP
	 ELSE
	    ZSTAR(I) = (ABS(PORO(I)) - ABS(H(I)))/(1.0_SP-SLOT_DELTA) ! for real case case, slot height: difference betw berm height and flat bottom

		 IF (ZSTAR(I) < 0.0_SP) THEN
				ZSTAR(I) = 0.0_SP
		 END IF
	 END IF
   END DO
        
   CALL N2E2D(ZSTAR,ZSTAR_E)
   CALL N2E2D(PORO,PORO_E)

!====================================================
!  EXCHANGE SHAPE FACTOR INFORMATION
!====================================================
# if defined (MULTIPROCESSOR)
  IF(PAR)CALL AEXCHANGE(EC,MYID,NPROCS,A1U,A2U) 
  IF(PAR)CALL AEXCHANGE(EC,MYID,NPROCS,AWX,AWY,AW0) 
  IF(PAR)CALL AEXCHANGE(EC,MYID,NPROCS,ALPHA) 
  IF(PAR)CALL AEXCHANGE(EC,MYID,NPROCS,ART)
  ! mdeb 02/03/2019
  IF(PAR)CALL AEXCHANGE(EC,MYID,NPROCS,ZSTAR_E)
  IF(PAR)CALL AEXCHANGE(EC,MYID,NPROCS,PORO_E)

  ! THESE MUST BE SET CORRECTLY IN THE HALO FOR OUTPUT!
  IF(PAR)CALL AEXCHANGE(NC,MYID,NPROCS,ART1,ART2)
  IF(PAR)CALL AEXCHANGE(NC,MYID,NPROCS,NTSN,NTVE)
  ! mdeb 02/03/2019
  IF(PAR)CALL AEXCHANGE(NC,MYID,NPROCS,ZSTAR)
  IF(PAR)CALL AEXCHANGE(NC,MYID,NPROCS,PORO)
# endif

!====================================================
! Calculate the horizontal gradient of the bathymetry
!====================================================
 CALL DEPTH_GRADIENT


!====================================================
! SETUP BOUNDARY NEIGHBORS AND SUCH
!====================================================
  CALL SETUP_OBC
# if defined (SEMI_IMPLICIT)
  IF(NESTING_ON) THEN
    DO I=1,IOBCN
      ISONB(NEXT_OBC(I)) = 3
    END DO
  ENDIF
# endif

!-------------------Read dam info--------------------
# if defined (THIN_DAM)
  CALL READ_DAM    
!====================================================
! Calculate Shape Coefficients for Thin Dam
!====================================================
  CALL SHAPE_COEF_DAM   

# endif

!====================================================
! SETUP THE LONGSHORE FLOW INDEX AND ANGLES
!====================================================
  IF(OBC_LONGSHORE_FLOW_ON) CALL longshore_flow

END SUBROUTINE GRID_METRICS

