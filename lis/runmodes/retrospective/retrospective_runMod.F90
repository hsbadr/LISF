!-----------------------BEGIN NOTICE -- DO NOT EDIT-----------------------
! NASA Goddard Space Flight Center
! Land Information System Framework (LISF)
! Version 7.5
!
! Copyright (c) 2024 United States Government as represented by the
! Administrator of the National Aeronautics and Space Administration.
! All Rights Reserved.
!-------------------------END NOTICE -- DO NOT EDIT-----------------------
module retrospective_runMod
!BOP
!
! !MODULE: retrospective_runMod
! 
! !DESCRIPTION: 
!   This is a typical running mode used in LIS to perform 
!   retrospective simulations. The mode assumes that all the meteorological
!   forcing analyes required for the specified time period is archived 
!   for the simulation. 
! 
!   This module contains the definition of the functions used for
!   LIS initialization, execution, and finalization
!   for a retrospective runmode in LIS.
!   
! !REVISION HISTORY: 
!  21Oct05    Sujay Kumar  Initial Specification
!  25Feb25    Dan Rosen    Add Step Subroutine
! 
!
  implicit none
  
  PRIVATE
!-----------------------------------------------------------------------------
! !PUBLIC MEMBER FUNCTIONS:
!-----------------------------------------------------------------------------
  public :: LIS_init_retrospective  !init method for retrospective mode
  public :: LIS_run_retrospective   !run method for retrospective mode
  public :: LIS_step_retrospective  !step method for retrospective mode
  public :: LIS_final_retrospective !finalize method for retrospective mode

!EOP  
contains
!BOP
! !ROUTINE: LIS_init_retrospective
!
! 
! !INTERFACE:
  subroutine LIS_init_retrospective
! !USES: 
    use LIS_coreMod
    use LIS_domainMod,         only : LIS_domain_init
    use LIS_surfaceModelMod,   only : LIS_surfaceModel_init,  &
                                      LIS_surfaceModel_setup, &
                                      LIS_surfaceModel_readrestart
    use LIS_metforcingMod,     only : LIS_metforcing_init
    use LIS_DAobservationsMod, only : LIS_initDAObservations
    use LIS_perturbMod,        only : LIS_perturb_init, LIS_perturb_readrestart
    use LIS_dataAssimMod,      only : LIS_dataassim_init
    use LIS_paramsMod,         only : LIS_param_init
    use LIS_routingMod,        only : LIS_routing_init, LIS_routing_readrestart
    use LIS_irrigationMod,     only : LIS_irrigation_init
    use LIS_RTMMod,            only : LIS_RTM_init
    use LIS_appMod,            only : LIS_appModel_init

    use LIS_tbotAdjustMod,     only : LIS_createTmnUpdate
! !DESCRIPTION:
!  This is the initialize method for LIS in a retrospective running mode. 
!  The following calls are invoked from this method. 
! \begin{description} 
!  \item[LIS\_domain\_init] (\ref{LIS_domain_init}) \newline
!    initialize the LIS domains
!  \item[LIS\_param\_init] (\ref{LIS_param_init}) \newline
!    initialize parameters
!  \item[LIS\_lsm\_init] (\ref{LIS_lsm_init}) \newline
!    initialize the land surface model. 
!  \item[LIS\_metforcing\_init] (\ref{LIS_metforcing_init}) \newline
!    initialize the met forcing
!  \item[LIS\_initDAObservations] (\ref{LIS_initDAobservations}) \newline
!    initialize structures needed to read observations for 
!    data assimilation
!  \item[LIS\_setuplsm] (\ref{LIS_setuplsm}) \newline
!    complete the LSM setups
!  \item[LIS\_lsm\_readrestart] (\ref{LIS_lsm_readrestart}) \newline
!    read the restart files 
! \end{description} 
!
!EOP
    call LIS_domain_init
    call LIS_createTmnUpdate
    call LIS_param_init
    call LIS_perturb_init
    call LIS_surfaceModel_init
    call LIS_metforcing_init
    call LIS_irrigation_init
    call LIS_initDAObservations
    call LIS_routing_init
    call LIS_routing_readrestart
    call LIS_dataassim_init
    call LIS_surfaceModel_setup
    call LIS_surfaceModel_readrestart
    call LIS_perturb_readrestart
    call LIS_RTM_init
    call LIS_appModel_init
    call LIS_core_init

  end subroutine lis_init_retrospective

!BOP
! !ROUTINE: lis_run_retrospective
!
! !INTERFACE:
  subroutine lis_run_retrospective
! !USES:
    use LIS_coreMod,           only : LIS_rc, LIS_endofrun
!
! !DESCRIPTION:
!
!  This is the run method for LIS in a retrospective running mode.
!  The following calls are invoked from this method.
! \begin{description}
!  \item[LIS\_endofrun] (\ref{LIS_endofrun}) \newline
!    check to see if the end of simulation has reached
! \end{description}
!
!EOP
    integer :: n

    do while (.NOT. LIS_endofrun())
       call lis_step_retrospective()
    enddo
  end subroutine lis_run_retrospective

!BOP
! !ROUTINE: lis_step_retrospective
!
! !INTERFACE:
  subroutine lis_step_retrospective
! !USES:
    use LIS_coreMod,           only : LIS_rc, LIS_ticktime, LIS_timetoRunNest
    use LIS_surfaceModelMod,   only : LIS_surfaceModel_f2t, LIS_surfaceModel_run,&
                                      LIS_surfaceModel_output, LIS_surfaceModel_writerestart, &
                                      LIS_surfaceModel_perturb_states
    use LIS_paramsMod,         only : LIS_setDynparams
    use LIS_metforcingMod,     only : LIS_get_met_forcing, LIS_perturb_forcing
    use LIS_perturbMod,        only : LIS_perturb_writerestart
    use LIS_DAobservationsMod, only : LIS_readDAobservations, & 
                                      LIS_perturb_DAobservations
    use LIS_dataAssimMod,      only : LIS_dataassim_run, LIS_dataassim_output
    use LIS_routingMod,        only : LIS_routing_run, LIS_routing_writeoutput, &
                                      LIS_routing_writerestart
    use LIS_irrigationMod,     only : LIS_irrigation_run,LIS_irrigation_output
    use LIS_appMod,            only : LIS_runAppModel, LIS_outputAppModel
    use LIS_RTMMod,            only : LIS_RTM_run, LIS_RTM_output
    use LIS_logMod,            only : LIS_logunit
!
! !DESCRIPTION:
! 
!  This is the step method for LIS in a retrospective running mode.
!  The following calls are invoked from this method. 
! \begin{description} 
!  \item[LIS\_ticktime] (\ref{LIS_ticktime}) \newline
!    advance model clock
!  \item[LIS\_timeToRunNest] (\ref{LIS_timeToRunNest}) \newline
!    check to see if the current nest needs to be run. 
!  \item[LIS\_setDynparams] (\ref{LIS_setDynparams}) \newline
!    set the time dependent parameters
!  \item[LIS\_get\_met\_forcing] (\ref{LIS_get_met_forcing}) \newline
!    retrieve the met forcing
!  \item[LIS\_perturb\_forcing] (\ref{LIS_perturb_forcing}) \newline
!    perturbs the met forcing
!  \item[LIS\_irrigation\_run] (\ref{LIS_irrigation_run}) \newline
!    run the irrigation model
!  \item[LIS\_surfaceModel\_f2t] (\ref{LIS_surfaceModel_f2t}) \newline
!    transfer forcing to model tiles
!  \item[LIS\_surfaceModel\_run] (\ref{LIS_surfaceModel_run}) \newline
!    run the land surface model
!  \item[LIS\_surfaceModel\_perturb\_states] (\ref{LIS_surfaceModel_perturb_states}) \newline
!    perturb the land surface model states
!  \item[LIS\_readDAobservations] (\ref{LIS_readDAobservations}) \newline
!    read observations to be used for data assimilation
!  \item[LIS\_perturb\_DAobservations] (\ref{LIS_perturb_DAobservations}) \newline
!    perturb observations to be used for data assimilation
!  \item[LIS\_dataassim\_run] (\ref{LIS_dataassim_run}) \newline
!    run the data assimilation algorithm
!  \item[LIS\_dataassim\_output] (\ref{LIS_dataassim_output}) \newline
!    write da output
!  \item[LIS\_surfaceModel\_output] (\ref{LIS_surfaceModel_output}) \newline
!    write surface model output
!  \item[LIS\_surfaceModel\_writerestart] (\ref{LIS_surfaceModel_writerestart}) \newline
!    write surface model restart files
!  \item[LIS\_irrigation\_output] (\ref{LIS_irrigation_output}) \newline
!    write irrigation model output
!  \item[LIS\_routing\_run] (\ref{LIS_routing_run}) \newline
!    run the routing model
!  \item[LIS\_routing\_writeoutput] (\ref{LIS_routing_writeoutput}) \newline
!    write routing model output
!  \item[LIS\_routing\_writerestart] (\ref{LIS_routing_writerestart}) \newline
!    write routing model restart data
!  \item[LIS\_RTM\_run] (\ref{LIS_RTM_run}) \newline
!    run the radiative transfer model
!  \item[LIS\_RTM\_output] (\ref{LIS_RTM_output}) \newline
!    write radiative transfer model output
!  \item[LIS\_runAppModel] (\ref{LIS_runAppModel}) \newline
!    run the application model
!  \item[LIS\_outputAppModel] (\ref{LIS_outputAppModel}) \newline
!    write the application model output
! \end{description} 
!
!EOP
    integer :: n

    call LIS_ticktime

! Run each nest separately
    do n=1,LIS_rc%nnest
       if(LIS_timeToRunNest(n)) then
          call LIS_setDynparams(n)
          call LIS_get_met_forcing(n)
          call LIS_perturb_forcing(n)
          call LIS_irrigation_run(n)
          call LIS_surfaceModel_f2t(n)
          call LIS_surfaceModel_run(n)
          call LIS_surfaceModel_perturb_states(n)
          call LIS_readDAobservations(n)
          call LIS_perturb_DAobservations(n)
          call LIS_perturb_writerestart(n)
          call LIS_dataassim_run(n)
          call LIS_dataassim_output(n)
          call LIS_surfaceModel_output(n)
          call LIS_surfaceModel_writerestart(n)
          call LIS_irrigation_output(n)
          call LIS_routing_run(n)
          call LIS_routing_writeoutput(n)
          call LIS_routing_writerestart(n)
          call LIS_RTM_run(n)
          call LIS_RTM_output(n)
          call LIS_runAppModel(n)
          call LIS_outputAppModel(n)
       endif
    enddo
    flush(LIS_logunit)
  end subroutine lis_step_retrospective

!BOP
! !ROUTINE: lis_final_retrospective
!
! !INTERFACE:
  subroutine lis_final_retrospective
! !USES:
    use LIS_coreMod,         only : LIS_finalize
    use LIS_logMod,          only : LIS_logunit
    use LIS_surfaceModelMod, only : LIS_surfaceModel_finalize
    use LIS_paramsMod,       only : LIS_param_finalize
    use LIS_metforcingMod,   only : LIS_metforcing_finalize
    use LIS_RTMMod,          only : LIS_RTM_finalize
    use LIS_appMod,          only : LIS_appModel_finalize ! SY

! !DESCRIPTION:
! 
!  This is the finalize method for LIS in a retrospective running mode. 
!  The following calls are invoked from this method. 
! \begin{description} 
!  \item[LIS\_finalize] (\ref{LIS_finalize}) \newline
!    cleanup LIS generic structures
!  \item[LIS\_lsm\_finalize] (\ref{LIS_lsm_finalize}) \newline
!    cleanup land surface model specific structures
!  \item[LIS\_param\_finalize] (\ref{LIS_param_finalize}) \newline
!    cleanup parameter specific structures
!  \item[LIS\_metforcing\_finalize] (\ref{LIS_metforcing_finalize}) \newline
!    cleanup metforcing specific structures
!  \item[LIS\_RTM\_finalize] (\ref{LIS_RTM_finalize}) \newline
!    cleanup radiative transfer model specific structures
!  \item[LIS\_dataassim\_finalize] (\ref{LIS_dataassim_finalize}) \newline
!    cleanup data assimilation specific structures
! \end{description} 
!
!EOP

    call lis_finalize()
    call LIS_surfaceModel_finalize()
    call LIS_param_finalize()
    call LIS_metforcing_finalize()
    call LIS_RTM_finalize()
! SY: Begin
    call LIS_appModel_finalize()     
! SY: End 

    write(LIS_logunit,*) " LIS Run completed. "

  end subroutine lis_final_retrospective
end module retrospective_runMod
