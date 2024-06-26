!-----------------------BEGIN NOTICE -- DO NOT EDIT-----------------------
! NASA Goddard Space Flight Center
! Land Information System Framework (LISF)
! Version 7.5
!
! Copyright (c) 2024 United States Government as represented by the
! Administrator of the National Aeronautics and Space Administration.
! All Rights Reserved.
!-------------------------END NOTICE -- DO NOT EDIT-----------------------
#include "LIS_misc.h"
!BOP
!
! !ROUTINE: read_MODISsai
! \label{read_MODISsai}
!
! !REVISION HISTORY:
!  25 Jul 2005: Sujay Kumar; Initial Specification
!  20 Feb 2006: Sujay Kumar; Modified to support nesting
!
! !INTERFACE:
subroutine read_MODISsai(n, time1, array)
! !USES:
  use ESMF
  use LIS_coreMod,        only : LIS_rc, LIS_domain, LIS_localPet
  use LIS_logMod,         only : LIS_logunit, LIS_getNextUnitNumber, &
       LIS_releaseUnitNumber, LIS_endrun
  use LIS_vegDataMod,     only : LIS_sai
  use LIS_fileIOMod,      only : LIS_readData
  use LIS_constantsMod,   only : LIS_CONST_PATH_LEN

  implicit none
! !ARGUMENTS: 

  integer, intent(in) :: n
  type(ESMF_Time)     :: time1
  real, intent(inout) :: array(LIS_rc%ntiles(n))

! !DESCRIPTION:
!  This subroutine retrieves the SAI climatology for the 
!  specified month and returns the values in the latlon projection
!  
!  The arguments are:
!  \begin{description}
!  \item[n]
!   index of the nest
!  \item[mo]
!   time index (month or quarter)
!  \item[array]
!   output field with the retrieved SAI 
!  \end{description}
!
!EOP     
  real, allocatable :: tmparr(:,:) 
  character(len=LIS_CONST_PATH_LEN) :: filename2
  integer :: t
  integer :: mo
  integer :: ftn
  character*3 :: months(12)
  real        :: sai_gridDesc(6)
  logical     :: file_exists

  data months /'jan','feb','mar','apr','may','jun','jul','aug',&
       'sep','oct','nov','dec'/

  allocate(tmparr(LIS_rc%lnc(n),LIS_rc%lnr(n)))
  call ESMF_TimeGet(time1,mm=mo)
  filename2 = trim(LIS_sai(n)%saifile)//"."//months(mo)//'.1gd4r'
  
  inquire(file=trim(filename2), exist=file_exists)
  if(.not.file_exists) then 
     write(LIS_logunit,*) 'SAI map ',trim(filename2),' not found'
     write(LIS_logunit,*) 'Program stopping ...'
     call LIS_endrun
  endif

  ftn = LIS_getNextUnitNumber()
  open(ftn, file=filename2, access='direct',status='old', &
       form="unformatted", recl=4)

  sai_gridDesc(1) = LIS_rc%gridDesc(n,34)
  sai_gridDesc(2) = LIS_rc%gridDesc(n,35)
  sai_gridDesc(3) = LIS_rc%gridDesc(n,37)
  sai_gridDesc(4) = LIS_rc%gridDesc(n,38)
  sai_gridDesc(5) = LIS_rc%gridDesc(n,39)
  sai_gridDesc(6) = LIS_rc%gridDesc(n,40)

  call LIS_readData(n,ftn,sai_gridDesc,tmparr)

  call LIS_releaseUnitNumber(ftn)

  do t=1,LIS_rc%ntiles(n)
     array(t) = tmparr(LIS_domain(n)%tile(t)%col,LIS_domain(n)%tile(t)%row)
  enddo
  deallocate(tmparr)
  write(LIS_logunit,*)'Read SAI File ',trim(filename2)

end subroutine read_MODISsai
