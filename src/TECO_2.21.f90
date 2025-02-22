!photosynthetic response to temperature

! there is pending issue in methane, different runs/ par sets result to different concentraion saturating point, need 2-3 years of
! spin up time, this


!spin up for forward run: simu_daily dimension = 80,000
!spin up for DA run: dimension need to be changed for simu_dailywatertable, simu_dailywater, simu_dailysoilt, etc.
! *************************************************************
program TECO_MCMC

    implicit none

! USE IFPORT !! Was:      USE DFPORT
!   for parameter file
    real lat,longi,wsmax,wsmin
    real LAIMAX,LAIMIN,rdepth,Rootmax,Stemmax
    real SapR,SapS,SLA,GLmax,GRmax,Gsmax,stom_n
    real a1,Ds0,Vcmax0,extkU,xfang,alpha
    real Tau_Leaf,Tau_Wood,Tau_Root,Tau_F,Tau_C
    real Tau_Micro,Tau_slowSOM,Tau_Passive
    real gddonset,Q10,Q10rh,Rl0,Rs0,Rr0
!    integer first_year
!   for soil thermal, snow DA  ..int
    real shcap_s,condu_s,shcap_snow,condu_snow,albedo_snow,resht,thd_snow_depth,b_bound
    real infilt_rate
    real fa,fsub,rho_snow,decay_m
!   for methane DA  ..int
    real r_me,Q10pro,kCH4,Omax,CH4_thre,Tveg,Tpro_me,Toxi       !parameters added for MEMCMC
    real f,bubprob,Vmaxfraction
! *** for adding allocation rate into DA ***
	real etaL,etaW,etaR,f_F2M,f_C2M,f_C2S,f_M2S,f_M2P,f_S2P,f_S2M,f_P2M
!    real obs_CH4_MEMCMC(11,1000),std_CH4(11,1000)
    real dpatm ! used only in methane ebullition
!   for webpage flow    ..int
!    real paraest(19,40000)
    real, allocatable :: paraest(:,:)
    integer seq,Pselect
    character(len=120) parafile,parafile2,daparfile,outdir,uniparfile
    character(len=150) paraestfile
    integer,parameter :: partotal=60
    integer,dimension(partotal):: DApar
    real,dimension(partotal) :: parval,parval2,parmin,parmax
    character(len=250) indexstring

!   for climate file
    integer, parameter :: ilines=150000
    integer, parameter :: iiterms=18
    integer,dimension(ilines):: year_seq,doy_seq,hour_seq
    real forcing_data(iiterms,ilines)
    character(len=150) climatefile
    integer yr_length,lines
    integer,dimension(ilines):: year_seq1,doy_seq1,hour_seq1
    real forcing_data1(iiterms,ilines)
    character(len=150) climatefile1
    integer yr_length1,lines1
    integer,dimension(ilines):: year_seq2,doy_seq2,hour_seq2
    character(len=150) climatefile2,forcingdir
    real forcing_data2(iiterms,ilines)
    integer yr_length2,lines2

    real,dimension(11):: input_tsoil ! use the obs Tsoil to drive the submodel Tsoil_simu

!   for observation files
    real,allocatable,dimension(:,:) :: obs_cflux,obs_cflux_hr,obs_cpool,obs_ch4flux,obs_ch4conc
    real,allocatable,dimension(:,:) :: obs_soilwater,obs_soilt,obs_snow,obs_wt,obs_td,obs_soilprofc
    real,allocatable,dimension(:,:) :: std_cflux,std_cflux_hr,std_cpool,std_ch4flux,std_ch4conc
    real,allocatable,dimension(:,:) :: std_soilwater,std_soilt,std_snow,std_wt,std_td
    real treatment
    !    character(len=150) obsfile1,obsfile2,covfile
    character(len=150) covfile,obsfile_cflux,obsfile_cflux_hr,obsfile_cpool,obsfile_ch4flux,obsfile_ch4conc, &
         & obsfile_sw,obsfile_st,obsfile_soilprofc,&
         & obsfile_snow,obsfile_wt,obsfile_thawd
    !    integer len1,len2
    integer len_cflux,len_cflux_hr,len_cpool,len_ch4flux,len_ch4conc,len_sw,len_st,len_snow,len_wt,len_td
!   *** ..int commented lines
!    real obs_carbon(12,1000),std(12,1000),obs_soilwater(5,40000),obs_soilt(11,40000)
!    real obs_watertable_d(2,4000),obs_soilt(11,4000)

    ! water table ..int
    real water_table(ilines),snow_in(ilines)
    character(len=50) watertablefile,snowdepthfile
!   ***  observation files for methane DA
    integer len4,len5
    integer, parameter :: miterms=29
    real output_data(miterms,ilines)
!   for MCMC
    integer MCMC ! 0:run model simulation; 1:data assimilation
    integer IDUM,upgraded,isimu,JNAN
!    integer, parameter :: npara=18       ! Number of parameters to be estimated
    integer npara,daily,yk1
    real search_length
    real J_last
! commented for ..int
!    real Simu_dailyflux(15,10000)
!    real Simu_dailyflux14(14,10000)
!    real Simu_dailywater(11,10000)
!  *****************************  added for allocatable dimension for workshop                                                           ..int
    integer,parameter :: nyrmax=160
    real,dimension(15,nyrmax*365)    :: Simu_dailyflux
    real,dimension(14,nyrmax*365)    :: Simu_dailyflux14
	real,dimension(4,nyrmax*500)	 :: Simu_hrflux
    real,dimension(11,nyrmax*365)    :: Simu_dailysoilt
    real,dimension(11,24*nyrmax*365)    :: Simu_soiltemp
    real,dimension(1,24*nyrmax*365)     :: Simu_watertable
    real,dimension(1,nyrmax*365)     :: Simu_snowdepth
    real,dimension(30,24*nyrmax*365)    :: Simu_soilwater
    real,dimension(1,nyrmax*365)     :: Simu_dailywatertable
    real,dimension(1,nyrmax*365)     :: Simu_TD
    real,dimension(10,nyrmax*365)    :: Simu_dailyice
    real,dimension(31,nyrmax*365)    :: Simu_dailywater
    real,dimension(17,nyrmax*365)    :: Simu_dailyCH4
!    real Simu_dailyflux(15,80000),Simu_soilwater(10,40000),Simu_soiltemp(11,40000)
!    real Simu_dailysoilt(11,80000),Simu_dailywatertable(1,80000),Simu_dailyice(10,80000)
!    real Simu_watertable(1,40000),Simu_snowdepth(1,80000)
!    real Simu_dailyCH4(17,80000)
!    real Simu_dailyflux14(14,80000)
!    real Simu_dailywater(31,80000)
!  *****************************                                                            ..int
!    real coef(npara),coefac(npara),coefnorm(npara)
!    real coefmax(npara),coefmin(npara)

!    real coef(npara),coefac(npara),coefnorm(npara).
!    real coefmax(npara),coefmin(npara)
    real r,fact_rejet
!    real gamma(npara,npara),gamnew(npara,npara)     ! covariance matrix
    real, allocatable :: coef(:), coefac(:), coefnorm(:)
    real, allocatable :: coefmax(:),coefmin(:)
    real, allocatable :: gamma(:,:),gamnew(:,:)
    integer,allocatable :: coefindex(:)

    integer k1,k2,rejet,paraflag,k3
    integer, parameter :: nc=100
    integer, parameter :: ncov=500
!! nc: the multiplicative constant will be adjusted !!
!!        every nc iterations, to preserve an adequate!!
!!        acceptation rate
!! ncov: the covariance matrix gamma will be updated  !!
!!        every ncov iterations
!    real coefhistory(ncov,npara)
    real, allocatable :: coefhistory(:,:)
    character(len=150) outfile,MCMCargu,yrargu,dyargu
    character(len=150) Targu,CO2argu

!   for consts parameteres
    real,dimension(3):: tauL,rhoL,rhoS
    real pi,emleaf,emsoil,Rconst,sigma,cpair,Patm,Trefk
    real H2OLv0,airMa,H2OMw,chi,Dheat,wleaf,gsw0,eJmx0,theta,JV   ! added JV for acclimation study
    real conKc0,conKo0,Ekc,Eko,o2ci,Eavm,Edvm,Eajm,Edjm
    real Entrpy,gam0,gam1,gam2

!   for initialize
    real fwsoil,topfws,omega,Storage,nsc
    real fwsoil_initial,topfws_initial,omega_initial
    real Storage_initial,nsc_initial
    real wcl(10),QC(8)
    real wcl_initial(10),QC_initial(8)
    integer yrs_eq,rep,yrlim,dylim
    character(len=150) my_fmt
!   for simu_dailywater output
    real wsc(10)

!   .. int from soil thermal module
    real diff_snow,diff_s,condu_b
    real depth_ex
 !
    real Ttreat,CO2treat,covexist,randnum
    integer new,reject,tmp_up,i,j
    ! ***************************************************************
!   switches added to incorporate and accommodate soil thermal and methane module
!!!!!!!!!!!! user supplied configuration !!!!!!!!!!!!!!!!!!!!
!    logical,parameter :: do_soilphy = .True.
!    logical, parameter :: do_snow   = .True.
!    logical, parameter :: do_soilt_da     = .False.
!    logical, parameter :: do_snow_da     = .False.
!    logical, parameter :: do_watertable_da     = .False.
!    logical, parameter :: do_methane_da   = .False.
!    logical, parameter :: do_methane_fcast = .False.
!    logical, parameter :: do_co2_fcast = .False.
!    logical, parameter :: do_EBG = .True.
!    logical, parameter :: do_co2_da   = .False.
!    logical, parameter :: do_soilwater_da = .False.
!    logical, parameter :: is_grass = .True.   ! grassland

    logical is_grass  ! true for grassland, false for forest
    logical do_soilphy,do_snow,do_EBG,do_methane_fcast,do_co2_fcast
    logical do_soilt_da,do_snow_da,do_watertable_da,do_methane_da,do_co2_da,do_soilwater_da,do_da,do_fcast
    integer first_year,use_cflux_ob,use_cflux_hr_ob,use_cpool_ob,use_ch4flux_ob,use_ch4conc_ob,use_plinit
    integer use_soilwater_ob,use_soilt_ob,use_snow_ob,use_watertable_ob,use_td_ob
    namelist /control_pm/ parafile,parafile2,DAparfile,climatefile1,outdir,is_grass,first_year,use_plinit,do_soilphy,&
            do_snow,do_EBG,do_methane_fcast,do_co2_fcast,&
            do_co2_da,do_methane_da,do_soilwater_da,do_soilt_da,do_snow_da,do_watertable_da,&
            use_cflux_ob,use_cflux_hr_ob,use_cpool_ob,use_ch4flux_ob,use_ch4conc_ob,use_soilwater_ob,use_soilt_ob,&
            use_snow_ob,use_watertable_ob,use_td_ob,&
            obsfile_cflux,obsfile_cflux_hr,obsfile_cpool,obsfile_soilprofc,obsfile_ch4flux,obsfile_ch4conc,&
            obsfile_sw,obsfile_st,obsfile_snow,obsfile_wt,obsfile_thawd
     open(517,file='teco.nml')
     read(517,nml=control_pm)
     write(*,*)'parafile=',parafile
	 write(*,*)'parafile2=',parafile2
     write(*,*)'DAparfile=',DAparfile
!     write(*,*)'climatefile0=',climatefile0
     write(*,*)'climatefile1=',climatefile1
     write(*,*)'outdir=',outdir
     write(*,*)'is_grass=',is_grass
     write(*,*)'first_year=',first_year
     write(*,*)'use_plinit=',use_plinit
     write(*,*)'do_soilphy=',do_soilphy
     write(*,*)'do_snow=',do_snow
     write(*,*)'do_EBG=',do_EBG
     write(*,*)'do_methane_fcast=',do_methane_fcast
     write(*,*)'do_co2_fcast=',do_co2_fcast
     write(*,*)'do_co2_da=',do_co2_da
     write(*,*)'do_methane_da=',do_methane_da
     write(*,*)'do_soilwater_da=',do_soilwater_da
     write(*,*)'do_soilt_da=',do_soilt_da
     write(*,*)'do_snow_da=',do_snow_da
     write(*,*)'do_watertable_da=',do_watertable_da
     write(*,*)'use_cflux_ob=',use_cflux_ob
	 write(*,*)'use_cflux_hr_ob=',use_cflux_hr_ob
     write(*,*)'use_cpool_ob=',use_cpool_ob
     write(*,*)'use_ch4flux_ob=',use_ch4flux_ob
     write(*,*)'use_ch4conc_ob=',use_ch4conc_ob
     write(*,*)'use_soilwater_ob=',use_soilwater_ob
     write(*,*)'use_soilt_ob=',use_soilt_ob
     write(*,*)'use_snow_ob=',use_snow_ob
     write(*,*)'use_watertable_ob=',use_watertable_ob
     write(*,*)'use_td_ob=',use_td_ob
     write(*,*)'obsfile_cflux=',obsfile_cflux
	 write(*,*)'obsfile_cflux_hr=',obsfile_cflux_hr
     write(*,*)'obsfile_cpool=',obsfile_cpool
     write(*,*)'obsfile_soilprofc=',obsfile_soilprofc
     write(*,*)'obsfile_ch4flux=',obsfile_ch4flux
     write(*,*)'obsfile_ch4conc=',obsfile_ch4conc
     write(*,*)'obsfile_sw=',obsfile_sw
     write(*,*)'obsfile_st=',obsfile_st
     write(*,*)'obsfile_snow=',obsfile_snow
     write(*,*)'obsfile_wt=',obsfile_wt
     write(*,*)'obsfile_thawd=',obsfile_thawd


    yrlim = 2014   !
    dylim = 365
    Ttreat = 0.0            ! this is for adding temp in forward simulation mode, not forecasting mode
    CO2treat = 900.0 !0608

! ***************************************************************

! ***********  int initial values of paras used in soil thermal is added here instead of in the pars file ********
! Parameters for soil physical part Yuanyuan
!    shcap_snow=690000.  ! refer to csm 4.0 physical constant ! 2090 J/kg/°K with density of 330 kg/m3
! ..int
    shcap_snow=1000000.  ! tuneice worker better
    condu_snow=0.1
!    condu_b = 0.2  ! yuanyuan int version value
    condu_b = 0.08  ! yuanyuan soil thermal version value  ... int: this par is not sensitive to CWE
    depth_ex=0.05
!    shcap_snow=700246.3125  ! refer to csm 4.0 physical constant ! 2090 J/kg/°K with density of 330 kg/m3
!    condu_snow=0.0202
!    condu_b = 0.0797
!    depth_ex=0.0472

    diff_s=1.
    diff_snow =1.8    ! .. int diffusivity of snow not sensitive for ice
!    diff_snow =0.018      !tunesnow
    albedo_snow=0.7
    resht=40.
    thd_snow_depth=4.0
    b_bound=100.
!    b_bound=0.1     !tuneice  not sensitive for ice

    infilt_rate= 0.001
!    infilt_rate= 0.00
    fa = 1
    fsub=0.1
!    rho_snow=100.
    rho_snow=80.        !tuneice
    decay_m=2.2192      !aging factor on snow melting
!    decay_m=1.7      !tuneice
! ***********   end of soil thermal paras initial values

!   Read parameters from file
!    call getarg(1,parafile)
!    parafile='input/SPRUCE_pars.txt'
!    parafile2 is for post 2014
    write(*,*)'getting parameters from ',parafile2
    call Getparameters(lat,longi,wsmax,wsmin,           &
    &   LAIMAX,LAIMIN,rdepth,Rootmax,Stemmax,           &
    &   SapR,SapS,SLA,GLmax,GRmax,Gsmax,stom_n,         &
    &   a1,Ds0,Vcmax0,extkU,xfang,alpha,                &
    &   Tau_Leaf,Tau_Wood,Tau_Root,Tau_F,Tau_C,         &
    &   Tau_Micro,Tau_slowSOM,Tau_Passive,              &
    &   gddonset,Q10,Rl0,Rs0,Rr0,parafile2,              &
    &   r_me,Q10pro,kCH4,Omax,CH4_thre,Tveg,Tpro_me,Toxi,&
    &   f,bubprob,Vmaxfraction, &       !..int added for methane module
    &   Q10rh,JV,Entrpy, &                   ! added for acclimation study Feb 19 2019
	&	etaL,etaW,etaR,f_F2M,f_C2M,f_C2S,&
	&	f_M2S,f_M2P,f_S2P,f_S2M,f_P2M) ! added for Sep 2019

    parval2 = (/lat,longi,wsmax,wsmin,           &
    &   LAIMAX,LAIMIN,rdepth,Rootmax,Stemmax,           & !9
    &   SapR,SapS,SLA,GLmax,GRmax,Gsmax,stom_n,         & !16
    &   a1,Ds0,Vcmax0,extkU,xfang,alpha,                & !22
    &   Tau_Leaf,Tau_Wood,Tau_Root,Tau_F,Tau_C,         & !27
    &   Tau_Micro,Tau_slowSOM,Tau_Passive,              & !30
    &   gddonset,Q10,Rl0,Rs0,Rr0,   &
    &   r_me,Q10pro,kCH4,Omax,CH4_thre,Tveg,Tpro_me,Toxi,&!43
    &   f,bubprob,Vmaxfraction, &                         !46
    &   Q10rh,JV,Entrpy, &                   			!49
	&	etaL,etaW,etaR,f_F2M,f_C2M,f_C2S,&
	&	f_M2S,f_M2P,f_S2P,f_S2M,f_P2M/) ! 60
	!    parafile is for before 2014
    write(*,*)'getting parameters from ',parafile
    call Getparameters(lat,longi,wsmax,wsmin,           &
    &   LAIMAX,LAIMIN,rdepth,Rootmax,Stemmax,           &
    &   SapR,SapS,SLA,GLmax,GRmax,Gsmax,stom_n,         &
    &   a1,Ds0,Vcmax0,extkU,xfang,alpha,                &
    &   Tau_Leaf,Tau_Wood,Tau_Root,Tau_F,Tau_C,         &
    &   Tau_Micro,Tau_slowSOM,Tau_Passive,              &
    &   gddonset,Q10,Rl0,Rs0,Rr0,parafile,              &
    &   r_me,Q10pro,kCH4,Omax,CH4_thre,Tveg,Tpro_me,Toxi,&
    &   f,bubprob,Vmaxfraction, &       !..int added for methane module
    &   Q10rh,JV,Entrpy, &                   ! added for acclimation study Feb 19 2019
	&	etaL,etaW,etaR,f_F2M,f_C2M,f_C2S,f_M2S,f_M2P,f_S2P,f_S2M,f_P2M) ! added for Sep 2019

!    write (*,*) 'first_year',first_year,'Entrpy',Entrpy
    parval  = (/lat,longi,wsmax,wsmin,           &
    &   LAIMAX,LAIMIN,rdepth,Rootmax,Stemmax,           & !9
    &   SapR,SapS,SLA,GLmax,GRmax,Gsmax,stom_n,         & !16
    &   a1,Ds0,Vcmax0,extkU,xfang,alpha,                & !22
    &   Tau_Leaf,Tau_Wood,Tau_Root,Tau_F,Tau_C,         & !27
    &   Tau_Micro,Tau_slowSOM,Tau_Passive,              & !30
    &   gddonset,Q10,Rl0,Rs0,Rr0,   &
    &   r_me,Q10pro,kCH4,Omax,CH4_thre,Tveg,Tpro_me,Toxi,&!43
    &   f,bubprob,Vmaxfraction, &                         !46
    &   Q10rh,JV,Entrpy, &                   			!49
	&	etaL,etaW,etaR,f_F2M,f_C2M,f_C2S,f_M2S,f_M2P,f_S2P,f_S2M,f_P2M/) ! 60
	write (*,*) "head parval",parval,"parval2",parval2
!    read in from namelist
!!   Read climatic forcing
!!    climatefile1='input/SPRUCE_forcing2011_2016_PBOT.txt'
!    climatefile1='input/ForcingTECO_ambient_2005-2016_PBOT.txt'  !test grassland
!! ****************************************************************************
!    watertablefile='input/SPRUCE_Water_Table_Level_2011-2014.txt'
!    snowdepthfile='input/SPRUCE_Snow_Depth_2011-2014.txt'

!    if (.not. do_methane_fcast) then
    write(*,*)'Getting climate forcing from ',climatefile1!,climatefile0
        call Getclimate(year_seq1,doy_seq1,hour_seq1,          &
        &   forcing_data1,climatefile1,lines1,yr_length1)
!        call Getclimate(year_seq1,doy_seq1,hour_seq1,          &
!        &   forcing_data0,climatefile0,lines1,yr_length1)

        if (.not. do_soilphy)then
            write(*,*)'Getting water table from ',watertablefile
        call Getwatertable(year_seq,doy_seq,hour_seq,          &
        &   water_table,watertablefile,lines,yr_length)
        end if
        if (.not. do_snow) then
            write(*,*)'Getting snow depth from ',snowdepthfile
            call Getsnowdepth(year_seq,doy_seq,hour_seq,          &
            &   snow_in,snowdepthfile,lines,yr_length)
        endif
!    endif
        !   1 are climate data for simulation, 2 are climate data for forecasting   ..int
!   getwatertable and snowdepth are used as forcing in soil thermal module by Yuanyuan   ..int

!   Read observation data
!   read in from namelist
!    call getarg(3,obsfile1)
!    obsfile1='input/SPRUCE_obs.txt'
!   added obs files 2-6 for ..int
!    obsfile2='input/SPRUCE_hummock_toplayer.txt'
!    obsfile3='input/SPRUCE_soilt.txt'
!    obsfile4='input/daily_soilt_2011-2014.txt'
!    obsfile5='input/daily_watertable_2011-2014.txt'
!!    obsfile6='input/SPRUCE_obs_ch4_2011-2016_0amb.txt'
!    obsfile6='input/SPRUCE_obs_ch4_2011-2017_amb_del2017_del0414_del20160.6.txt'

    treatment=0.    ! Ambient temperature

!   ..int more obs files added in the getobsdata subroutine
!    call GetObsData(obs_carbon,std,len1,obsfile1)
!   ..int read obs files for CO2, soil thermal and soil water DA
    allocate(obs_cflux(5,yr_length1*365))
	allocate(obs_cflux_hr(7,yr_length1*500))
    allocate(obs_cpool(10,yr_length1*5))
    allocate(obs_ch4flux(2,yr_length1*365))
    allocate(obs_ch4conc(10,yr_length1*365))
    allocate(obs_soilwater(4,yr_length1*365))
    allocate(obs_soilt(9,yr_length1*365))
    allocate(obs_snow(3,yr_length1*365))
    allocate(obs_wt(3,yr_length1*365))
    allocate(obs_td(3,yr_length1*365))

    allocate(std_cflux(5,yr_length1*365))
	allocate(std_cflux_hr(7,yr_length1*500))
    allocate(std_cpool(10,yr_length1*5))
    allocate(std_ch4flux(2,yr_length1*365))
    allocate(std_ch4conc(10,yr_length1*365))
    allocate(std_soilwater(6,yr_length1*365))
    allocate(std_soilt(9,yr_length1*365))
    allocate(std_snow(3,yr_length1*365))
    allocate(std_wt(3,yr_length1*365))
    allocate(std_td(3,yr_length1*365))


    write(*,*)'getting observation for data assimilation'
    call GetObsData(obs_cflux,obs_cflux_hr,obs_cpool,obs_ch4flux,obs_ch4conc,&
            &	obs_soilwater,obs_soilt,obs_snow,obs_wt,obs_td,obs_soilprofc, &
            &	std_cflux,std_cflux_hr,std_cpool,std_ch4flux,std_ch4conc,&
            &	std_soilwater,std_soilt,std_snow,std_wt,std_td, &
            &   obsfile_cflux,obsfile_cflux_hr,obsfile_cpool,obsfile_ch4flux,obsfile_ch4conc,&
            &	obsfile_sw,obsfile_st,obsfile_soilprofc,&
            &   obsfile_snow,obsfile_wt,obsfile_thawd,use_plinit,&
            &   len_cflux,len_cflux_hr,len_cpool,len_ch4flux,len_ch4conc,len_sw,len_st,len_snow,len_wt,len_td,yr_length1)
!   initiations for canopy model, including canopy traits variation in a year
    ! write (*,*) 'after getobs obs_cflux_hr',obs_cflux_hr
    write(*,*)'initializing constants for canopy model'
    call consts(pi,tauL,rhoL,rhoS,emleaf,emsoil,&
     &    Rconst,sigma,cpair,Patm,Trefk,H2OLv0,airMa,H2OMw,chi,Dheat,&
     &    wleaf,gsw0,Vcmax0,eJmx0,theta,conKc0,conKo0,Ekc,Eko,o2ci,&
     &    Eavm,Edvm,Eajm,Edjm,Entrpy,gam0,gam1,gam2)

    fwsoil=1.0
    topfws=1.0
    omega=1.0
    do i=1,10
        wcl(i)=wsmax/100.
    enddo
    Storage=60.0 !32.09           !g C/m2
    nsc=85.35
!         put the values into a matrix
!    QC=(/300.,650.,100.,119.,300.,322.,38340.,23120./)    !github
!    QC=(/500.,650.,300.,119.,300.,322.*1.25,38340.*1.25,23120.*1.25/)
!    QC=(/500.,650.,300.,119.,300.,322.*2,38340.*1.5,23120.*1.5/)
!    QC=(/500.,100.,300.,119.,300.,322.,38340.,23120./)    ! ecosystem initial state for 1999 forward
!    QC=(/500.,650.,200.,119.,300.,322.,38340.,23120./)     ! ecosystem initial state for 2011 forward
!    QC=(/450.,380.,250.,119.,300.,322.,38340.,23120./)      ! updated leave wood biomass due to the change of estimated plot area

    if(is_grass)then
        if (use_plinit .eq. 0) then      !average site-level C pool size eg. tundra Alaska
!      (1)foliage(2)wood(3)root(4)Coarse Litter(5)Fine litter(6)fast soilC(7)slow soilC(8)passive soilC
            QC_initial=(/150.,0.,250.,119.,300.,322.,38340.,23120./)
        else                             ! plot specific initial valued for the 8 carbon pool sizes
            QC_initial=(/150.,0.,250.,119.,300.,322.,38340.,23120./)
        endif
    else
        if (use_plinit .eq. 0) then      !average site-level C pool size eg. SPRUCE forest Minnesota
            QC_initial=(/300.,380.,250.,119.,300.,322.,86558.,71120./)
        elseif (use_plinit .eq. 11) then !plot-specific C pool size eg. SPRUCE forest Minnesota
        !    QC_initial=(/208.4,242.5,378.,119.,300.,250.,86558.,71120./) !p07 f1p1
		! QC_initial=(/146.9,67.7,200.,119.,300.,250.,86558.,71120./) !p07 f1p1 without trees
			! QC_initial=(/146.9,67.7,200.,119.,300.,350.,36558.,131120./) !p07 f1p1 without trees
			QC_initial=(/146.9,67.7,200.,119.,300.,350.,86558.,71120./) !p07 f1p1 without trees
			! QC_initial=(/108.4,192.5,200.,119.,300.,250.,86558.,71120./) !p07 f1p1  decreased wood and leaf for 18 yrs spinup, rescaled root biomass
		elseif (use_plinit .eq. 12) then  !         leaf  wood  root lif lic  micro fast   passive
        !    QC_initial=(/201.4,221.5,378.,119.,300.,250.,86558.,71120./) !p06 f1p2
			! QC_initial=(/146.1,64.,200.,119.,300.,350.,36558.,131120./) !p06 f1p2 without trees
			QC_initial=(/146.1,64.,200.,119.,300.,350.,86558.,71120./) !p06 f1p2 without trees
			! QC_initial=(/201.4,121.5,378.,119.,300.,250.,86558.,71120./) !p06 f1p1 decreased wood and leaf for 18 yrs spinup
			! QC_initial=(/201.4,151.5,200.,119.,300.,250.,86558.,71120./) !p06 f1p1 decreased wood and leaf for 18 yrs spinup
        elseif (use_plinit .eq. 13) then
		!    QC_initial=(/324.4,742.5,378.,119.,300.,250.,86558.,71120./) !p20 f1p3
		   ! QC_initial=(/136.7,207.8,200.,119.,300.,350.,36558.,131120./) !p20 f1p3 without trees
		   QC_initial=(/136.7,207.8,200.,119.,300.,350.,86558.,71120./) !p20 f1p3 without trees
			! QC_initial=(/324.4,702.5,478.,119.,300.,250.,86558.,71120./) !p20 f1p3  decreased wood and leaf for 18 yrs spinup
        elseif (use_plinit .eq. 14) then
        !    QC_initial=(/250.4,369.5,378.,119.,300.,250.,86558.,71120./) !p13 f1p4
			! QC_initial=(/155.7,98.4,200.,119.,300.,350.,36558.,131120./) !p13 f1p4 without trees
			QC_initial=(/155.7,98.4,200.,119.,300.,350.,86558.,71120./) !p13 f1p4 without trees
			! QC_initial=(/250.4,359.5,228.,119.,300.,250.,86558.,71120./) !p13 f1p4  decreased wood and leaf for 18 yrs spinup
        elseif (use_plinit .eq. 15) then
        !   QC_initial=(/251.4,492.5,378.,119.,300.,250.,86558.,71120./) !p08 f1p5
			! QC_initial=(/121.1,119.9,200.,119.,300.,350.,36558.,131120./) !p08 f1p5 without trees
			QC_initial=(/121.1,119.9,200.,119.,300.,350.,86558.,71120./) !p08 f1p5 without trees
			! QC_initial=(/251.4,472.5,228.,119.,300.,250.,86558.,71120./) !p08 f1p5  decreased wood and leaf for 18 yrs spinup
        elseif (use_plinit .eq. 16) then
        !    QC_initial=(/245.4,392.5,378.,119.,300.,250.,86558.,71120./) !p17 f1p6
			! QC_initial=(/167.6,170.4,200.,119.,300.,350.,36558.,131120./) !p17 f1p6 without trees
			QC_initial=(/167.6,170.4,200.,119.,300.,350.,86558.,71120./) !p17 f1p6 without trees
			! QC_initial=(/245.4,352.5,298.,119.,300.,250.,86558.,71120./) !p17 f1p6  decreased wood and leaf for 18 yrs spinup

        elseif (use_plinit .eq. 21) then
            QC_initial=(/441.4,596.5,378.,119.,300.,250.,86558.,71120./) !p21 f2p1
			QC_initial=(/441.4,496.5,378.,119.,300.,250.,86558.,71120./) !p21 f2p1  decreased wood and leaf for 18 yrs spinup
        elseif (use_plinit .eq. 22) then
            QC_initial=(/338.4,592.5,378.,119.,300.,250.,86558.,71120./) !p19 f2p2
			QC_initial=(/338.4,492.5,378.,119.,300.,250.,86558.,71120./) !p19 f2p2  decreased wood and leaf for 18 yrs spinup
        elseif (use_plinit .eq. 23) then
            QC_initial=(/245.4,359.5,378.,119.,300.,250.,86558.,71120./) !p11 f2p3
			QC_initial=(/245.4,259.5,378.,119.,300.,250.,86558.,71120./) !p11 f2p3  decreased wood and leaf for 18 yrs spinup
        elseif (use_plinit .eq. 24) then
            QC_initial=(/200.4,263.5,378.,119.,300.,250.,86558.,71120./) !p4 f2p4
			QC_initial=(/200.4,163.5,378.,119.,300.,250.,86558.,71120./) !p4 f2p4  decreased wood and leaf for 18 yrs spinup
        elseif (use_plinit .eq. 25) then
            QC_initial=(/296.4,621.5,378.,119.,300.,250.,86558.,71120./) !p16 f2p5
			QC_initial=(/296.4,421.5,378.,119.,300.,250.,86558.,71120./) !p16 f2p5  decreased wood and leaf for 18 yrs spinup
        elseif (use_plinit .eq. 26) then
            QC_initial=(/212.4,317.5,378.,119.,300.,250.,86558.,71120./) !p10 f2p6
			QC_initial=(/212.4,217.5,378.,119.,300.,250.,86558.,71120./) !p10 f2p6  decreased wood and leaf for 18 yrs spinup

        else
            write (*,*) 'use_plinit not eq 2 1 5 4 6 3'
            QC_initial=(/300.,380.,250.,119.,300.,250.,86558.,71120./)
        endif
    endif   !         leaf  wood  root lif lic  micro fast   passive
    QC=QC_initial   ! assigned here fore easier identification in the workshop
!    QC=(/201.4,221.5,150.,119.,300.,322.,38340.,23120./) !p06
!    QC=(/251.4,492.5,200.,119.,300.,322.,38340.,23120./) !p08
!    QC=(/250.4,369.5,200.,119.,300.,322.,38340.,23120./) !p13
!    QC=(/245.4,392.5,200.,119.,300.,322.,38340.,23120./) !p17
	     write (*,*) 'QC(1)=',QC(1),'QC(2)=',QC(2)
!   Start main loop
!    call getarg(4,outdir)
!    outdir = 'output'  !Chris added into namelist
    do_da = do_soilt_da .or. do_snow_da .or. do_watertable_da .or. do_co2_da .or. &
            do_co2_da .or. do_soilwater_da .or. do_methane_da
    do_fcast = do_methane_fcast .or. do_co2_fcast
    write(*,*)'do_da is=',do_da,'do_fcast=',do_fcast,'do_methane_fcast=',do_methane_fcast
    if (.not. do_da .and. .not. do_fcast) then
        write(*,*)'forward run','outdir',outdir
            write(outfile,"(A120,A18)") trim(outdir),"/SPRUCE_yearly.csv"
            outfile = trim(outfile)
            outfile = adjustl(outfile)
            write(*,*)'outfile=',outfile
            open(61,file=outfile)
            write(*,*)'open 61'
            write(61,*) 'year,LAI,gpp_yr,NPP_yr,Ra_yr,Rh_yr, &
                        &   ET,rain_yr,transp_yr,evap_yr,runoff_yr,GL_yr,    &
                        &   GW_yr,GR_yr,Pool1,Pool2,Pool3,Pool4,Pool5,   &
                        &   Pool6,Pool7,Pool8,out1_yr,out2_yr,out3_yr,   &
                        &   out4_yr,out5_yr,out6_yr,out7_yr,out8_yr,     &
                        &   simuCH4_yr,Pro_sum_yr,Oxi_sum_yr,Fdifu1_yr, &
                        &   Ebu_sum_unsat_yr,Ebu_sum_sat_yr,Pla_sum_yr'
            write(*,*)'SPRUCE_yearly'
            write(outfile,"(A120,A22)") trim(outdir),"/Simu_dailyflux001.csv"
            outfile = trim(outfile)
            outfile = adjustl(outfile)
            open(62,file=outfile)
            write(62,*)'sdoy, GPP_d, NEE_d, Reco_d, QC1, GL_yr, QC2, GW_yr, QC3, GR_yr, QC678, pheno, LAI,NPP_d,Rh_d, Ra_d'
        ! MS insert simu_dailywater output
            write(outfile,"(A120,A23)") trim(outdir),"/Simu_dailywater001.csv"
            outfile = trim(outfile)
            outfile = adjustl(outfile)
            open(63,file=outfile)
        !    write(63,*)'wcl1,wcl2,wcl3,wcl4,wcl5,wcl6,wcl7,wcl8,wcl9,wcl10,zwt'
            write(63,*)'day,wcl1,wcl2,wcl3,wcl4,wcl5,wcl6,wcl7,wcl8,wcl9,wcl10,liq_water1,liq_water2,liq_water3,&
            & liq_water4,liq_water5,liq_water6,liq_water7,liq_water8,liq_water9,liq_water10,ice1,ice2,ice3,ice4,&
            & ice5,ice6,ice7,ice8,ice9,ice10,zwt'
            write(outfile,"(A120,A24)") trim(outdir),"/Simu_dailyflux14001.csv"
            outfile = trim(outfile)
            outfile = adjustl(outfile)
            open(662,file=outfile)
!            write(662,*)'sdoy, GPP_d, NEE_d, Reco_d, NPP_d, Ra_d, QC1, QC2, QC3, add, storage, LAIMAX, Rh_d, LAI, Tleaf(1)'
              write(662,*)'sdoy, GPP_d, NEE_d, Reco_d, NPP_d, Ra_d, QC1, QC2, QC3, QC4,QC5,QC6, Rh_d,QC7,QC8'
        ! end of inserting
                            write(outfile,"(A120,A21)") trim(outdir), "/Simu_dailybal001.csv"
                            outfile=trim(outfile)
                            outfile=adjustl(outfile)
                            open(70,file=outfile)
                            write (70,*)'day,swc1,swc2,swc3,st1,st2'

            write(outfile,"(A120,A18)") trim(outdir),"/Simu_dailyCH4.csv"
            outfile = trim(outfile)
            outfile = adjustl(outfile)
            open(64,file=outfile)
            write (64,*)'day,simuCH4_d,pro_sum_d,oxi_sum_d,fdifu1_d,ebu_sum_sat_d,pla_sum_d,CH4V1,CH4V2,CH4V3,CH4V4,CH4V5,  &
            &  CH4V6,CH4V7,CH4V8,CH4V9,CH4V10,ebu_sum_unsat_d,zwt'

        ! ..int
            write(outfile,"(A120,A18)") trim(outdir),"/Simu_soiltemp.csv"
            outfile = trim(outfile)
            outfile = adjustl(outfile)
            open(65,file=outfile)

            write(outfile,"(A120,A18)") trim(outdir),"/Simu_dailyice.csv"
            outfile = trim(outfile)
            outfile = adjustl(outfile)
            open(66,file=outfile)

!                    write(outfile,"(A120,A21,I3.3,A4)") trim(outdir), "/Simu_dailywatertable",1,".csv"
!                    outfile=trim(outfile)
!                    outfile=adjustl(outfile)
!                    open(67,file=outfile)

                    write(outfile,"(A120,A22)") trim(outdir), "/Simu_snowdepth001.csv"
                    outfile=trim(outfile)
                    outfile=adjustl(outfile)
                    open(68,file=outfile)
                    write(68,*)'day,snowdepth'

                    write(outfile,"(A120,A22)") trim(outdir), "/Simu_thawdepth001.csv"
                    outfile=trim(outfile)
                    outfile=adjustl(outfile)
                    open(69,file=outfile)

        ! ..int below files did not change the format to JJ's
!            write(outfile,"(A120,A15)") trim(outdir),"/Simu_Esoil.csv"
!            outfile = trim(outfile)
!            outfile = adjustl(outfile)
!            open(84,file=outfile)
!    !       write(84,*)'Esoil,slope,Rsoilabs,G,rhocp,Dair,raero,rLAI,psyc,Rsoil'
!            write (84,*) 'Esoil,slope,Rsoilabs,G,rhocp,Dair,raero,rLAI,psyc,Rsoil,  &
!              &  Hsoil,sftmp,Tair,resht_lai'

!            write(outfile,"(A120,A28)") trim(outdir),"/Simu_hourly_water_table.csv"
!            outfile = trim(outfile)
!            outfile = adjustl(outfile)
!            open(81,file=outfile)
!            if (do_soilphy) then
!                write (81,*)'WTADD,infilt,runoff,evap,transp,vtot,zwt, &
!                & liq_water(1),liq_water(2),liq_water(3),liq_water(4),liq_water(5), &
!                & liq_water(6),liq_water(7),liq_water(8),liq_water(9),liq_water(10), &
!                & ice(1),ice(2),ice(3),ice(4),ice(5),ice(6),ice(7),ice(8),ice(9),ice(10), &
!                & wcl(1),wcl(2),wcl(3),wcl(4),wcl(5),wcl(6),wcl(7),wcl(8),wcl(9),wcl(10)'
!            else
!                write(81,*)'WTADD,infilt,runoff,evap,transp,vtot,zwt, &
!                & wsc(1),wsc(2),wsc(3),wsc(4),wsc(5),wsc(6),wsc(7),wsc(8),wsc(9),wsc(10), &
!                & wcl(1),wcl(2),wcl(3),wcl(4),wcl(5),wcl(6),wcl(7),wcl(8),wcl(9),wcl(10)'
!            endif

            write(outfile,"(A120,A16)") trim(outdir),"/hourlysoilt.csv"
            outfile = trim(outfile)
            outfile = adjustl(outfile)
            open(91,file=outfile)

            write(outfile,"(A120,A24)") trim(outdir),"/Simu_hourly_Methane.csv"
            outfile = trim(outfile)
            outfile = adjustl(outfile)
            open(82,file=outfile)
            if (do_EBG) then
                write(82,*) 'zwt,simuCH4,Pro_sum,Pla_sum,Ebu_sum_sat,Ebu_sum_unsat,Fdifu(1), &
                  & Rh(1),Rh(2),Rh(3),Rh(4),Rh(5),Rh(6),Rh(7),Rh(8),Rh(9),Rh(10),   &
                  & ProCH4(1),ProCH4(2),ProCH4(3),ProCH4(4),ProCH4(5),ProCH4(6),ProCH4(7),ProCH4(8),ProCH4(9),ProCH4(10),   &
                  & PlaCH4(1),PlaCH4(2),PlaCH4(3),PlaCH4(4),PlaCH4(5),PlaCH4(6),PlaCH4(7),PlaCH4(8),PlaCH4(9),PlaCH4(10),   &
                  & mebu_out2(1),mebu_out2(2),mebu_out2(3),mebu_out2(4),mebu_out2(5),mebu_out2(6),mebu_out2(7),mebu_out2(8), &
                  & mebu_out2(9),mebu_out2(10), &
                  & Fdifu(1),Fdifu(2),Fdifu(3),Fdifu(4),Fdifu(5),Fdifu(6),Fdifu(7),Fdifu(8),Fdifu(9),Fdifu(10), &
                  & CH4(1),CH4(2),CH4(3),CH4(4),CH4(5),CH4(6),CH4(7),CH4(8),CH4(9),CH4(10), &
                  & CH4_V(1),CH4_V(2),CH4_V(3),CH4_V(4),CH4_V(5),CH4_V(6),CH4_V(7),CH4_V(8),CH4_V(9),CH4_V(10), &
                  & OxiCH4(1),OxiCH4(2),OxiCH4(3),OxiCH4(4),OxiCH4(5),OxiCH4(6),OxiCH4(7),OxiCH4(8),OxiCH4(9),OxiCH4(10)'
            else
                write(82,*) 'zwt,simuCH4,Pro_sum,Pla_sum,Ebu_sum_sat,Ebu_sum_unsat,Fdifu(1), &
                  & Rh(1),Rh(2),Rh(3),Rh(4),Rh(5),Rh(6),Rh(7),Rh(8),Rh(9),Rh(10),   &
                  & ProCH4(1),ProCH4(2),ProCH4(3),ProCH4(4),ProCH4(5),ProCH4(6),ProCH4(7),ProCH4(8),ProCH4(9),ProCH4(10),   &
                  & PlaCH4(1),PlaCH4(2),PlaCH4(3),PlaCH4(4),PlaCH4(5),PlaCH4(6),PlaCH4(7),PlaCH4(8),PlaCH4(9),PlaCH4(10),   &
                  & EbuCH4(1),EbuCH4(2),EbuCH4(3),EbuCH4(4),EbuCH4(5),EbuCH4(6),EbuCH4(7),EbuCH4(8),EbuCH4(9),EbuCH4(10), &
                  & Fdifu(1),Fdifu(2),Fdifu(3),Fdifu(4),Fdifu(5),Fdifu(6),Fdifu(7),Fdifu(8),Fdifu(9),Fdifu(10), &
                  & CH4(1),CH4(2),CH4(3),CH4(4),CH4(5),CH4(6),CH4(7),CH4(8),CH4(9),CH4(10), &
                  & CH4_V(1),CH4_V(2),CH4_V(3),CH4_V(4),CH4_V(5),CH4_V(6),CH4_V(7),CH4_V(8),CH4_V(9),CH4_V(10), &
                  & OxiCH4(1),OxiCH4(2),OxiCH4(3),OxiCH4(4),OxiCH4(5),OxiCH4(6),OxiCH4(7),OxiCH4(8),OxiCH4(9),OxiCH4(10)'
            endif
    !        write(outfile,"(A120,A16)") trim(outdir),"/TECO_output.csv"
    !        outfile = trim(outfile)
    !        outfile = adjustl(outfile)
    !        open(83,file=outfile)
            open(83,file='TECO_output.csv')
            write(83,*)'zwt,Tsoil10,Rh_pools(1),Rh_pools(2),Rh_pools(3),Rh_pools(4),Rh_pools(5),&
              & wsc(1),wsc(2),wsc(3),wsc(4),wsc(5),wsc(6),wsc(7),wsc(8),wsc(9),wsc(10), &
              & Tsoil1,Tsoil2,Tsoil3,Tsoil4,Tsoil5,Tsoil6,Tsoil7,Tsoil8,Tsoil9,Tsoil0,dpatm,LAIMAX'


           write(outfile,"(A120,A14)") trim(outdir),"/Simu_snow.csv"
            outfile = trim(outfile)
            outfile = adjustl(outfile)
            open(89,file=outfile)
            write(89,*) "melt,snow_dsim,snow_in,ta"

        endif

!    open(121,file='beforesnow.txt')
!    open(122,file='aftersnow.txt')
! debug
!    write(outfile,"(A120,A11,I3.3,A4)") trim(outdir), "/beforesnow",rep,".txt"
!    outfile=trim(outfile)
!    outfile=adjustl(outfile)
!    open(121,file=outfile)
!
!    write(outfile,"(A120,A10,I3.3,A4)") trim(outdir), "/aftersnow",rep,".txt"
!    outfile=trim(outfile)
!    outfile=adjustl(outfile)
!    open(122,file=outfile)


! ***************************************************************************************
    !    call getarg(5,MCMCargu)
!    read(MCMCargu,'(i1)') MCMC
!    MCMC = 1    ! will be eventually totally replaced by    do_co2_da
!    MCMC = 2 for forecasting function, da need to be false
!    call getarg(6,DAparfile)
!    DAparfile='input/SPRUCE_da_pars.txt'

!            DAparfile='input/SPRUCE_da_pars.txt'   !read from nml
    call GetDAcheckbox(DApar,parmin,parmax,DAparfile,partotal)
    npara=sum(DApar)
    write(*,*) 'GetDAcheckbox npara is',npara
!!       **********************************************************************************************************************
!     added for both DA and forecasting: npara, and coefindex. added when developing forecasting for methane 09/14/2018
    if (do_fcast) then  ! if do fcast and draw parameters from uniform distribution

    !    allocate(paraest((npara),40000))
        allocate(paraest((npara+2),40000))
        allocate(coefindex(npara))
        j=0
        do i=1,partotal
           if (DApar(i).eq. 1) then     !DApar(i) is an indicator of whether do DA for that particular parameter
               j=j+1
               coefindex(j)=i
           endif
        enddo
    endif
!!   **********************************************************************************************************************

!    if(MCMC.eq.1) GOTO 100
    if (do_da) GOTO 110          ! if do any DA goto 100
!    if (MCMC.eq.2) GOTO 150
    if (do_fcast)  GOTO 150
    year_seq = year_seq1
    doy_seq = doy_seq1
    hour_seq = hour_seq1
    forcing_data = forcing_data1
    climatefile = climatefile1
    lines = lines1
    yr_length = yr_length1
    !yrs_eq=yr_length*0  ! spin up length in simulation mode edit there on Nov2018
    !yrs_eq=18+5+5
    yrs_eq=9!18

    call TECO_simu(MCMC,Simu_dailyflux,Simu_hrflux,Simu_soilwater,      &
     &        yrlim,dylim,Ttreat,CO2treat,              &
	 &		  obs_cflux_hr,	&
     &        forcing_data,yr_length,year_seq,doy_seq,hour_seq,lines,   &
     &        fwsoil,topfws,omega,wcl,Storage,nsc,yrs_eq,QC,    &
     &        lat,longi,wsmax,wsmin,LAIMAX,LAIMIN,rdepth,     &
     &        Rootmax,Stemmax,SapR,SapS,SLA,GLmax,GRmax,Gsmax,      &
     &        stom_n,a1,Ds0,Vcmax0,extkU,xfang,alpha,               &
     &        tau_Leaf,tau_Wood,tau_Root,tau_F,tau_C,tau_Micro,     &   ! the unit is year
     &        tau_SlowSOM,tau_Passive,gddonset,                     &
     &        Q10,Q10rh,Rl0,Rs0,Rr0,pi,tauL,rhoL,rhoS,emleaf,emsoil,&
     &    Rconst,sigma,cpair,Patm,Trefk,H2OLv0,airMa,H2OMw,chi,Dheat,&
     &    wleaf,gsw0,eJmx0,theta,conKc0,conKo0,Ekc,Eko,o2ci,JV,&
     &    Eavm,Edvm,Eajm,Edjm,Entrpy,gam0,gam1,gam2,wsc,&
     &    Simu_soiltemp,water_table,snow_in,&
     &    diff_s,diff_snow,albedo_snow,resht,thd_snow_depth,b_bound,&
     &    Simu_watertable,infilt_rate,Simu_dailysoilt,Simu_dailywatertable,Simu_dailywater,&
     &    Simu_snowdepth,Simu_TD,fa,fsub,rho_snow,decay_m,Simu_dailyice,shcap_snow,condu_snow,condu_b,&
     &    depth_ex,r_me,Q10pro,kCH4,Omax,CH4_thre,Tveg,Tpro_me,Toxi,f,bubprob,Vmaxfraction,Simu_dailyCH4,&
     &    do_da,do_fcast,do_snow,do_soilphy,do_co2_da,do_methane_da,do_methane_fcast,do_co2_fcast,do_EBG,output_data,dpatm,&
     &    first_year,yr_length1,nyrmax,is_grass,daily,input_tsoil,use_plinit,partotal,parval,parval2,yk1,&
	 &	  etaL,etaW,etaR,f_F2M,f_C2M,f_C2S,f_M2S,f_M2P,f_S2P,f_S2M,f_P2M)

     close (83)
    write(*,*)'run simulation'
    return
150 continue
        if (do_methane_fcast) then
            call getteco_output(output_data)
        endif
    !   Update posterior parameters
!    paraestfile = trim(outdir),"/Paraest.txt"
!    paraestfile = "Paraest.txt"
     write(paraestfile,"(A120,A20)") trim(outdir),"/Paraest_example.txt"
     paraestfile = trim(paraestfile)
     paraestfile = adjustl(paraestfile)
     call Getparaest(paraestfile,paraest,seq,npara,indexstring)

!    write (my_fmt, '(a,i0,a)') '(',npara,'I12)' us
!    read(indexstring,my_fmt) coefindex          us
!                 write (my_fmt, '(a,i0,a)') '(i12,",",i12,",",',npara,'(F15.4,","))'
!    call getarg(8,yrargu)
!    read(yrargu,'(i4)') yrlim
    yrlim = 2024
!    call getarg(9,dyargu)
!    read(dyargu,'(i3)') dylim
    dylim = 365
!    call getarg(10,Targu)
!    read(Targu,'(f9.3)') Ttreat  add temperature here
    Ttreat = 0.0                                        ! this is for adding temp in forecasting mode, not forward simulation
!    call getarg(11,CO2argu)
!    read(CO2argu,'(f9.3)') CO2treat
    CO2treat = 900.0
! yrlim, dylim should be a early development variable, which is not used in current code
!!!################  assign initials before the forecasting loop begins  #################################################!
    year_seq = year_seq1
    doy_seq = doy_seq1
    hour_seq = hour_seq1
    forcing_data = forcing_data1
    climatefile = climatefile1
    lines = lines1
    yr_length = yr_length1
!    yrs_eq=yr_length*0  ! spin up length  in forecast mode
    yrs_eq=9!18
!   ****************** assign initial value after each forecasting run ***************************
    fwsoil_initial = fwsoil
    topfws_initial = topfws
    omega_initial = omega
    wcl_initial = wcl
    Storage_initial = Storage
    nsc_initial = nsc
!    QC_initial = QC

!    fwsoil=1.0
!    topfws=1.0
!    omega=1.0
!    do i=1,10
!        wcl(i)=wsmax/100.
!    enddo
!    Storage=60.0 !32.09           !g C/m2
!    nsc=85.35
!    QC=QC_initial

!    DAparfile='input/SPRUCE_da_pars_c.txt'
    DAparfile=TRIM(DAparfile)
    DAparfile = adjustl(DAparfile)
    print*,'fcast,DAparfile=',DAparfile,partotal

    call GetDAcheckbox(DApar,parmin,parmax,DAparfile,partotal)

    uniparfile='output/unipar.txt'
    if (do_methane_fcast) then
        open (87,file=uniparfile)   ! methane_fcast, randomly draw posterior parameters related to methane
    elseif (do_co2_fcast) then
        open (88,file=uniparfile)   ! carbon_fcast, randomly draw posterior parameters related to carbon cycle
    endif

  DO rep=1,500
    CALL random_number(randnum)
    Pselect = int(seq/2+randnum*(seq-seq/2))   !select parameter sets that are at the second half of accepted values
!    Pselect = 20
    !Pselect = 10000
    do k1=1,npara
        parval(coefindex(k1))=paraest(k1+2,Pselect)
    enddo
    write (*,*) 'npara=',npara
    if (npara .gt. 8.) then
        SLA = parval(12)
        GLmax = parval(13)
        GRmax = parval(14)
        Gsmax = parval(15)
        Vcmax0 = parval(19)
        Tau_Leaf = parval(23)
        Tau_Wood = parval(24)
        Tau_Root = parval(25)
        Tau_F = parval(26)
        Tau_C = parval(27)
        Tau_Micro = parval(28)
        Tau_slowSOM = parval(29)
        Tau_Passive = parval(30)
        gddonset = parval(31)
        Q10 = parval(32)
        Rl0 = parval(33)
        Rs0 = parval(34)
        Rr0 = parval(35)

        r_me=parval(36)
        Q10pro=parval(37)
        Omax=parval(39)
        Tveg=parval(41)
        f=parval(44)
        bubprob=parval(45)
        Vmaxfraction=parval(46)

        Q10rh = parval(47)
        JV = parval (48)
        Entrpy = parval (49)

		etaL = parval(50)
		etaW = parval(51)
		etaR = parval(52)
		f_F2M = parval(53)
		f_C2M = parval(54)
		f_C2S = parval(55)
		f_M2S = parval(56)
		f_M2P = parval(57)
		f_S2P = parval(58)
		f_S2M = parval(59)
		f_P2M = parval(60)

        write(88,808)rep,SLA,GLmax,GRmax,Gsmax,Vcmax0,Tau_Leaf,Tau_Wood,Tau_Root,Tau_F,Tau_C,Tau_Micro,Tau_slowSOM,Tau_Passive, &
        &  gddonset,Q10,Rl0,Rs0,Rr0,r_me,Q10pro,Omax,Tveg,f,bubprob,Vmaxfraction,Q10rh,JV,Entrpy, &
		&	etaL,etaW,etaR,f_F2M,f_C2M,f_C2S,f_M2S,f_M2P,f_S2P,f_S2M,f_P2M
808     format((i7),",",38(f15.4,","),(f15.4))

    else
        r_me=parval(36)
        Q10pro=parval(37)
        Omax=parval(39)
        Tveg=parval(41)
        f=parval(44)
        bubprob=parval(45)
        Vmaxfraction=parval(46)

        write(87,807)rep,r_me,Q10pro,Omax,Tveg,f,bubprob,Vmaxfraction
807     format((i7),",",6(f15.4,","),(f15.4))

!        r_me=0.0821             ! used in test stage
!        Q10pro=1.4613
!        Omax= 35.53
!        CH4_thre=1400.
!        Tveg=14.5
    endif

    if (do_methane_fcast) then
        write(outfile,"(A120,A14,I3.3,A4)") trim(outdir), "/Simu_dailyCH4",rep,".txt"
        outfile=trim(outfile)
        outfile=adjustl(outfile)
        open(64,file=outfile)
        write (64,*)'day,simuCH4_d,pro_sum_d,oxi_sum_d,fdifu1_d,ebu_sum_sat_d,pla_sum_d,&
        & CH4V1,CH4V2,CH4V3,CH4V4,CH4V5,CH4V6,CH4V7,CH4V8,CH4V9,CH4V10,ebu_sum_unsat_d,zwt'
    elseif (do_co2_fcast) then
        write(outfile,"(A120,A15,I3.3,A4)") trim(outdir),"/Simu_dailyflux",rep,".txt"
        outfile = trim(outfile)
        outfile = adjustl(outfile)
        open(62,file=outfile)
        write(62,*)'sdoy,GPP_d,NEE_d,Reco_d,QC(1),QC(6),QC(2),QC(7),&
				& QC(3),QC(4),QC678,pheno,QC(5),NPP_d,Rh_d,Ra_d'

     	   write(outfile,"(A120,A14,I3.3,A4)") trim(outdir), "/Simu_dailybal",rep,".txt"
           outfile=trim(outfile)
           outfile=adjustl(outfile)
           open(70,file=outfile)
        write (70,*)'isimu,swc1,swc2,swc3,st1,st2'
!
!        write(outfile,"(A120,A23)") trim(outdir),"/Simu_dailywater001.txt"
!        outfile = trim(outfile)
!        outfile = adjustl(outfile)
!        open(63,file=outfile)
!    !    write(63,*)'wcl1,wcl2,wcl3,wcl4,wcl5,wcl6,wcl7,wcl8,wcl9,wcl10,zwt'
!        write(63,*)'day,wcl1,wcl2,wcl3,wcl4,wcl5,wcl6,wcl7,wcl8,wcl9,wcl10,liq_water1,liq_water2,liq_water3,&
!        & liq_water4,liq_water5,liq_water6,liq_water7,liq_water8,liq_water9,liq_water10,ice1,ice2,ice3,ice4,&
!        & ice5,ice6,ice7,ice8,ice9,ice10,zwt'
!        write(outfile,"(A120,A24)") trim(outdir),"/Simu_dailyflux14001.txt"
!        outfile = trim(outfile)
!        outfile = adjustl(outfile)
!        open(662,file=outfile)
!        write(662,*)'sdoy, GPP_d, NEE_d, Reco_d, NPP_d, Ra_d, QC1, QC2, QC3, add, storage, LAIMAX, Rh_d, LAI, Tleaf(1)'
!!            write(662,*)'sdoy, QC1, QC2, QC3, QC4, QC5, QC6, QC7, QC8, add, storage, LAIMAX, Rh_d, LAI, Tleaf(1)'
!    ! end of inserting
!
!        write(outfile,"(A120,A18)") trim(outdir),"/Simu_dailyCH4.txt"
!        outfile = trim(outfile)
!        outfile = adjustl(outfile)
!        open(64,file=outfile)
!        write (64,*)'day,simuCH4_d,pro_sum_d,oxi_sum_d,fdifu1_d,ebu_sum_sat_d,pla_sum_d,CH4V1,CH4V2,CH4V3,CH4V4,CH4V5,  &
!        &  CH4V6,CH4V7,CH4V8,CH4V9,CH4V10,ebu_sum_unsat_d,zwt'
!
!    ! ..int
!        write(outfile,"(A120,A18)") trim(outdir),"/Simu_soiltemp.txt"
!        outfile = trim(outfile)
!        outfile = adjustl(outfile)
!        open(65,file=outfile)
!
!        write(outfile,"(A120,A18)") trim(outdir),"/Simu_dailyice.txt"
!        outfile = trim(outfile)
!        outfile = adjustl(outfile)
!        open(66,file=outfile)
!
!            write(outfile,"(A120,A21,I3.3,A4)") trim(outdir), "/Simu_dailywatertable",1,".txt"
!            outfile=trim(outfile)
!            outfile=adjustl(outfile)
!            open(67,file=outfile)
!
!            write(outfile,"(A120,A22)") trim(outdir), "/Simu_snowdepth001.txt"
!            outfile=trim(outfile)
!            outfile=adjustl(outfile)
!            open(68,file=outfile)
!            write(68,*)'day,snowdepth'
!
!            write(outfile,"(A120,A22)") trim(outdir), "/Simu_thawdepth001.txt"
!            outfile=trim(outfile)
!            outfile=adjustl(outfile)
!            open(69,file=outfile)
    endif


!   *****************************************************

    call TECO_simu(MCMC,Simu_dailyflux,Simu_hrflux,Simu_soilwater,      &
     &        yrlim,dylim,Ttreat,CO2treat,              &
	 &		  obs_cflux_hr,	&
     &        forcing_data,yr_length,year_seq,doy_seq,hour_seq,lines,   &
     &        fwsoil,topfws,omega,wcl,Storage,nsc,yrs_eq,QC,    &
     &        lat,longi,wsmax,wsmin,LAIMAX,LAIMIN,rdepth,     &
     &        Rootmax,Stemmax,SapR,SapS,SLA,GLmax,GRmax,Gsmax,      &
     &        stom_n,a1,Ds0,Vcmax0,extkU,xfang,alpha,               &
     &        tau_Leaf,tau_Wood,tau_Root,tau_F,tau_C,tau_Micro,     &   ! the unit is year
     &        tau_SlowSOM,tau_Passive,gddonset,                     &
     &        Q10,Q10rh,Rl0,Rs0,Rr0,pi,tauL,rhoL,rhoS,emleaf,emsoil,&
     &    Rconst,sigma,cpair,Patm,Trefk,H2OLv0,airMa,H2OMw,chi,Dheat,&
     &    wleaf,gsw0,eJmx0,theta,conKc0,conKo0,Ekc,Eko,o2ci,JV,&
     &    Eavm,Edvm,Eajm,Edjm,Entrpy,gam0,gam1,gam2,wsc,&
     &    Simu_soiltemp,water_table,snow_in,&
     &    diff_s,diff_snow,albedo_snow,resht,thd_snow_depth,b_bound,&
     &    Simu_watertable,infilt_rate,Simu_dailysoilt,Simu_dailywatertable,Simu_dailywater,&
     &    Simu_snowdepth,Simu_TD,fa,fsub,rho_snow,decay_m,Simu_dailyice,shcap_snow,condu_snow,condu_b,&
     &    depth_ex,r_me,Q10pro,kCH4,Omax,CH4_thre,Tveg,Tpro_me,Toxi,f,bubprob,Vmaxfraction,Simu_dailyCH4,&
     &    do_da,do_fcast,do_snow,do_soilphy,do_co2_da,do_methane_da,do_methane_fcast,do_co2_fcast,do_EBG,output_data,dpatm,&
     &    first_year,yr_length1,nyrmax,is_grass,daily,input_tsoil,use_plinit,partotal,parval,parval2,yk1,&
	 &	  etaL,etaW,etaR,f_F2M,f_C2M,f_C2S,f_M2S,f_M2P,f_S2P,f_S2M,f_P2M)
    write(*,*)'run forecasting',rep

    close(62)
    close(63)
    close(662)
    close(70)
    close(64)
!    close(121)
!    close(122)
!       update the initial condition after each forecast run
        fwsoil = fwsoil_initial
        topfws = topfws_initial
        omega = omega_initial
        wcl = wcl_initial
        Storage=Storage_initial
        nsc=nsc_initial
        QC = QC_initial

  enddo ! END of rep

    if (do_methane_fcast) then
            close(87)
    elseif (do_co2_fcast) then
            close(88)
    endif


    deallocate(paraest)

    return

110 continue
    if (do_methane_da) then
        call getteco_output(output_data)
    endif

    write(outfile,"(A120,A12)") trim(outdir),"/Paraest.txt"
    outfile = trim(outfile)
    outfile = adjustl(outfile)
    open(71,file=outfile)  ! 71 is the paraest file  start write in para value

    year_seq = year_seq1
    doy_seq = doy_seq1
    hour_seq = hour_seq1
    forcing_data = forcing_data1
    climatefile = climatefile1
    lines = lines1
    yr_length = yr_length1
!      *** assign initial value before DA runs
    fwsoil_initial = fwsoil
    topfws_initial = topfws
    omega_initial = omega
    wcl_initial = wcl
    Storage_initial = Storage
    nsc_initial = nsc


    npara=sum(DApar)
    allocate(coef(npara),coefac(npara),coefnorm(npara))
    allocate(coefindex(npara))
    allocate(coefmax(npara),coefmin(npara))
    allocate(gamma(npara,npara),gamnew(npara,npara))
    allocate(coefhistory(ncov,npara))
!	DA begins here, coef,coefmin,coefmax correspond to parval, parmax and parmin
    J_last=9000000.0
    IDUM = 542
    upgraded=0
    new=0
    k3=0
    j=0
!  below is webpage version of giving the coef min max, for JJ carbon, after integration, all da pars read in need to be changed
    do i=1,partotal
       if (DApar(i).eq. 1) then     !DApar(i) is an indicator of whether do DA for that particular parameter
           j=j+1
           coef(j)=parval(i)        !define initial value for parameters, equal to the parameter file value
           coefindex(j)=i
           coefmin(j)=parmin(i)     !define min value for parameters
           coefmax(j)=parmax(i)     !define min value for parameters
       endif
    enddo
!    write(71,*) npara                      !???
!    write(71,*)(coefindex(i),i=1,npara)    !???
!    write(*,*) "stoooop"

    ! initialize covariance matrix
    covexist=0 ! give an initial value for covexist, updated inside of the isimu loop
    if(covexist.eq.1)then      ! If prior covariance exists, read from file

        write(covfile,"(A120,A15)") trim(outdir),"/covariance.txt"
        covfile = trim(covfile)
        covfile = adjustl(covfile)
        call getCov(gamma,covfile,npara)

        call racine_mat(gamma,gamnew,npara)      ! square root of covariance matrix
        gamma=gamnew
        do k1=1,npara
!           coefnorm(k1)=(coef(k1)-coefmin(k1))/(coefmax(k1)-coefmin(k1))
            coefnorm(k1)=0.5
            coefac(k1)=coefnorm(k1)
        enddo
    else

        coefac=coef
    endif

    fact_rejet=2.4/sqrt(real(npara))
    search_length=0.05
    rejet = 0

    do isimu=1,50000
!   generate parameters as coef, in each round of isimu, the new coef is generated based on the old coef, connected with coefac
        if(covexist.eq.1)then
			write (*,*) "covexist=1"
            paraflag=1
            do while(paraflag.gt.0)
                call gengaussvect(fact_rejet*gamma,coefac,coefnorm,npara)
                paraflag=0
                do k1=1,npara
                    if(coefnorm(k1).lt.0. .or. coefnorm(k1).gt.1.)then
                    paraflag=paraflag+1
                    write(*,*)'out of range',paraflag
                    endif
                enddo
            enddo
            do k1=1,npara
                coef(k1)=coefmin(k1)+coefnorm(k1)*(coefmax(k1)-coefmin(k1))
            enddo
        else
				write (*,*) "covexist=0"
            call coefgenerate(coefac,coefmax,coefmin,coef,search_length,npara)
        endif

!         update parameters
        do k1=1,npara
			! parval(coefindex(k1))=coef(k1)
            parval2(coefindex(k1))=coef(k1)
        enddo
		! write (*,*) "parval",parval
		! write (*,*) "parval2",parval2
! 	**** start
!        use to assign with updated parameter values, now these lines are commented and updated inside of TECO_simu subroutine
! !        if (do_co2_da) then
        ! if (do_da) then
            ! SLA = parval(12)        ! par values generated by subroutine coefgenerate
            ! GLmax = parval(13)      ! update all the parameters in this step no matter changed or not
            ! GRmax = parval(14)      ! only the parameters used in DA will change the value, others are updated with the same value
            ! Gsmax = parval(15)
            ! Vcmax0 = parval(19)
            ! Tau_Leaf = parval(23)
            ! Tau_Wood = parval(24)
            ! Tau_Root = parval(25)
            ! Tau_F = parval(26)
            ! Tau_C = parval(27)
            ! Tau_Micro = parval(28)
            ! Tau_slowSOM = parval(29)
            ! Tau_Passive = parval(30)
            ! gddonset = parval(31)
            ! Q10 = parval(32)
            ! Rl0 = parval(33)
            ! Rs0 = parval(34)
            ! Rr0 = parval(35)
            ! Q10rh=parval(47)
            ! JV = parval (48)
            ! Entrpy = parval (49)

            ! r_me=parval(36)                                                !para in methane production
            ! Q10pro=parval(37)
            ! Omax=parval(39)                                            	!para in methane oxidation
            ! Tveg=parval(41)
            ! f=parval(44)
            ! bubprob=parval(45)
            ! Vmaxfraction=parval(46)
! !        elseif (do_methane_da) then
! !            r_me=parval(36)                                                !para in methane production
! !            Q10pro=parval(37)
! !            Omax=parval(39)                                            	!para in methane oxidation
! !!            CH4_thre=parval(40)
! !            Tveg=parval(41)
! !!            r_me=0.0821             ! used in test DA stage

! !!            Q10pro=1.4613
! !!            Omax= 35.53

! !!            CH4_thre=1400.
! !!            Tveg=14.5
! !            f=parval(44)
! !            bubprob=parval(45)
! !            Vmaxfraction=parval(46)
        ! endif
! 	**** end
!	  use to assign with updated parameter values, now these lines are commented and updated inside of TECO_simu subroutine

        yrs_eq = 9!18      ! spin up equilibrium run for DA modes
        call TECO_simu(MCMC,Simu_dailyflux,Simu_hrflux,Simu_soilwater,      &
     &        yrlim,dylim,Ttreat,CO2treat,              &
	 &		  obs_cflux_hr,	&
     &        forcing_data,yr_length,year_seq,doy_seq,hour_seq,lines,   &
     &        fwsoil,topfws,omega,wcl,Storage,nsc,yrs_eq,QC,    &
     &        lat,longi,wsmax,wsmin,LAIMAX,LAIMIN,rdepth,     &
     &        Rootmax,Stemmax,SapR,SapS,SLA,GLmax,GRmax,Gsmax,      &
     &        stom_n,a1,Ds0,Vcmax0,extkU,xfang,alpha,               &
     &        tau_Leaf,tau_Wood,tau_Root,tau_F,tau_C,tau_Micro,     &   ! the unit is year
     &        tau_SlowSOM,tau_Passive,gddonset,                     &
     &        Q10,Q10rh,Rl0,Rs0,Rr0,pi,tauL,rhoL,rhoS,emleaf,emsoil,&
     &    Rconst,sigma,cpair,Patm,Trefk,H2OLv0,airMa,H2OMw,chi,Dheat,&
     &    wleaf,gsw0,eJmx0,theta,conKc0,conKo0,Ekc,Eko,o2ci,JV,&
     &    Eavm,Edvm,Eajm,Edjm,Entrpy,gam0,gam1,gam2,wsc,&
     &    Simu_soiltemp,water_table,snow_in,&
     &    diff_s,diff_snow,albedo_snow,resht,thd_snow_depth,b_bound,&
     &    Simu_watertable,infilt_rate,Simu_dailysoilt,Simu_dailywatertable,Simu_dailywater,&
     &    Simu_snowdepth,Simu_TD,fa,fsub,rho_snow,decay_m,Simu_dailyice,shcap_snow,condu_snow,condu_b,&
     &    depth_ex,r_me,Q10pro,kCH4,Omax,CH4_thre,Tveg,Tpro_me,Toxi,f,bubprob,Vmaxfraction,Simu_dailyCH4,&
     &    do_da,do_fcast,do_snow,do_soilphy,do_co2_da,do_methane_da,do_methane_fcast,do_co2_fcast,do_EBG,output_data,dpatm,&
     &    first_year,yr_length1,nyrmax,is_grass,daily,input_tsoil,use_plinit,partotal,parval,parval2,yk1,&
	 &	  etaL,etaW,etaR,f_F2M,f_C2M,f_C2S,f_M2S,f_M2P,f_S2P,f_S2M,f_P2M)

!         M-H algorithm
        tmp_up=upgraded
! ..int JJ carbon version cost function
!        call costFObsNee(Simu_dailyflux,   &
!            &   obs_carbon,std,len1,   &
!            &   J_last,upgraded)
! ..int CWE version cost function
        call costFObsNee(Simu_dailyflux,Simu_hrflux,Simu_soilwater,Simu_soiltemp,Simu_dailysoilt, &
		 & Simu_dailywatertable,Simu_dailywater,Simu_snowdepth,Simu_TD,Simu_dailyCH4, &
                 & obs_cflux,obs_cflux_hr,obs_cpool,obs_ch4flux,obs_ch4conc, &
		 & obs_soilwater,obs_soilt,obs_snow,obs_wt,obs_td,obs_soilprofc, &
                 & std_cflux,std_cflux_hr,std_cpool,std_ch4flux,std_ch4conc, &
		 & std_soilwater,std_soilt,std_snow,std_wt,std_td, &
                 & len_cflux,len_cflux_hr,len_cpool,len_ch4flux,len_ch4conc,len_sw,len_st,len_snow,len_wt,len_td,yr_length1, &
		 & J_last,upgraded,isimu,JNAN, &
                 & do_soilt_da,do_snow_da,do_watertable_da,do_methane_da,do_co2_da,do_soilwater_da, &
                 & use_cflux_ob,use_cflux_hr_ob,use_cpool_ob,use_ch4flux_ob,use_ch4conc_ob, &
		 & use_soilwater_ob,use_soilt_ob,use_snow_ob,use_watertable_ob,use_td_ob,use_plinit)
        if(upgraded.gt.tmp_up)then
            new=new+1
            if(covexist.eq.1)then           ! covexist=0
                coefac=coefnorm
                coefhistory(new,:)=coefnorm
            else
                coefac=coef
                do k1=1,npara
                    coefnorm(k1)=(coef(k1)-coefmin(k1))/(coefmax(k1)-coefmin(k1))
                enddo
            endif
            coefhistory(new,:)=coefnorm
            if(new.ge.ncov)new=0

            write (my_fmt, '(a,i0,a)') '(i12,",",i12,",",',npara,'(F15.4,","))'
                write(71,my_fmt)isimu, upgraded,(coef(i),i=1,npara)
!		save files for DA output 	daily is updated as the last day of the year, 365, yk1 is updated as the last row of obs_hr
                if(upgraded.gt.1500 .and. k3.lt.800)then
                CALL random_number(r)
                if(r.gt.0.95)then
                    k3=k3+1
                    if (do_methane_da) then
                        write(outfile,"(A120,A14,I3.3,A4)") trim(outdir), "/Simu_dailyCH4",k3,".txt"
                        outfile=trim(outfile)
                        outfile=adjustl(outfile)
                        open(64,file=outfile)
                        write (64,*)'day,isimu,simuCH4_d,pro_sum_d,oxi_sum_d,fdifu1_d,ebu_sum_sat_d,pla_sum_d,&
                        & CH4V1,CH4V2,CH4V3,CH4V4,CH4V5,CH4V6,CH4V7,CH4V8,CH4V9,CH4V10,ebu_sum_unsat_d'
                        do i=1,daily
                            write(64,6044)i,isimu,(Simu_dailyCH4(j,i),j=1,17)
                        enddo
6044                     format((i7),",",(i7),",",16(f15.4,","),(f15.4))
                        close(64)
!                    if (do_methane_da) then
                        open(85,file='fivehparasinMEMCMC.txt')
                        write(85,*)'k3,r_me,Q10pro,Omax,Tveg,f,bubprob,Vmaxfraction'
!                    endif
                    write(85,805)k3,r_me,Q10pro,Omax,Tveg,f,bubprob,Vmaxfraction       !stochastically save 500 parameter set
805                 format((i7),",",7(f15.4,","))

                    elseif (do_da) then
                        write(outfile,"(A120,A15,I3.3,A4)") trim(outdir), "/Simu_dailyflux",k3,".txt"
                        outfile=trim(outfile)
                        outfile=adjustl(outfile)
                        open(62,file=outfile)
                        write (62,*)'day,isimu,GPP_d,NEE_d,Reco_d,QC(1),QC(6),QC(2),QC(7),&
                        & QC(3),QC(4),QC678,pheno,QC(5),NPP_d,Rh_d, Ra_d'
                        do i=1,daily
                            write(62,602)i,isimu,(Simu_dailyflux(j,i),j=1,15)
!                            write (*,*) 'i',i,'Simu_dailyflux',Simu_dailyflux(2,i)
                        enddo
602                    format((i7),",",(i7),",",14(f15.4,","),(f15.4))
                        close(62)
! .. int add more ouput files
                        ! ** add Tsoil WSC and watertable to evaluate the balance
                        ! write(outfile,"(A120,A14,I3.3,A4)") trim(outdir), "/Simu_dailybal",k3,".txt"
                        ! outfile=trim(outfile)
                        ! outfile=adjustl(outfile)
                        ! open(70,file=outfile)
                        ! write (70,*)'isimu,wcl1,wcl2,wcl3,st1,st2'
                        ! do i=1,daily
                            ! write(70,700)i,(Simu_dailywater(j,i),j=11,13),(Simu_dailysoilt(j,i),j=2,3)
                        ! enddo
! 700                 format((i7),",",4(f15.4,","),(f15.4))
                        ! close(70)
                        ! ** add hourly output to evaluate the DA mismatch
                        write(outfile,"(A120,A12,I3.3,A4)") trim(outdir), "/Simu_hrflux",k3,".txt"
                        outfile=trim(outfile)
                        outfile=adjustl(outfile)
                        open(74,file=outfile)
                        write (74,*)'obsrow,gpp,nee,reco,ch4'
                        do i=1,yk1
                            write(74,704)i,Simu_hrflux(1,i),Simu_hrflux(2,i), Simu_hrflux(3,i),Simu_hrflux(4,i)
                        enddo
704                 format((i7),",",3(f15.4,","),(f15.4))
                        close(74)

                        write(outfile,"(A120,A14,I3.3,A4)") trim(outdir), "/Simu_dailyCH4",k3,".txt"
                        outfile=trim(outfile)
                        outfile=adjustl(outfile)
                        open(64,file=outfile)
                        write (64,*)'day,isimu,simuCH4_d,pro_sum_d,oxi_sum_d,fdifu1_d,ebu_sum_sat_d,pla_sum_d,&
                        & CH4V1,CH4V2,CH4V3,CH4V4,CH4V5,CH4V6,CH4V7,CH4V8,CH4V9,CH4V10,ebu_sum_unsat_d'
                        do i=1,daily
                            write(64,60444)i,isimu,(Simu_dailyCH4(j,i),j=1,17)
                        enddo
60444                     format((i7),",",(i7),",",16(f15.4,","),(f15.4))
                        close(64)

!                        write(outfile,"(A120,A15,I3.3,A4)") trim(outdir), "/Simu_soilwater",k3,".txt"
!                        outfile=trim(outfile)
!                        outfile=adjustl(outfile)
!                        open(63,file=outfile)
!                        do i=1,2192
!                            write(63,603)i,(Simu_soilwater(j,i),j=1,10)
!                        enddo
!    603                 format((i7),",",10(f15.4,","))
!                        close(63)
!
!                        write(outfile,"(A120,A20,I3.3,A4)") trim(outdir), "/Simu_soiltemp_daily",k3,".txt"
!                        outfile=trim(outfile)
!                        outfile=adjustl(outfile)
!                        write(*,*)'outfile',outfile
!                        open(65,file=outfile)
!                        do i=1,2192
!                            write(65,605)i,(Simu_dailysoilt(j,i),j=1,11)
!                        enddo
!    605                 format((i7),",",10(f15.4,","),(f15.4))
!                        close(65)
!                        write(outfile,"(A120,A15,I3.3,A4)") trim(outdir), "/Simu_ice_daily",k3,".txt"
!                        outfile=trim(outfile)
!                        outfile=adjustl(outfile)
!                        write(*,*)'outfile',outfile
!                        open(66,file=outfile)
!                        do i=1,2192
!                            write(66,606)i,(Simu_dailyice(j,i),j=1,10)
!                        enddo
!    606                 format((i7),",",9(f15.4,","),(f15.4))
!                        close(66)
!
!                    write(outfile,"(A120,A15,I3.3,A4)") trim(outdir), "/Simu_snowdepth",k3,".txt"
!                    outfile=trim(outfile)
!                    outfile=adjustl(outfile)
!                    write(*,*)'outfile',outfile
!                    open(68,file=outfile)
!                    do i=1,daily
!                        write(68,608)i,(Simu_snowdepth(j,i),j=1,1)
!                    enddo
!608                 format((i7),",",1(f15.4,","))
!                    close(68)
!
!		   write(outfile,"(A120,A15,I3.3,A4)") trim(outdir), "/Simu_thawdepth",k3,".txt"
!                   outfile=trim(outfile)
!                   outfile=adjustl(outfile)
!                    write(*,*)'outfile',outfile
!                    open(69,file=outfile)
!                    do i=1,daily
!                        write(69,608)i,(Simu_TD(j,i),j=1,1)
!                    enddo
!                    close(69)
!
                    endif
                endif
            endif
        else
            reject=reject+1
        endif
!       return the initial condition after each run
        fwsoil = fwsoil_initial
        topfws = topfws_initial
        omega = omega_initial
        wcl = wcl_initial
        Storage=Storage_initial
        nsc=nsc_initial
        QC = QC_initial

!        write(*,*)'isimu',isimu,'upgraded',upgraded

    	! updates of the multiplicative constant
        if(covexist.eq.1)then
            if(mod(isimu,nc).eq.0)then
                if ((1. - real(rejet)/real(nc)) < 0.23) then
                !    fact_rejet = fact_rejet*0.9
                else
                    if ((1. - real(rejet)/real(nc)) > 0.44) then
                !    fact_rejet = fact_rejet * 1.1
                    endif
                endif
            rejet=0
            write(*,*)'search length is', search_length
            endif
        else
            if(mod(isimu,nc).eq.0)then
                if(real(upgraded)/real(isimu) .lt. 0.23)then
                !    search_length=search_length*0.9
                else
                    if(real(upgraded)/real(isimu) .gt. 0.44)then
                !        search_length=search_length*1.1
                    endif
                endif
                reject=0
                write(*,*)'search length is', search_length
            endif
        endif

	! updates of the covariance matrix

        if(covexist.eq.0 .and. mod(upgraded,ncov).eq.0 .and. upgraded .ne. 0)then
            covexist=1
            coefac=coefnorm
!            print*,'coefhistory',coefhistory
            print*,'using covarance matrix1'
            call varcov(coefhistory,gamnew,npara,ncov)
            if (.not.(all(gamnew==0.))) then
                gamma=gamnew
                call racine_mat(gamma,gamnew,npara)
                gamma=gamnew
            endif
        endif
	if (mod(upgraded,ncov).eq.0 .and. covexist.eq.1 .and. upgraded .ne. 0) then
            print*,'using covarance matrix2'
            call varcov(coefhistory,gamnew,npara,ncov)
            if (.not.(all(gamnew==0.))) then
                gamma=gamnew
                call racine_mat(gamma,gamnew,npara)
                gamma=gamnew
            endif
	endif
        !print*,'end of loop'

    enddo !isimu
    !write(outfile,"(A120,A21)") trim(outdir),"/covvariance_temp.txt"
    !outfile = trim(outfile)
    !outfile = adjustl(outfile)
    !open(72,file=outfile)
    !do i=1,npara
    !    write(72,*) (gamma(j,i),j=1,npara)
    !enddo
    !close(72)
    close(61)

    close(71)

    deallocate(coef,coefac,coefnorm)
    deallocate(coefindex)
    deallocate(coefmax,coefmin)
    deallocate(gamma,gamnew)
    deallocate(coefhistory)

    write(*,*)'run MCMC'
    end


! ====================================================================
    subroutine TECO_simu(MCMC,Simu_dailyflux,Simu_hrflux,Simu_soilwater,      &
     &        yrlim,dylim,Ttreat,CO2treat,              &
	 &		  obs_cflux_hr,	&
     &        forcing_data,yr_length,year_seq,doy_seq,hour_seq,lines,   &
     &        fwsoil,topfws,omega,wcl,Storage,nsc,yrs_eq,QC,    &
     &        lat,longi,wsmax,wsmin,LAIMAX,LAIMIN,rdepth,     &
     &        Rootmax,Stemmax,SapR,SapS,SLAx,GLmx,GRmx,Gsmx,      &
     &        stom_n,a1,Ds0,Vcmax0,extkU,xfang,alpha,               &
     &        tau_L,tau_W,tau_R,tau_F,tau_C,tau_Micr,     &   ! the unit is year
     &        tau_Slow,tau_Pass,gddonset,                     &
     &        Q10,Q10rh,Rl0,Rs0,Rr0,pi,tauL,rhoL,rhoS,emleaf,emsoil,&
     &    Rconst,sigma,cpair,Patm,Trefk,H2OLv0,airMa,H2OMw,chi,Dheat,&
     &    wleaf,gsw0,eJmx0,theta,conKc0,conKo0,Ekc,Eko,o2ci,JV,&
     &    Eavm,Edvm,Eajm,Edjm,Entrpy,gam0,gam1,gam2,wsc,&
     &    Simu_soiltemp,water_table,snow_in,&
     &    diff_s,diff_snow,albedo_snow,resht,thd_snow_depth,b_bound,&
     &    Simu_watertable,infilt_rate,Simu_dailysoilt,Simu_dailywatertable,Simu_dailywater,&
     &    Simu_snowdepth,Simu_TD,fa,fsub,rho_snow,decay_m,Simu_dailyice,shcap_snow,condu_snow,condu_b,&
     &    depth_ex,r_me,Q10pro,kCH4,Omax,CH4_thre,Tveg,Tpro_me,Toxi,f,bubprob,Vmaxfraction,Simu_dailyCH4,&
     &    do_da,do_fcast,do_snow,do_soilphy,do_co2_da,do_methane_da,do_methane_fcast,do_co2_fcast,do_EBG,output_data,dpatm,&
     &    first_year,yr_length1,nyrmax,is_grass,daily,input_tsoil,use_plinit,partotal,parval,parval2,yk1,&
	 &	  etaL,etaW,etaR,f_F2M,f_C2M,f_C2S,f_M2S,f_M2P,f_S2P,f_S2M,f_P2M)

      implicit none

   !==================== test variables
    real fwsoil_yr,omega_yr,topfws_yr, difference,diff_yr,diff_d

      integer, parameter :: iiterms=18            ! added 11 for Tsoil
      integer, parameter :: ilines=150000         ! the maxmum records of Duke Face, 1998~2007
      integer :: nyrmax,use_plinit
      real, parameter:: times_storage_use=720.   ! 720 hours, 30 days
      integer  lines,idays,MCMC
      integer,dimension(ilines):: year_seq,doy_seq,hour_seq
      real forcing_data(iiterms,ilines),input_data(iiterms,ilines)
	! before and after 2014
	  integer partotal
	  real,dimension(partotal) :: parval,parval2
!   *** before ..int
!      real Simu_dailyflux(15,10000)
      real Simu_dailyflux14(14,nyrmax*365)
      real Simu_dailywater(31,nyrmax*365)
      real TD
!      real obs_carbon(12,1000)
!      integer pheno,phenoset
!      site specific parameters
!   ***
	  real :: obs_cflux_hr(7,yr_length1*500)!,obs_soilwater(5,yr_length1*365)
!   *** after ..int
      real,intent(inout) ::  Simu_dailyflux(15,nyrmax*365),Simu_soilwater(30,nyrmax*365),Simu_soiltemp(11,nyrmax*365)
	  real,intent(inout) ::  Simu_hrflux(4,nyrmax*500)
      real,intent(inout) ::  Simu_watertable(1,nyrmax*365),Simu_dailysoilt(11,nyrmax*365),Simu_dailywatertable(1,nyrmax*365)
      real,intent(inout) ::  Simu_dailyice(10,nyrmax*365)
      real,intent(inout) ::  Simu_snowdepth(1,nyrmax*365),Simu_TD(1,nyrmax*365),Simu_dailyCH4(17,nyrmax*365)
      real water_table(ilines),snow_in(ilines)
!      real obs_carbon(12,1000),obs_soilwater(5,40000),obs_soilt(11,40000)  !!look back and correct
      integer yr_length1
!      real :: obs_soilt(11,yr_length1*365),obs_carbon(12,yr_length1*365),obs_soilwater(5,yr_length1*365)
      integer pheno,phenoset,day_mod,num
!   ***

      real lat,longi,rdepth,LAIMAX,LAIMIN
      real wsmax,wsmin,co2ca,CO2treat
      real tau_L,tau_W,tau_R
      real tau_F,tau_C,tau_Micr,tau_Slow,tau_Pass
      real TauC(8)
!      the variables that should be initialized in the begining
      real Q_soil
      real QC(8) !  leaf,wood,root,fine lit.,coarse lit.,Micr,Slow,Pass
      real Pool1,Pool2,Pool3,Pool4,Pool5,Pool6,Pool7,Pool8
      real out1_yr,out2_yr,out3_yr,out4_yr,out5_yr,out6_yr,out7_yr,out8_yr
      real OutC(8)
      real Rh_pools(5)
!      for soil conditions
      real WILTPT,FILDCP,infilt
      real Rsoilabs
      real fwsoil,topfws,omega
!      for plant growth and allocation
      real NSC,NSCmin,NSCmax,add               ! none structural carbon pool
      real Growth,Groot,Gshoot,GRmax           ! growth rate of plant,root,shoot,and max of root
      real St,Sw,Ss,Sn,Srs,Sps,fnsc,Weight     ! scaling factors for growth
!      variables for canopy model


      real evap,transp,ET,G

!      real evap,transp,ET
!!   *** ..int

      real wind,eairp,esat,rnet
      real Pa_air
      real gpp,gpp_ra,NPP,NEE,NEP,gpp_d,NPP_d
      real evap_d,transp_d
      real,dimension(3):: tauL,rhoL,rhoS,reffbm,reffdf,extkbm,extkdm
      real,dimension(2):: Radabv
      real Qcan(3,2)
!      parameters for photosynthesis model
      real stom_n,a1,Ds0,Vcmx0,Vcmax0,extkU,xfang,alpha
      real pi,emleaf,emsoil
      real Rconst,sigma,cpair,Patm,Trefk,H2OLv0,airMa,H2OMw,chi,Dheat
      real wleaf,gsw0,eJmx0,theta,conKc0,conKo0,Ekc,Eko,o2ci,JV         ! added JV for acclimation study Feb 19 2019
      real Eavm,Edvm,Eajm,Edjm,Entrpy,gam0,gam1,gam2
!     for nitrogen sub-model
      real CNmin,CNmax,NSNmax,NSNmin
      real NSN
!      QNleaf,QNwood,QNroot,QNfine,QNcoarse,QNmicr,QNslow,QNpass
!      CN_leaf,CN_wood,CN_root,CN_fine,CN_coarse,CN_micr,CN_slowC,CN_pass
      real QN(8),CN0(8),CN(8),OutN(8),QNplant,QNminer
      real N_leaf,N_wood,N_root,N_deficit,N_immob
      real N_LF,N_WF,N_RF
      real N_uptake,N_leach,N_vol,N_fixation,N_deposit,N_fert
      real N_up_d,N_fix_d,N_dep_d,N_leach_d,N_vol_d
      real N_up_yr,N_fix_yr,N_dep_yr,N_leach_yr,N_vol_yr,N_tran_yr,N_def_yr,QNmin_yr,N_min_yr,N_imb_yr
      real N_miner,alphaN
      real SNvcmax,SNgrowth,SNRauto,SNrs
!   ***   .. int add pars for soil thermal
      real diff_s,diff_snow,albedo_snow,resht,thd_snow_depth,shcap_snow,condu_snow,depth_ex
      real infilt_rate
      real b_bound,fa,fsub,rho_snow,decay_m,condu_b
!   ***
!      additional arrays to allow output of info for each layer
      real,dimension(5):: RnStL,QcanL,RcanL,AcanL,EcanL,HcanL
      real,dimension(5):: GbwcL,GswcL,hG,hIL
      real,dimension(5):: Gaussx,Gaussw,Gaussw_cum
!      for phenology
      real LAI,bmroot,bmstem,bmleaf,bmplant,totlivbiom,ht
      real SLA,SLAx,L_fall,L_add,litter,seeds
      real GDDonset,GDD5,accumulation,storage,stor_use,store
      real RaL,RaS,RaR  !allocation to respiration
      real alpha_L,alpha_W,alpha_R ! allocation ratio to Leaf, stem, and Root
      real Q10,Rl0,Rs0,Rr0,Q10rh         ! parameters for auto respiration, Q10rh added for acclimation study on Rh
      real Rgrowth,Rnitrogen,Rmain,Rauto !respirations
      real RmLeaf,RmStem,RmRoot          ! maintanence respiration
      real RgLeaf,RgStem,RgRoot          ! growth respiration
      real RaLeaf,RaStem,RaRoot
      real Rsoil,Rhetero,Rtotal
      real Ra_Nfix,Rh_Nfix
      real gpp_yr,NPP_yr,NEE_yr,RaL_yr,RaR_yr,RaS_yr,Rh_yr,NSN_yr,NSC_yr,add_yr,store_yr,radsol_yr,VcmxT_yr,VcmxT
      real Rh4_yr,Rh5_yr,Rh6_yr,Rh7_yr,Rh8_yr,Ra_yr
      real R_Ntr_yr
      real NPPL_yr,NPPR_yr,NPPS_yr,NPP_L,NPP_R,NPP_W
      real Rootmax,Stemmax,SapS,SapR,StemSap,RootSap
      REAL ws,wdepth
!      climate variables for every day
!   *** before ..int
!      real Ta,Tair,Ts,Tsoil,Ttreat
!   *** after ..int
      real Ta,Tair,Ts,Tsoil,Ttreat,water_table_depth,snow_depth
      real,dimension(11):: input_tsoil
!   ***
      real doy,hour,Dair,Rh,radsol
      real PAR,dpatm
!      output daily means of driving variables
      real CO2air_d_avg,SWdown_d_avg,Psurf_d_avg
      real Rain_d_avg,Tair_d_avg,Wind_d_avg
!   *** ..int

!   ***
!      output from canopy model
      real evap_yr,transp_yr
      real,dimension(10):: thksl,wupl,evapl,wcl,FRLEN   ! wsc is the output from soil water module
      real,dimension(:) :: depth_z(0:10)
      real wsc(10)
      real runoff,runoff_d,runoff_yr,rain,rain_d,rain_yr
      real ws1,ws2,dws,net_dws
      real Esoil,Hcrop,ecstot,Anet,DEPH2O,Acanop
      real Hcanop,Hcanop_d
      real Raplant,Glmax,Gsmax,Rh_d
      real GLmx,Gsmx,GRmx
      real Tleaf(2)
!      output for ORNL model comparison
      real CO2h,PARh,ATh,STh,VPDh,SWh
      real RECOh
      real ETh,Th,Eh,INTh,ROh,DRAINh,LEh,SHh
      real LWH,Rgrowth_d,abvLitter,blLitter
!     daily output
      real PAR_d,AT_d,ST_d,VPD_d
      real SW_d,NEP_d,NEE_d,RECO_d
      real Ra_d,RLEAV_d,RWOOD_d,RROOT_d,RHET_d,RSOIL_d,ET_d,T_d
      real E_d,INT_d,RO_d,DRAIN_d,LE_d,SH_d,CL_d,CW_d,CFR_d,TNC_d
      real CSOIL_d,GL_d,GW_d,GR_d,LFALL_d,LMA_d,NCAN_d,NWOOD_d
      real GL_yr,GR_yr,GW_yr
      real NFR_d,NSOIL_d,NUP_d,NMIN_d,NVOL_d,NLEACH_d
      real N_LG_d,N_WG_d,N_RG_d
      real N_LF_d,N_WF_d,N_RF_d
      real WFALL_D,RFALL_D
      real Simu_lit

!   *** added for ..int
      ! for soil temp
      real sftmp,Tsnow,Twater,Tice,ice_tw,water_tw
      real,dimension(10):: Tsoill,ice,liq_water
      real,dimension(11):: testout
      real soilt_d_simu(11),watertable_d_obs,ice_d_simu(10),TD_d
!      real soilt_d_simu(11),soilt_d_obs(7),watertable_d_obs,ice_d_simu(10),TD_d
!      integer obs_counter(7)
      real zwt_d,snow_depth_e,snow_dsim,melt,dcount,dcount_soil
      character(len=80) outfile

      integer dlayer
!   *** added for ..int

!      NEE observation
      real NEE_annual,Cumol2gram
      real NEE_annual_array(30)
      integer year_array(30),year_obs
!     for loops
      integer jrain,W_flag(7)
      integer onset !flag of phenological stage
      integer year,yr,days,i,j,m,n,yrs_eq,hoy,iyr,daily
      integer k1,yk1
      integer lines_NEE,yr_NEE
      integer istat1,istat2,istat3,istat4,istat5
      integer dtimes,yr_length
      integer num_scen,isite
      integer idoy,ihour,ileaf,first_year
      integer dylim,yrlim
      real zwt,phi

!   *** ..int
      !*****for methane subroutine      MS
      integer, parameter :: nlayers=10
      real CH4(nlayers),CH4_V(nlayers), CH4V_d(nlayers)
      real ProCH4(nlayers),Pro_sum,Pro_sum_d,Pro_sum_yr
      real OxiCH4(nlayers),Oxi_sum,Oxi_sum_d,Oxi_sum_yr
      real simuCH4,simuCH4_d,simuCH4_yr
      real Fdifu(nlayers),Fdifu1_d,Fdifu1_yr
      real Ebu_sum_sat,Ebu_sum_sat_d,Ebu_sum_sat_yr
      real Ebu_sum_unsat,Ebu_sum_unsat_d,Ebu_sum_unsat_yr
      real Pla_sum,Pla_sum_d,Pla_sum_yr
      real S_omega
      real r_me,Q10pro,kCH4,Omax,CH4_thre,Tveg,Tpro_me,Toxi
      logical do_snow,do_soilphy
      real Vp(nlayers),pwater(nlayers),presP(nlayers),methanebP(nlayers),methaneP(nlayers),Rgas
      real bubble_methane_tot
      real f,Nbub,bubprob,Vmaxfraction
      real depth(nlayers)
!*******************************************
!   ***  for write out data
      logical do_co2_da,do_methane_da,do_methane_fcast,do_co2_fcast,do_EBG,is_grass,do_da,do_fcast
      integer, parameter :: miterms=29
      real output_data(miterms,ilines)
      real Rmain_yr,Rgrowth_yr,Rnitrogen_yr
! *** for adding allocation rate into DA ***
	  real etaL,etaW,etaR,f_F2M,f_C2M,f_C2S,f_M2S,f_M2P,f_S2P,f_S2M,f_P2M
!*******************************************
!      integer first_year  !read from input parameter file added for workshop Feb 26 2019

!     Default C/N ratios of Oak Ridge FACE
!      data CN0 /45.,350.,60.,40.,300.,10.,15.,8./
!     Default C/N ratios of Duke FACE
      CN0 = (/50.,350.,60.,40.,300.,10.,20.,12./)
!      CN0 = (/150.,350.,200.,40.,300.,10.,20.,12./)      !Chris CiPEHR value used
!     ratio of roots in every layer, Oak Ridge FACE
!      FRLEN = (/0.1,0.25,0.25,0.2,0.1,0.05,0.025,0.015,0.005,0.005/)  ! JJ and Yuanyuan
!      FRLEN = (/0.75,0.2,0.02,0.015,0.005,0.0,0.0,0.0,0.0,0.0/)  ! Shuang
      FRLEN = (/0.75,0.2,0.02,0.02,0.01,0.0,0.0,0.0,0.0,0.0/)
!     update: Shuang methane bog species even more shallowly rooted than the tundra

      CH4_V = (/0.,0.,0.,0.,0.,0.,0.,0.,0.,0./)
      TD=150
!   *** ..int
!      add initials for soil thermal dynamics in Yuanyuanversion
      sftmp =-0.
      Tsnow = -20.
      Twater=0.0
      Tice =0.0

      G=20.5
      Esoil=0.5*G
      snow_dsim =0.575
      dcount=50.
      dcount_soil=50.

      ice_tw =0.0
!      Tsoill=(/ -0.09, 0.73, 1.95, 3.89, 5.88, 6.27, 3.89,    &
!        &   5.99, 6.27,7./)                                    !  Yuanyuan thksl 5 25 ...
!                   10    20    30   40   50   70  90 110   130  150
        Tsoill=(/ -0.09, 0.73, 1.3, 1.95, 2.3, 3., 4., 4.5, 5., 5.98/)  ! JJ MS thksl 10 20 30 40 50 70 90 110 130 150...

      ice=(/0.021, 0.0, 0., 0., 0.0, 0.0, 0.0, 0.0,    &
        &   0.0, 0.0/)
!      ice=(/0.005, 0.0, 0., 0., 0.0, 0.0, 0.0, 0.0,    &
!        &   0.0, 0.0/)

      liq_water=(/0.0355, 0.056, 0.056, 0.056, 0.056, 0.113, 0.113,0.113,0.113,0.113/)    ! unit m

!     thickness of every soil layer
      thksl = (/10.,10.,10.,10.,10.,20.,20.,20.,20.,20./)

      depth(1)=10.0                                  !calculate soil depth unit cm
      do i=2,nlayers
          depth(i)=depth(i-1)+THKSL(i)
      enddo

      zwt=0.0
      water_tw=zwt*0.001


    !!!!  #1.EBG put this paragraph outside of the time loop, initialization step
    Vp(1:3)=0.  !assume in the very beginning no bubbles exist in the first three layers (30cm)
    Vp(4:6)=0.001!0.005
    Vp(7:10)=0.01  !unit m3
    bubble_methane_tot  = 0.

!      add initials for methane module Shuang version                                                        !MS
!      CH4=(/0.,0.,0.,0.,0.,0.,0.,0.,0.,0./)
!        CH4= (/0.000152,0.1232,0.2128,0.3024,0.352,0.8,0.8,0.8,0.8,0.8/)
!        CH4= (/0.000152,0.01232,0.06128,0.0224,0.03,0.5,0.8,0.8,0.8,0.8/)
!        CH4= (/0.000152,0.05,0.6,0.7,0.7,1.4,1.4,1.4,1.4,1.4/)
        CH4= (/0.000152,0.05,0.6,0.7,0.7,1.7,1.7,1.7,1.7,1.7/) !steady sate for EBG
!    CH4= (/0.000152,0.05,0.1,0.1,0.1,3.7,4.,4.,4.,4./) !steady state for ECT
!   *** end of ..int
!  initials for Methane_EBG parameters
!    f = 0.1
    Nbub = 100.
!    bubprob = 0.1
!    Vmaxfraction = 0.1


    do i=1,nlayers
        if (depth(i) .le. (-zwt)*0.1) then
            pwater(i) = 1000*9.81*(depth(i)*0.01-(-zwt)*0.001)
            else
            pwater(i) = 0.
        endif
        presP(i) = 101325 + pwater(i)  ! unit Pa

            methanebP(i) = f * presP(i) * Vp(i)/(8.3144621 * (Tsoill(i)+273.15))  !unit mol/layer
            methaneP(i) = CH4(i)/12
    !				  gC/layer  /12   unit molC/layer
    enddo


      !     Nitrogen input
!      N_deposit=0.000144634702 !(gN/h/m2, 1.2+0.067 gN/yr/m2,Oak ridge)
!     0.7 gN/yr/m2, 13.4 kg N ha-1 yr-1, 2000, Dentener et al. 2006, GBC, Duke FACE
      N_deposit=2.34/8760. !(gN/h/m2, )
!      N_deposit=0.7/8760. !(gN/h/m2, )   !CiPEHR Chris

!      N_fert=0. ! (20.0 gN m-2 yr-1, in spring, from 2004, Oak Ridge)
      N_fert=0. !5.6 ! (11.2 gN m-2 yr-1, in spring, Duke Forest FACE)



          input_data=forcing_data
!         end of reading forcing data

!     ===============================================================
!         cycle  ! skip the following blocks, read input data only.
!         ===================================================
!         Initialize parameters and initial state:


          WILTPT=wsmin/100.0
          FILDCP=wsmax/100.0
!         define soil for export variables for satisfying usage of canopy submodel first time
!          wscontent=WILTPT

          infilt=0.

!         gddonset=320.0

          stor_use=Storage/times_storage_use
          accumulation=0.0
          SNvcmax=1.0

			! write (*,*) "LAIMIN",LAIMIN
          LAI=LAIMIN
          bmleaf=QC(1)/0.48
          bmstem=QC(2)/0.48
          bmroot=QC(3)/0.48
          bmplant=bmstem+bmroot+bmleaf

!         initial values of Nitrogen pools and C/N ratio
          alphaN=0.0    ! the transfer of N before littering

          NSN=0.35
          QNminer= 1.2
!   ****** Chris CiPEHR value
!          NSN=6.0
!          QNminer= 0.1
          N_deficit=0
          N_immob=0
          CN=CN0
          QN=QC/CN0
          QNplant  =QN(1) + QN(2) + QN(3)

!=============================================================
          m=1
          n=1
          k1=1
		  yk1=1	!yk1 is the row count of hourly obs_cflux data
          iyr=0
          idays=365
          daily=0
!          first_year=2011  !added to input parameter file for training purpose
          !yr_length=1
!          print*,yrs_eq,yr_length
          do yr=1,yrs_eq+yr_length  ! how many years, year loop start
!              print*,yr,daily
              if(yr.gt.3)then
!                  write(*,*)'One year done'
              endif
!            using ambient data to run equilibiurm, elevated only for the last cycle
             iyr=iyr+1
             if(iyr>yr_length)iyr=1

!!          leap year
!           if(MOD(first_year+iyr-1,4).eq.0)then
!                 idays=366
!           else
                 idays=365  !ignore iday 366 in this version
!           endif

!		use two sets of parameters before and after year 2014
			if (yr .le. 13) then !22
				! write(*,*)'before 2014'

		!		by default these parameters are imported as parval1
				wsmax    =parval(3)
				wsmin    =parval(4)
				SLAx     =parval(12)
				GLmx     =parval(13)  !GLmax
				GRmx     =parval(14)	 !GRmax
				Gsmx     =parval(15)  !Gsmax
				Vcmax0   =parval(19)
				tau_L    =parval(23)
				tau_W    =parval(24) !Tau_Wood
				tau_R    =parval(25)!Tau_Root
				tau_F    =parval(26)!Tau_F
				tau_C    =parval(27)!Tau_C
				tau_Micr =parval(28)!Tau_Micro
				tau_Slow =parval(29)!Tau_slowSOM
				tau_Pass =parval(30)!Tau_Passive
				gddonset =parval(31)
				Q10		 =parval(32)
				Rl0		 =parval(33)
				Rs0		 =parval(34)
				Rr0		 =parval(35)
				r_me	 =parval(36)
				Q10pro	 =parval(37)
				Omax	 =parval(39)
				Tveg	 =parval(41)
				f		 =parval(44)
				bubprob	 =parval(45)
				Vmaxfraction=parval(46)
				Q10rh		=parval(47)
				JV		  	=parval(48)
				Entrpy		=parval(49)
				etaL = parval(50)
				etaW = parval(51)
				etaR = parval(52)
				f_F2M = parval(53)
				f_C2M = parval(54)
				f_C2S = parval(55)
				f_M2S = parval(56)
				f_M2P = parval(57)
				f_S2P = parval(58)
				f_S2M = parval(59)
				f_P2M = parval(60)
			!	write (*,*) 'SLAx',SLAx,'Vcmax0',Vcmax0,'tau_L',tau_L
			! write (*,*) SLAx,GLmx,GRmx,Gsmx,Vcmax0,tau_L,tau_W,tau_R,tau_F,tau_C,tau_Micr,tau_Slow,tau_Pass, &
						! &	gddonset,Q10,Rl0,Rs0,Rr0,r_me,Q10pro,Omax,Tveg,f,bubprob,Vmaxfraction,Q10rh,JV,Entrpy
			elseif (yr .gt. 13) then
				! write(*,*)'after 2014'
				wsmax    =parval2(3)
				wsmin    =parval2(4)
				SLAx     =parval2(12)
				GLmx     =parval2(13)  !GLmax
				GRmx     =parval2(14)	 !GRmax
				Gsmx     =parval2(15)  !Gsmax
				Vcmax0   =parval2(19)
				tau_L    =parval2(23)
				tau_W    =parval2(24) !Tau_Wood
				tau_R    =parval2(25)!Tau_Root
				tau_F    =parval2(26)!Tau_F
				tau_C    =parval2(27)!Tau_C
				tau_Micr =parval2(28)!Tau_Micro
				tau_Slow =parval2(29)!Tau_slowSOM
				tau_Pass =parval2(30)!Tau_Passive
				gddonset =parval2(31)
				Q10		 =parval2(32)
				Rl0		 =parval2(33)
				Rs0		 =parval2(34)
				Rr0		 =parval2(35)
				r_me	 =parval2(36)
				Q10pro	 =parval2(37)
				Omax	 =parval2(39)
				Tveg	 =parval2(41)
				f		 =parval2(44)
				bubprob	 =parval2(45)
				Vmaxfraction=parval2(46)
				Q10rh		=parval2(47)
				JV		  	=parval2(48)
				Entrpy		=parval2(49)
				etaL = parval2(50)
				etaW = parval2(51)
				etaR = parval2(52)
				f_F2M = parval2(53)
				f_C2M = parval2(54)
				f_C2S = parval2(55)
				f_M2S = parval2(56)
				f_M2P = parval2(57)
				f_S2P = parval2(58)
				f_S2M = parval2(59)
				f_P2M = parval2(60)
			endif
			!	write (*,*) 'SLAx',SLAx,'Vcmax0',Vcmax0,'tau_L',tau_L
!		end of using two sets of parameters before and after year 2014

!         the unit of residence time is transformed from yearly to hourly
          tauC=(/tau_L,tau_W,tau_R,tau_F,tau_C,&
     &           tau_Micr,tau_Slow,tau_Pass/)*8760.

          SLA=SLAx/10000.         ! Convert unit from cm2/g to m2/g
!         growth rates of plant
          GLmax=GLmx/8760.
          GRmax=GRmx/8760.
          Gsmax=GSmx/8760.
!         end of setting parameters

             GDD5=0.0
             onset=0
             phenoset=0
             diff_yr=0.0
             gpp_yr=0.0
             R_Ntr_yr=0.
             NPP_yr=0.0
             Rh_yr =0.0
             Rh4_yr=0.0
             Rh5_yr=0.0
             Rh6_yr=0.0
             Rh7_yr=0.0
             Rh8_yr=0.0
             Ra_yr =0.0
             GL_yr=0.0
             GW_yr=0.0
             GR_yr=0.0
             Pool1=0.0
             Pool2=0.0
             Pool3=0.0
             Pool4=0.0
             Pool5=0.0
             Pool6=0.0
             Pool7=0.0
             Pool8=0.0
             out1_yr=0.0
             out2_yr=0.0
             out3_yr=0.0
             out4_yr=0.0
             out5_yr=0.0
             out6_yr=0.0
             out7_yr=0.0
             out8_yr=0.0
             NEE_yr=0.0
!            water fluxes
             rain_yr=0.0
             transp_yr=0.0
             evap_yr=0.0
             runoff_yr=0.0
             Simu_lit=0.

!            Nitrogen fluxes
             N_up_yr=0
             N_tran_yr=0
             N_fix_yr=0.
             N_def_yr=0.
             N_min_yr=0.
             N_imb_yr=0.
             QNmin_yr=0.

             N_dep_yr=0.
             N_leach_yr=0.
             N_vol_yr=0.

        !============================== test variable
             fwsoil_yr=0.
             omega_yr=0.
             topfws_yr=0.
!============================== methane related outputs set initial to 0
                  simuCH4_yr = 0.
                  Pro_sum_yr = 0.
                  Oxi_sum_yr = 0.
                  Fdifu1_yr = 0.
                  Ebu_sum_sat_yr = 0.
                  Ebu_sum_unsat_yr = 0.
                  Pla_sum_yr = 0.

             hoy=0

!!     end of leap year
             do days=1,idays !the days of a year, day loop starts
                 if (yr .eq. 1 .and. days .ge. 113 )then
!                      write (*,*) 'days', days
                 endif
!             Nitrogen fertilization since 2004 in Oak Ridge
!              if(yr>yrs_eq+5.and.days==135)then
!                  QNminer=QNminer+N_fert     !(20 gN/yr/m2,N fertiliztion in Spring)
!              endif

!             Nitrogen fertilization since 1999 in Duke
              if(yr>yrs_eq+1.and.(days==75.OR.days==105))then
                  QNminer=QNminer+N_fert     !(5.6 gN/yr/m2,N fertiliztion in March and Apr)
              endif


              StemSap=AMIN1(Stemmax,SapS*bmStem)   ! Stemmax and SapS were input from parameter file, what are they? Unit? Maximum stem biomass? -JJJJJJJJJJJJJJJJJJJJJJ
              RootSap=AMIN1(Rootmax,SapR*bmRoot)
              NSCmin=5.
!              NSCmax=0.05*(StemSap+RootSap+QC(1))
              NSCmax=0.05*(StemSap+RootSap+QC(1)+QC(3))  ! +QC(3) added by Chris
              if(Ta.gt.5.0)GDD5=GDD5+Ta

!   *** int
!   ********* for daily initials in soil thermal module
              TD_d = 0
              soilt_d_simu=(/0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0./)
              ice_d_simu=(/0.,0.,0.,0.,0.,0.,0.,0.,0.,0./)

!              soilt_d_obs=(/0.,0.,0.,0.,0.,0.,0./)
              zwt_d=0.0
!              obs_counter = (/0,0,0,0,0,0,0/)
!              write (121,1201) zwt,snow_dsim

!1201                 format(2(f15.4,","))
              if (do_snow) then
                 if (yr .eq. 1. .and. days .eq. 1.) then
                     ta = -12.85       ! since changed the ta criteria (0. to 1.e-10)) in calculating melt
                     rain_d = 0.        !dbmemo
                 endif

                 call snow_d(rain_d,lat,days,ta,snow_dsim,fa,fsub,rho_snow,melt,dcount,decay_m)
                 snow_depth_e=snow_dsim

              endif
!              write (122,1202) zwt,snow_dsim
!1202                 format(2(f15.4,","))

!               for daily initials in methane module

              simuCH4_d=0.0
              Pro_sum_d=0.0
              Oxi_sum_d=0.0
              Fdifu1_d=0.0
              Ebu_sum_sat_d=0.0
              Ebu_sum_unsat_d=0.0
              Pla_sum_d=0.0
              CH4V_d= (/0.,0.,0.,0.,0.,0.,0.,0.,0.,0./)
!*****************************
!   *** ..int

!             THE FIRST PART:  coupled canopy and soil model
              diff_d = 0.0
              gpp_d   =0.0   ! daily
              gpp_ra  =0.0   ! daily
              NPP_d   =0.0   ! daily
              NEP_d=0.0
              NEE_d = 0.0
!             rain_d,transp_d,evap_d
              transp_d=0.0   ! daily
              Hcanop_d=0.0   ! daily
              evap_d  =0.0   ! daily
              ta=0.0         ! daily
              Ts=0.0         ! daily
              rain_d=0.0     ! daily
              runoff_d=0.0    ! daily
              LE_d=0.0
              RaL=0.0
              RaS=0.0
              RaR=0.0
              Rauto=0.0
              Rh_d=0.0
              N_up_d=0.
              N_fix_d=0.
              N_dep_d=0.
              N_leach_d=0.
              N_vol_d=0.
              PAR_d=0.
              VPD_d=0.0
              RECO_d=0.0
              RLEAV_d=0.0
              RWOOD_d=0.0
              RROOT_d=0.0
              GL_d   =0.0
              GW_d   =0.0
              GR_d   =0.0
              LFALL_d=0.0
              NUP_d=0.0
              NVOL_d=0.
              NLEACH_d=0.0
              NMIN_d=0.0
              N_LG_d=0.0
              N_WG_d=0.0
              N_RG_d=0.0
              N_LF_d=0.0
              N_WF_d=0.0
              N_RF_d=0.0
              WFALL_d=0.0
              RFALL_d=0.0
              dtimes=24 !how many times a day,24 means every hour
              do i=1,dtimes		! hour loop starts
!           write (*,*) 'daily3',daily,i,'Simu_dailysoilt(11)',Simu_dailysoilt(11,2123),'Simu_dailysoilt(1)',Simu_dailysoilt(1,2124)

!                  if (yr .eq. 7 .and. days .ge. 120.) then                      !dbmemo15641
!                    write (77,*) 'yr',yr,'days',days,'i',i  !print timer
!                  endif
!                  write (*,*) 'yr,days,time', yr, days, i       !dbmemo
                  if(i.gt.1)then
!                      write(*,*)'pause'
                  endif

!!                 input data
!                  if(m > lines)then    ! Repeat forcing data for the whole time period
!!                  lines is the length of climate file
!                !  if(yr.ge.1 .and. mod(days,idays).eq.0     &
!                !  &     .and. mod(i,dtimes).eq.0)then   ! Repeat forcing data for specific time period
!!                     m=1           ! m is row sequence in the file of input_data
!                     m=43801	    ! reuse 2015-2018 data in spinup after the first 8 years forward run
!                     n=1
!                     hoy=0
!                  endif
!   *************************************  18+8
                  ! if(m .gt. 26280 .and. yr .le. 19)then  !26280 hrs from 2011-2013
				    if(m .gt. 26280 .and. yr .le. 10)then  !26280 hrs from 2011-2013 spin
                      m=1
                     n=1
                     hoy=0
!                  elseif(yr .gt. 26 .and. m > lines) then
!                      m=1
!                      n=1
!                      hoy=0
                  endif

!   *************************************  18+8+5+5
!                  if(m .gt. 26280 .and. yr .le. 19)then  !26280 hrs from 2011-2013
!                      m=1
!                      n=1
!                      hoy=0
!                  elseif(yr .gt. 26 .and. m > lines) then
!                      m=26281
!                      n=1
!                      hoy=0
!                  endif
!!  *****************************
                  year =year_seq(m)
                  doy  =doy_seq(m)
                  hour =hour_seq(m)+1
!                  write (*,*) year, doy, hour,output_data(2,2)

!       ######################################################################
              if (do_methane_da .or. do_methane_fcast) then
!              if (do_methane_da) then
!                  dpatm = input_data(8,m)
                  zwt = output_data(1,m)
                  testout(11) = output_data(2,m)+0!+9.
                  Rh_pools(1:5)=output_data(3:7,m)
                  wsc(1:10)  =  output_data(8:17,m)
                  Simu_soilwater(1:10,k1)=wcl(1:10)
                  testout(2:10) = output_data(18:26,m)+0!+9.
                  testout(1) = output_data(27,m)+0!+9.
                  dpatm = output_data(28,m)
                  LAIMAX = output_data(29,m)
                  Tsoil=input_data(2,m)+0!+9.
              else

!       ######################################################################
                  !!       for Duke Forest
                  Tair=input_data(1,m)   ! Tair
                  Tsoil=input_data(2,m)    ! SLT Tsoil in -20cm, used when Tsoil_simu is off
                  input_tsoil(1:11)=input_data(8:18,m)
                  co2ca=380.0*1.0E-6
                  if (yr .gt. 23)then ! eCO2 started in 2016, 18+5
					if (days .gt. 90 .and. days .lt.305) then
                     ! Tair = Tair + Ttreat !temperature treatment was added to the forcing file
                     ! Tsoil = Tsoil + Ttreat !temperature treatment was added to the forcing file
					 if (use_plinit .eq. 21 .or. use_plinit .eq. 22 .or. use_plinit .eq. 23 &
					 & .or. use_plinit .eq. 24 .or. use_plinit .eq. 25 .or. use_plinit .eq. 26) then
                      co2ca=CO2treat*1.0E-6 ! CO2 concentration,ppm-->1.0E-6
					 endif
					endif
                  endif
                  RH=input_data(3,m)
!                  Dair=input_data(4,m)       !vpd, deleted in SPRUCE acclimation version, since it was not measured 2011-2018
!                  co2ca=CO2treat*1.0E-6 ! CO2 concentration,ppm-->1.0E-6
!                  if(isite==2.and.yr>yrs_eq)then
!                      co2ca=(input_data(5,m)+200.)*1.0E-6
!                  endif
                  rain=input_data(4,m)    ! rain fal per hour
                  wind=ABS(input_data(5,m))     ! wind speed m s-1
                  PAR=input_data(6,m)             ! Unit  umol/s/m-2
                  radsol=input_data(6,m)        ! PAR
                  dpatm = 101325.               ! Pa

!                  dpatm=input_data(8,m)          ! unit patm Pa dynamic atmosphere pressure
!                  Rnet=input_data(9,m)

!   *** int added for soil thermal/ soil water
                  day_mod=mod(m,24)
                  if (do_snow) then
                      snow_depth=snow_depth_e
                  else
                      snow_depth=snow_in(m)
                  endif

                  if (snow_depth .lt. 0.0) snow_depth = 0.0
                  snow_depth = snow_depth*100.   ! change from m to cm

!                  Rnet=input_data(9,m)
!   ***
!!       endof Duke Forest

!                 Ajust some unreasonable values
                  RH=AMAX1(0.01,AMIN1(99.99,RH))
                  eairP = esat(Tair)*RH/100.             ! Added for SPRUCE, due to lack of VPD data
                  Dair=esat(Tair)-eairP
                  radsol=AMAX1(radsol,0.01)
              endif             !!!!!!!!!!   ********** end of output_data forcing change
                  hoy=hoy+1

                m=m+1
!              if (do_methane_da .or. do_methane_fcast) GOTO 1002
                if (do_methane_da .or. do_methane_fcast) GOTO 1002
!   *** int if do soil thermal G is not given a value here
!                else G will be given a value below
!   ****************  G
                  if (do_soilphy) then
                      GOTO 160
                  endif
                  if(radsol.gt.10.0) then
                      G=-25.0
                  else
                      G=20.5
                  endif
                  Esoil=0.05*radsol
                  if(radsol.LE.10.0) Esoil=0.5*G

160 continue
!   ***
                  Hcrop=0.1  ! never used in routine
                  Ecstot=0.1 ! never used in routine
                  Anet=0.1 ! never used in routine
                  DepH2O=0.2
!                 for daily mean conditions
                  VPD_d=VPD_d+Dair/24./1000.
                  PAR_D=PAR_D+radsol/dtimes                 ! umol photons m-2 s-1
                  ta= ta + tair/24.0             ! sum of a day, for calculating daily mean temperature
!                  write (*,*) 'tair',tair,'ta',ta  !dbmemo
                  Ts=Ts+Tsoil/24.0
                  rain_d=rain_d+rain
!                 calculating scaling factor of NSC
                  if(NSC.le.NSCmin)fnsc=0.0
                  if(NSC.ge.NSCmax)fnsc=1.0
                  if((NSC.lt.NSCmax).and.(NSC.gt.NSCmin))then
                     fnsc=(NSC-NSCmin)/(NSCmax-NSCmin)
                  endif
!                 update vcmx0 and eJmx0 according to C/N of leaves
                  Vcmx0 = Vcmax0*SNvcmax*1.0e-6
!                  eJmx0 = 2.7*Vcmx0  ! original
                  eJmx0 = 1.67*Vcmx0 ! Weng 02/21/2011 Medlyn et al. 2002
                  eJmx0 = JV*Vcmx0   ! added for acclimation study,replace 1.67 with JV Feb 19 2019 Shuang
!    write (*,*) 'inputdata',inputdata
! write (*,*) 'daily2',daily,'Simu_dailysoilt(11)',Simu_dailysoilt(11,2123),'Simu_dailysoilt(1)',Simu_dailysoilt(1,2124)
            ! write (*,*) "gpp before canopy",GPP,"LAI",LAI
			call canopy(gpp,evap,transp,Acanop,Hcanop,Rsoilabs,  & ! outputs
           &         fwsoil,topfws, &                   ! from soil model
           &         LAI,Sps,&
           &         doy,hour,radsol,tair,dair,eairP,    &        ! from climate data file,including
           &         wind,rain,&
           &         Rnet,G,Esoil,Hcrop,Ecstot,Anet,&
           &         Tsoil,DepH2O,&
           &         wsmax,wsmin,  &                              !constants specific to soil and plant
           &         lat,co2ca,a1,Ds0,Vcmx0,extkU,xfang,alpha,&
           &         stom_n,pi,tauL,rhoL,rhoS,emleaf,emsoil,&
           &         Rconst,sigma,cpair,Patm,Trefk,H2OLv0,airMa,&
           &         H2OMw,chi,Dheat,wleaf,gsw0,eJmx0,theta,&
           &         conKc0,conKo0,Ekc,Eko,o2ci,Eavm,Edvm,Eajm,&
           &         Edjm,Entrpy,gam0,gam1,gam2,wcl,gddonset,&
           &         sftmp,Tsoill,testout,ice,&
           &         water_table_depth,snow_depth,Tsnow,Twater,Tice,water_tw,ice_tw,diff_s,&
           &         diff_snow,albedo_snow,resht,thd_snow_depth,THKSL,zwt,liq_water,shcap_snow,&
           &         condu_snow,condu_b,depth_ex,dcount_soil,do_soilphy,VcmxT,&                    !added for soil thermal..int
           &         Tleaf,input_tsoil)    ! Tleaf added for testing the leaf temperature response to warming treatment Feb 2019
			! write (*,*) "gpp after canopy",GPP

            call soilwater(wsmax,wsmin,rdepth,FRLEN,THKSL,    &   !constants specific to soil/plant
     &                rain,transp,evap,wcl,runoff,infilt,     &   !inputs
     &                fwsoil,topfws,omega,wsc,zwt,phi,        &
     &                liq_water,infilt_rate,melt,ta,day_mod, &
     &                do_soilphy,snow_depth,ice,testout,m,use_plinit)                      !outputs

               TD = 150
               depth_z(0) = 0
               do j=1,10
                  if (j .eq. 1) then
                     depth_z(1)=thksl(1)
                  else
                     depth_z(j)=depth_z(j-1)+thksl(j)
                  endif
!                  print*,'Simu_TD',daily,j,Simu_TD(1,daily),depth_z(j),thksl(j),Simu_dailysoilt(j+1,daily),&
!                                   -Simu_dailysoilt(j,daily)
                  if(j .eq. 1 .and. all(testout(1:3) .le. 0))then
                     TD = 0
                     exit
                  end if
                  if(testout(j) .gt. 0 .and. testout(j+1) .lt. 0)then
!                     TD = depth_z(j) - thksl(j) * testout(j+1) &
!                                 / (-testout(j) + testout(j+1))
!                     print*,'TD',j,depth_z(j)
!                     print*,'TD0.5',(-testout(j) + testout(j+1)),-log(testout(j+1) / (-testout(j) + testout(j+1)))
!                     print*,'TD1',1000.0/depth_z(j),(testout(j+1) / (-testout(j) + testout(j+1))),(1000.0/depth_z(j)),&
!                             testout(j+1),testout(j)
                     TD = depth_z(j-1) + thksl(j) * amin1(-testout(j)/(-testout(j)+testout(j+1)),amax1(0.,&
                          (-log(testout(j+1) / (-testout(j) + testout(j+1)))+log(1./6.)) / log(3.)))
                     exit
                  end if
               end do
                  ET=evap+transp
                  rain_yr=rain_yr+rain
                  transp_yr=transp_yr+transp
                  evap_yr=evap_yr+evap
                  runoff_yr=runoff_yr+runoff

                  call respiration(LAIMIN,GPP,Tair,Tsoil,DepH2O,&
     &                       Q10,Rl0,Rs0,Rr0,SNRauto,&
     &                       LAI,SLA,bmstem,bmroot,bmleaf,&
     &                       StemSap,RootSap,NSC,fnsc,&
     &                       RmLeaf,RmStem,RmRoot,Rmain)
			! write (*,*) "gpp after respiration",GPP
!                 THE Third Part: update LAI
                  call plantgrowth(Tair,omega,GLmax,GRmax,GSmax,&
     &                    LAI,LAIMAX,LAIMIN,SLA,TauC(1),         &    !Tau_L,
     &                    bmleaf,bmroot,bmstem,bmplant,&
     &                    Rootmax,Stemmax,SapS,SapR,&
     &                    StemSap,RootSap,Storage,GDD5,&
     &                    stor_use,onset,accumulation,gddonset,&
     &                    Sps,NSC,fnsc,NSCmin,NSCmax,&
     &                    NSN,CN,CN0,SNgrowth,N_deficit,&
     &                    store,add,L_fall,ht,&
     &                    NPP,alpha_L,alpha_W,alpha_R,&
     &                    RgLeaf,RgStem,RgRoot,Rgrowth,is_grass)
			! write (*,*) "gpp after plant growth",GPP
!                 THE Fourth PART: simulating C influx allocation in pools
                  call TCS_CN(Tair,Tsoil,omega,runoff,&
                     &        NPP,GPP,alpha_L,alpha_W,alpha_R,L_fall,&
                     &        tauC,QC,OutC,Rh_pools,Rnitrogen,NSC,&
                     &        CNmin,CNmax,NSNmax,NSNmin,alphaN,   &         ! nitrogen
                     &        NSN,N_uptake,N_miner,QN,QNminer,TD,&
                     &        CN,CN0,fnsc,rdepth,N_deficit,N_immob,&
                     &        N_leaf,N_wood,N_root,N_LF,N_WF,N_RF,&
                     &        N_deposit,N_fixation,N_leach,N_vol,&
                     &        SNvcmax,SNgrowth,SNRauto,SNrs,Q10rh,&
					&         tsoill,testout,do_soilphy,is_grass,   &
	 & etaL,etaW,etaR,f_F2M,f_C2M,f_C2S,f_M2S,f_M2P,f_S2P,f_S2M,f_P2M)
			! write (*,*) "gpp after TCS_CN",GPP
! *** ..int
!     added tsoil,testout,do_soilphy to TCS_CN
!     added methane module

!        write(82,182) zwt, Rh_pools,Tsoil, Ebu_sum_sat, Ebu_sum_unsat
!182     format(5(f15.9,","))
1002     continue

                call methane(Rh_pools,Tsoil,zwt,wsc,thksl,depth,      &
                &           phi,LAIMIN,LAIMAX,dpatm,           &
                &           ProCH4,Pro_sum,OxiCH4,Oxi_sum,Fdifu,Ebu_sum_sat,Ebu_sum_unsat,Pla_sum,simuCH4,CH4,CH4_V,   &
!                &           ProCH4,Pro_sum,OxiCH4,Oxi_sum,Fdifu,Ebu_sum,Pla_sum,simuCH4,CH4,   &
                &           r_me,Q10pro,kCH4,Omax,CH4_thre,Tveg,Tpro_me,Toxi,  &
                &           f,Nbub,bubprob,Vmaxfraction,     &                                 !DA parameters
                &           methanebP,methaneP,presP,pwater,Vp,bubble_methane_tot,  &		!with initial values
                &           testout,do_soilphy,do_co2_da,do_da,do_methane_da,do_methane_fcast,do_EBG)
                                                                                !update single value of Rh_pools,Tsoil,zwt,wsc


!
!                 update NSC
                  Rauto  =Rmain+Rgrowth+Rnitrogen
                  Rmain_yr=Rmain_yr+Rmain
                  Rgrowth_yr=Rgrowth_yr+Rgrowth
                  Rnitrogen_yr=Rnitrogen_yr+Rnitrogen
!                  write (*,*) 'Rmain',Rmain_yr,'Rgrowth',Rgrowth_yr,'Rnitrogen',Rnitrogen_yr
                  NSC    =NSC+GPP-Rauto-(NPP-add)-store
                  Difference = GPP-Rauto-NPP
                  if(NSC<0)then
                     if(is_grass)then
                        bmroot=bmroot+NSC/0.48
                        NPP=NPP+NSC/0.48
                        NSN=NSN-NSC/CN(3)
                        NSC=0.
                     else
                      bmstem=bmstem+NSC/0.48
                      NPP=NPP+NSC
                      NSN=NSN-NSC/CN(2)
                      NSC=0.
                     end if
                  endif
                  GL_d   =GL_d+NPP*alpha_L
                  GW_d   =GW_d+NPP*alpha_W
                  GR_d   =GR_d+NPP*alpha_R
                  LFALL_d=LFALL_d+L_fall
!                 update
                  RaLeaf = RgLeaf + RmLeaf
		  RaStem = RgStem + RmStem
		  RaRoot = RgRoot + RmRoot + Rnitrogen
                  WFALL_d=WFALL_d+OutC(2) !_wood
                  RFALL_d=RFALL_d+OutC(3) !_root
                  N_LG_d=N_LG_d+N_leaf
                  N_WG_d=N_WG_d+N_wood
                  N_RG_d=N_RG_d+N_root
                  N_LF_d=N_LF_d+N_LF
                  N_WF_d=N_WF_d+N_WF
                  N_RF_d=N_RF_d+N_RF

                  N_up_d=N_up_d+N_uptake
                  N_fix_d=N_fix_d+N_fixation
                  N_dep_d=N_dep_d+N_deposit
                  N_leach_d=N_leach_d+N_leach
                  N_vol_d=N_vol_d+N_vol

                  N_up_yr=N_up_yr+N_uptake
                  N_tran_yr=N_tran_yr+N_uptake
                  N_fix_yr=N_fix_yr+N_fixation
                  N_imb_yr=N_imb_yr+N_immob
                  N_min_yr=N_min_yr+N_miner
                  N_dep_yr=N_dep_yr+N_deposit
                  N_leach_yr=N_leach_yr+N_leach
                  N_vol_yr=N_vol_yr+N_vol

                  R_Ntr_yr=R_Ntr_yr + Rnitrogen

!   *** ..int
                  do dlayer=1,10
                      ice_d_simu(dlayer)=ice_d_simu(dlayer)+ice(dlayer)
                  enddo
                   do dlayer=1,11
                      soilt_d_simu(dlayer)=soilt_d_simu(dlayer)+testout(dlayer)
!                      write (*,*) 'dlayer',dlayer,'soilt_d_simu(dlayer)',soilt_d_simu(dlayer)
                      ! first = surface soil temperature 2:11=1:10 layer soil temperatures
                  enddo
                  TD_d = TD_d + TD
                  do dlayer=1,10
                      CH4V_d(dlayer)=CH4V_d(dlayer)+CH4_V(dlayer)
                  enddo
                  zwt_d=zwt_d+zwt    ! ..int I doubt it... mean for zwt?     check later  Shuang
!   ***

           ! ==================== test variables
                  topfws_yr = topfws_yr+topfws/8760.
                  omega_yr=omega_yr+omega/8760.
                  fwsoil_yr=fwsoil_yr+fwsoil/8760.

!                 Rhetero=Rh_f + Rh_c + Rh_Micr + Rh_Slow + Rh_Pass
                  Rhetero= Rh_pools(1)+Rh_pools(2)+Rh_pools(3) &
     &                    +Rh_pools(4)+Rh_pools(5)
                  Rsoil  =Rhetero+RmRoot+RgRoot+Rnitrogen
                  NEE=Rauto+Rhetero - GPP
                  Q_soil=QC(6) + QC(7) + QC(8)

                  bmleaf=QC(1)/0.48
                  bmstem=QC(2)/0.48
                  bmroot=QC(3)/0.48
                  bmplant=bmleaf+bmroot+bmstem
                  LAI=bmleaf*SLA
				  ! write (*,*) "update LAI",LAI,"bmleaf",bmleaf,"SLA",SLA
                  NMIN_d = NMIN_d+N_miner
!                 output hourly
                  Recoh=Rhetero+Rauto
                  ETh =ET !*1000.
                  Th  =transp !*1000.
                  Eh  =evap !*1000.
                  INTh=-9999
                  VPDh=Dair/1000.
                  ROh =runoff !*1000.
                  DRAINh=-9999
                  LEh =ETh*((2.501-0.00236*Tair)*1000.0)/3600.
                  SHh =-9999
                  LWh =-9999
                  NEP=-NEE


!                 sums of a day
                  diff_d=diff_d+difference
                  gpp_d=gpp_d + GPP
                  gpp_ra=gpp_ra+Rauto
                  NPP_d   =NPP_d+NPP
                  NEP_d=NEP_d+NEP
                  NEE_d=NEE_d+NEE
                  RECO_d=RECO_d+Recoh
                  Rh_d=  Rh_d + Rhetero
                  Ra_d=Reco_d-Rh_d
                  RLEAV_d=RLEAV_d+RmLeaf+RgLeaf
                  RWOOD_d=RWOOD_d+RmStem+RgStem
                  RROOT_d=RROOT_d+RmRoot+RgRoot+Rnitrogen
                  Rsoil_d=Rh_d+RROOT_d
                  NUP_d=NUP_d+N_uptake
                  NVOL_d=NVOL_d+N_vol
                  NLEACH_d=NLEACH_d+N_leach
                  transp_d=transp_d + transp*(24./dtimes)
                  evap_d=evap_d + evap*(24./dtimes)
                  ET_d=transp_d + evap_d
                  LE_d=LE_d+LEh/24.
                  Hcanop_d=Hcanop_d+Hcanop/(24./dtimes)
                  runoff_d=runoff_d+runoff
!   *** .int
                  ! added for MEMCMC also for generation of daily methane emission
                  simuCH4_d=simuCH4_d+simuCH4
                  Pro_sum_d=Pro_sum_d+Pro_sum
                  Oxi_sum_d=Oxi_sum_d+Oxi_sum
                  Fdifu1_d=Fdifu1_d+Fdifu(1)
                  Ebu_sum_sat_d=Ebu_sum_sat_d+Ebu_sum_sat
                  Ebu_sum_unsat_d=Ebu_sum_unsat_d+Ebu_sum_unsat
                  Pla_sum_d=Pla_sum_d+Pla_sum
!   ***
!                 sum of the whole year
                  diff_yr = diff_yr+difference
                  gpp_yr=gpp_yr+gpp
                  VcmxT_yr=VcmxT_yr+VcmxT
                  NPP_yr=NPP_yr+NPP
!                  add_yr=add_yr+add
!                  store_yr=store_yr+store
                  Rh_yr =Rh_yr +Rhetero
                  Ra_yr=Ra_yr+Rauto
                  Rh4_yr=Rh4_yr+Rh_pools(1)
                  Rh5_yr=Rh5_yr+Rh_pools(2)
                  Rh6_yr=Rh6_yr+Rh_pools(3)
                  Rh7_yr=Rh7_yr+Rh_pools(4)
                  Rh8_yr=Rh8_yr+Rh_pools(5)
                  radsol_yr=radsol_yr+radsol
                  if(days .eq. 1 .and. i .eq. 1)then
!                 NSN_yr=NSN_yr+NSN/8760
                     NSN_yr = NSN
                     NSC_yr = NSC
                     add_yr=add
                     store_yr=store
!                 NSC_yr=NSC_yr+NSC/8760
                  end if
                  Pool1 = Pool1+QC(1)/8760.
                  Pool2 = Pool2+QC(2)/8760.
                  Pool3 = Pool3+QC(3)/8760.
                  Pool4 = Pool4+QC(4)/8760.
                  Pool5 = Pool5+QC(5)/8760.
                  Pool6 = Pool6+QC(6)/8760.
                  Pool7 = Pool7+QC(7)/8760.
                  Pool8 = Pool8+QC(8)/8760.
                  QNmin_yr=QNmin_yr+QNminer/8760.
                  N_def_yr=N_def_yr+N_deficit/8760
                  out1_yr=out1_yr+OutC(1)
                  out2_yr=out2_yr+OutC(2)
                  out3_yr=out3_yr+OutC(3)
                  out4_yr=out4_yr+OutC(4)
                  out5_yr=out5_yr+OutC(5)
                  out6_yr=out6_yr+OutC(6)
                  out7_yr=out7_yr+OutC(7)
                  out8_yr=out8_yr+OutC(8)
                  NEE_yr=NEE_yr+NEE
                  GL_yr=GL_yr+NPP*alpha_L
                  GW_yr=GW_yr+NPP*alpha_W
                  GR_yr=GR_yr+NPP*alpha_R

                  simuCH4_yr=simuCH4_yr+simuCH4
                  Pro_sum_yr=Pro_sum_yr+Pro_sum
                  Oxi_sum_yr=Oxi_sum_yr+Oxi_sum
                  Fdifu1_yr=Fdifu1_yr+Fdifu(1)
                  Ebu_sum_sat_yr=Ebu_sum_sat_yr+Ebu_sum_sat
                  Ebu_sum_unsat_yr=Ebu_sum_unsat_yr+Ebu_sum_unsat
                  Pla_sum_yr=Pla_sum_yr+Pla_sum

!                 numbering
                  n=n+1

!   *** .int
!                 added for soil thermal
!                  if((yr+first_year-1).eq.obs_soilwater(1,k1) .and.    &
!                  &     days .eq. obs_soilwater(2,k1) .and.      &
!                  &     (i-1).eq. obs_soilwater(3,k1))then
               if(yr.gt.yrs_eq)then  !recording the hourly data only after spin up
                  k1=k1+1
!                  print*,'k1',k1
                  Simu_soilwater(1:10,k1)=wcl(1:10)
                  Simu_soilwater(11:20,k1)=liq_water(1:10)
                  Simu_soilwater(21:30,k1)=ice(1:10)
                  Simu_soiltemp(1:11,k1)=testout
                  Simu_watertable(1,k1)=zwt
               end if
!                  endif
                 ! write(*,*)yr,days,i,gpp,npp
!   ***   spin 19-10
!	*** hourly data for DA,  recording the hourly simu_hrflux only when there is obs data   Shuang
                  if((yr+first_year-10).eq.obs_cflux_hr(1,yk1) .and.    &	!obs column 1 is year label
                  &     days .eq. obs_cflux_hr(2,yk1) .and.      &			!obs column 2 is day  label   1-365
                  &     (i-1).eq. obs_cflux_hr(3,yk1))then					!obs column 3 is hour label   0-23, not 1-24, this is why i-1
                  Simu_hrflux(1,yk1)=GPP 								!so the obs file does not need to be prepared full timestamp
                  Simu_hrflux(2,yk1)=NEE								!Simu_ and obs_ has the same dimension
                  Simu_hrflux(3,yk1)=Recoh
                  Simu_hrflux(4,yk1)=simuCH4
				  ! write(*,*)'yr',yr+first_year-19,'days',days,'i',i,'Simu_hrflux(1,yk1)',Simu_hrflux(1,yk1)
                  yk1=yk1+1 													!k1 counts the rows of obs variables
                  endif

                  if(isnan(gpp))then
                      write(*,*)'gpp is nan'
                      return
                  endif
              enddo              ! end of dtimes
              if((GDD5.gt.gddonset) .and. phenoset.eq.0) then
                pheno=days
                phenoset=1
              endif

!             +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

!             output results of canopy and soil models, daily
!             daily output
              INT_d=-9999
              DRAIN_d=-9999
              SH_d=-9999
              CSOIL_d=QC(6)+QC(7)+QC(8)
              LMA_d=QC(1)/0.48
              NSOIL_d=QN(6)+QN(7)+QN(8)+QNminer

              Rgrowth_d=-9999
              abvLitter=QC(4)  !-9999
              blLitter=QC(5) !-9999
!            write(*,*)yr,days,LAI,gpp_d,npp_d

            if(yr.gt.yrs_eq)then
            ! if(yr.gt.18)then  !9
                daily=daily+1
  		!	if (daily .le. 300) then
		!	 write (*,*) "GPP_d",GPP_d,"NEE_d",NEE_d,"Reco_d",Reco_d
		!	endif
            Simu_dailyflux(1,daily)=GPP_d ! Leaf
            Simu_dailyflux(2,daily)=NEE_d	! Wood
            Simu_dailyflux(3,daily)=Reco_d	! Coarse roots
            Simu_dailyflux(4,daily)=QC(1)!*1.5
            Simu_dailyflux(5,daily)=QC(6)!*1.5
            Simu_dailyflux(6,daily)=QC(2)!*0.48
            Simu_dailyflux(7,daily)=QC(7)!*0.48
            Simu_dailyflux(8,daily)=QC(3)
            Simu_dailyflux(9,daily)=QC(4)
            Simu_dailyflux(10,daily)=(QC(6)+QC(7)+QC(8))!*13.8   ! Soil
            Simu_dailyflux(11,daily)=pheno   ! Soil
            Simu_dailyflux(12,daily)=QC(5) !QC(1)/(QC(1)+QC(4))
                Simu_dailyflux(13,daily)=NPP_d
                Simu_dailyflux(14,daily)=Rh_d
                Simu_dailyflux(15,daily)=Ra_d

            Simu_dailyflux14(1,daily)=GPP_d
            Simu_dailyflux14(2,daily)=NEE_d
            Simu_dailyflux14(3,daily)=Reco_d	!Rh
            Simu_dailyflux14(4,daily)=NPP_d!*1.5
            Simu_dailyflux14(5,daily)=Ra_d!*1.5
            Simu_dailyflux14(6,daily)=QC(1)
            Simu_dailyflux14(7,daily)=QC(2)
            Simu_dailyflux14(8,daily)=QC(3)
            Simu_dailyflux14(9,daily)=QC(4)
!            Simu_dailyflux14(9,daily)=add
            Simu_dailyflux14(10,daily)=QC(5)
!            Simu_dailyflux14(10,daily)=storage
            Simu_dailyflux14(11,daily)=QC(6)
!            Simu_dailyflux14(11,daily)=LAIMAX
            Simu_dailyflux14(12,daily)=Rh_d
!            Simu_dailyflux14(13,daily)=LAI
            Simu_dailyflux14(13,daily)=QC(7)
            Simu_dailyflux14(14,daily)=QC(8)!*0.48

!            Simu_dailyflux14(1,daily)=QC(1)
!            Simu_dailyflux14(2,daily)=QC(2)
!            Simu_dailyflux14(3,daily)=QC(3)	!Rh
!            Simu_dailyflux14(4,daily)=QC(4)!*1.5
!            Simu_dailyflux14(5,daily)=QC(5)*1.5
!            Simu_dailyflux14(6,daily)=QC(6)
!            Simu_dailyflux14(7,daily)=QC(7)
!            Simu_dailyflux14(8,daily)=QC(8)
!!            Simu_dailyflux14(9,daily)=QC(4)
!            Simu_dailyflux14(9,daily)=add
!!            Simu_dailyflux14(10,daily)=QC(5)
!            Simu_dailyflux14(10,daily)=storage
!!            Simu_dailyflux14(11,daily)=QC(6)
!            Simu_dailyflux14(11,daily)=LAIMAX
!            Simu_dailyflux14(12,daily)=Rh_d
!            Simu_dailyflux14(13,daily)=LAI
!!            Simu_dailyflux14(12,daily)=QC(7)
!!            Simu_dailyflux14(13,daily)=QC(8)!*0.48
!            Simu_dailyflux14(14,daily)=Tleaf(1)!QC(4)
            !
!            if (do_soilphy)
!            write (*,*) 'simuwcl',wcl(1)           !dbice
                    Simu_dailywater(1:10,daily)= wcl(1:10)        ! not aggregated to daily, value should represents 23:00
!                    Simu_dailywater(1:10,daily)= wsc(1:10)
            Simu_dailywater(11:20,daily)=liq_water(1:10)
            Simu_dailywater(21:30,daily)=ice(1:10)
            Simu_dailywater(31,daily)= zwt_d/24.
!            write (*,*) 'wcl(1)',wcl(1),'Simu_dailywater(1,daily)',Simu_dailywater(1,daily)
! *** ..int methane
            Simu_dailyCH4(1,daily)=simuCH4_d
            Simu_dailyCH4(2,daily)=Pro_sum_d
            Simu_dailyCH4(3,daily)=Oxi_sum_d
            Simu_dailyCH4(4,daily)=Fdifu1_d
            Simu_dailyCH4(5,daily)=Ebu_sum_sat_d
            Simu_dailyCH4(6,daily)=Pla_sum_d
             Simu_dailyCH4(7:16,daily)=CH4V_d(1:10)/24
            Simu_dailyCH4(17,daily)=Ebu_sum_unsat_d
!  *** .int soil thermal
            Simu_dailysoilt(1:11,daily)=soilt_d_simu(1:11)/24.
!            Simu_dailyst(1:11,daily) = testout(1:11)
            Simu_dailyice(1:10,daily)=ice_d_simu(1:10)/24.
            Simu_dailywatertable(1,daily)=zwt_d/24.
            Simu_snowdepth(1,daily)=snow_dsim
            Simu_TD(1,daily) = TD_d / 24.
             endif  !end of daily+1

!            if(yr.ge.(yrlim-first_year+1) .and. days.ge.dylim) goto 650
!            write (122,1202) zwt,snow_dsim
        enddo                         ! end of idays
!              do i=1,2190
!        write (*,*) 'i',i,'Simu_dailysoilt(11)',Simu_dailysoilt(11,i),'Simu_dailysoilt(1)',Simu_dailysoilt(1,i)
!              enddo
            storage=accumulation
            stor_use=Storage/times_storage_use
!            if(yr.eq.yrs_eq+yr_length .and. MCMC .eq. 1)then
!                write(*,*)yr,LAI,gpp_yr,NPP_yr,pheno
!                write(61,601)year,LAI,gpp_yr,NPP_yr,real(pheno)
!            endif
!            if(yr.eq.yrs_eq+yr_length .and. do_methane_da) then
!                write(*,*)'yr',yr,'LAI',LAI,'zwt',zwt,'simuCH4_yr',simuCH4_yr
!                write(61,601)year,LAI,gpp_yr,NPP_yr,real(pheno)
!            endif
!             if (do_methane_da) then
!                 write (*,*) year,zwt,testout(2),wsc(1)
!             endif
!            if(MCMC.ne.1) then
!            if (.not. do_co2_da) then
!            write (*,*) 'do_da=',do_da,'do_fcast=',do_fcast
            if (.not. do_da) then
                if (do_methane_fcast) then
                    write (*,*) year,simuCH4_yr,Pro_sum_yr,Oxi_sum_yr,Fdifu1_yr,Ebu_sum_sat_yr,Pla_sum_yr
                elseif (do_co2_fcast) then
                        write (*,*) year,'LAI',LAI,'gpp',gpp_yr,'npp',NPP_yr,'ra',Ra_yr
                else
                    write(*,*)'annual_summary:',yr,year,'LAI',LAI,'gpp',gpp_yr,'VcmxT',VcmxT_yr,'radsol',radsol_yr,&
                        &   'npp',NPP_yr,'ra',Ra_yr,'add',add_yr,'store',store_yr,'NSC',NSC_yr,'NSN',NSN_yr,&
                        &   N_up_yr,N_fix_yr,N_dep_yr,N_leach_yr,N_vol_yr,N_tran_yr,N_def_yr,QNmin_yr,N_min_yr,N_imb_yr,&
                        &   'P1',Pool1,'P2',Pool2,'P3',Pool3,'P4',Pool4,'P5',Pool5,'P6',Pool6,'P7',Pool7,'P8',Pool8,'simuCH4_yr', &
                        &   simuCH4_yr
!                        ,transp_yr,evap_yr,runoff_yr,rain_yr,zwt_yr/365/24,&
!                               zwt_read_yr/365/24,sub_depth_yr/365/24,infilt_yr
                    write(*,*)year,LAI,gpp_yr,NPP_yr,pheno
                    write(61,601)year,LAI,gpp_yr,NPP_yr,Ra_yr,Rh_yr, &
                    &   ET,rain_yr,transp_yr,evap_yr,runoff_yr,GL_yr,    &
                    &   GW_yr,GR_yr,Pool1,Pool2,Pool3,Pool4,Pool5,   &
                    &   Pool6,Pool7,Pool8,out1_yr,out2_yr,out3_yr,   &
                    &   out4_yr,out5_yr,out6_yr,out7_yr,out8_yr,     &
                    &   simuCH4_yr,Pro_sum_yr,Oxi_sum_yr,Fdifu1_yr, &
                    &   Ebu_sum_unsat_yr,Ebu_sum_sat_yr,Pla_sum_yr
                endif
601         format(i7,",",36(f15.4,","))
            endif

!              do i=1,daily
!        write (*,*) 'i',i,'Simu_dailysoilt(11)',Simu_dailysoilt(11,i),'Simu_dailysoilt(1)',Simu_dailysoilt(1,i)
!              enddo

            accumulation=0.0
            onset=0
         enddo            !end of simulations multiple years
!              do i=1,2190
!        write (*,*) 'i',i,'Simu_dailysoilt(11)',Simu_dailysoilt(11,i),'Simu_dailysoilt(1)',Simu_dailysoilt(1,i)
!              enddo
!         if(MCMC.ne.1)then
         if (.not. do_da) then
              do i=1,daily
                  if (do_methane_fcast) then
!                     write(62,602)i,(Simu_dailyflux(j,i),j=1,15)
!                     write(662,6602)i,(Simu_dailyflux14(j,i),j=1,14)
!                     write(63,603)i,(Simu_dailywater(j,i),j=1,31)
                     write(64,604)i,(Simu_dailyCH4(j,i),j=1,17),Simu_dailywatertable(1,i)
		  elseif (do_co2_fcast) then
			 write(62,602)i,(Simu_dailyflux(j,i),j=1,15)
		         write(70,700)i,(Simu_dailywater(j,i),j=11,13),(Simu_dailysoilt(j,i),j=2,3)
                  else
                     write(62,602)i,(Simu_dailyflux(j,i),j=1,15)
                     write(662,6602)i,(Simu_dailyflux14(j,i),j=1,14)
                     write(70,700)i,(Simu_dailywater(j,i),j=11,13),(Simu_dailysoilt(j,i),j=2,3)
                     write(63,603)i,(Simu_dailywater(j,i),j=1,31)
                     write(64,604)i,(Simu_dailyCH4(j,i),j=1,17),Simu_dailywatertable(1,i)
                     write(65,605)i,(Simu_dailysoilt(j,i),j=1,11)
!                     write(65,605)i,(Simu_soiltemp(j,i),j=1,11)
                     write(66,606)i,(Simu_dailyice(j,i),j=1,10)
!                     write(67,607)i,(Simu_dailywatertable(j,i),j=1,1)
                     write(68,608)i,(Simu_snowdepth(j,i),j=1,1)
                     write(69,608)i,(Simu_TD(j,i),j=1,1)
                  endif
              enddo

!             do i=1,k1
!                write(91,605)i,(Simu_soiltemp(j,i),j=1,11)
!                write(92,609)i,(Simu_soilwater(j,i),j=1,30)
!             end do

602      format((i7),",",14(f15.4,","),(f15.4))
6602     format((i7),",",13(f15.4,","),(f15.4))
603      format((i7),",",30(f15.4,","),(f15.4))
604      format((i7),",",17(f15.4,","),(f15.4))
605      format((i7),",",10(f15.4,","),(f15.4))
606      format((i7),",",9(f15.4,","),(f15.4))
607      format((i7),",",(f15.4))
608      format((i7),",",(f15.4))
700      format((i7),",",4(f15.4,","),(f15.4))
         endif





999      continue

    return
    end


!     ****************************************************************************
      subroutine consts(pi,tauL,rhoL,rhoS,emleaf,emsoil,                &
     &   Rconst,sigma,cpair,Patm,Trefk,H2OLv0,airMa,H2OMw,chi,Dheat,    &
     &   wleaf,gsw0,Vcmx0,eJmx0,theta,conKc0,conKo0,Ekc,Eko,o2ci,       &
     &   Eavm,Edvm,Eajm,Edjm,Entrpy,gam0,gam1,gam2)

      real tauL(3), rhoL(3), rhoS(3)
      pi = 3.1415926
!     physical constants
      tauL(1)=0.1                  ! leaf transmittance for vis
      rhoL(1)=0.1                  ! leaf reflectance for vis
      rhoS(1)=0.1                  ! soil reflectance for vis
      tauL(2)=0.425                ! for NIR
      rhoL(2)=0.425                ! for NIR
      rhoS(2)=0.3                  ! for NIR - later function of soil water content
      tauL(3)=0.00                 ! for thermal
      rhoL(3)=0.00                 ! for thermal
      rhoS(3)=0.00                 ! for thermal
      emleaf=0.96
      emsoil=0.94
      Rconst=8.314                 ! universal gas constant (J/mol)
      sigma=5.67e-8                ! Steffan Boltzman constant (W/m2/K4)
      cpair=1010.                  ! heat capapcity of air (J/kg/K)
      Patm=101325. !1.e5           ! atmospheric pressure  (Pa)
      Trefk=293.2                  !reference temp K for Kc, Ko, Rd
      H2OLv0=2.501e6               !latent heat H2O (J/kg)
      AirMa=29.e-3                 !mol mass air (kg/mol)
      H2OMw=18.e-3                 !mol mass H2O (kg/mol)
      chi=0.93                     !gbH/gbw
      Dheat=21.5e-6                !molecular diffusivity for heat
!     plant parameters
      gsw0 = 1.0e-2                !g0 for H2O in BWB model
!      eJmx0 = Vcmx0*2.7            !@20C Leuning 1996 from Wullschleger (1993)   ! commented on Feb 19 2019 for acclimation study
      theta = 0.9
      wleaf=0.01                   !leaf width (m)

!     thermodynamic parameters for Kc and Ko (Leuning 1990)
      conKc0 = 302.e-6                !mol mol^-1
      conKo0 = 256.e-3                !mol mol^-1
      Ekc = 59430.                    !J mol^-1
      Eko = 36000.                    !J mol^-1
!     Erd = 53000.                    !J mol^-1
      o2ci= 210.e-3                   !mol mol^-1

!     thermodynamic parameters for Vcmax & Jmax (Eq 9, Harley et al, 1992; #1392)
      Eavm = 116300.               !J/mol  (activation energy)
      Edvm = 202900.               !J/mol  (deactivation energy)
      Eajm = 79500.                !J/mol  (activation energy)
      Edjm = 201000.               !J/mol  (deactivation energy)
!      Entrpy = 650.                !J/mol/K (entropy term, for Jmax & Vcmax)   !commented for acclimation study read in from pars

!     parameters for temperature dependence of gamma* (revised from von Caemmerer et al 1993)
      gam0 = 28.0e-6               !mol mol^-1 @ 20C = 36.9 @ 25C
      gam1 = .0509
      gam2 = .0010
      return
      end
!****************************************************************************

!      a sub-model for calculating C flux and H2O flux of a canopy
!      adapted from a two-leaf canopy model developed by Wang Yingping

        subroutine canopy(gpp,evap,transp,Acanop,Hcanop,Rsoilabs, &  ! outputs
          &               fwsoil,topfws,           &! from soil model
          &               LAI,Sps,&
          &               doy,hour,radsol,tair,Dair,eairP,&! from climate data file,including
          &               wind,rain,&
          &               Rnet,G,Esoil,Hcrop,Ecstot,Anet,&
          &               Tsoil,DepH2O,&
          &               wsmax,wsmin,&  !constants specific to soil and plant
          &               lat,co2ca,a1,Ds0,Vcmx0,extkU,xfang,alpha,&
          &               stom_n,pi,tauL,rhoL,rhoS,emleaf,emsoil,&
          &               Rconst,sigma,cpair,Patm,Trefk,H2OLv0,airMa,&
          &               H2OMw,chi,Dheat,wleaf,gsw0,eJmx0,theta,&
          &               conKc0,conKo0,Ekc,Eko,o2ci,Eavm,Edvm,Eajm,&
          &               Edjm,Entrpy,gam0,gam1,gam2,wcl,gddonset,&
          &               sftmp,Tsoill,testout,ice,&                                                   !added for soil thermal..int
          &               water_table_depth,snow_depth,Tsnow,Twater,Tice,water_tw,ice_tw,diff_s,&      !added for soil thermal..int
          &               diff_snow,albedo_snow,resht,thd_snow_depth,thksl,zwt,liq_water,shcap_snow,&  !added for soil thermal..int
          &               condu_snow,condu_b,depth_ex,dcount_soil,do_soilphy,VcmxT,&                         !added for soil thermal..int
          &               Tleaf,input_tsoil)    ! Tleaf added for testing the leaf temperature response to warming treatment Feb 2019

      real lat,doy
      real gpp,evap,transp,LAI,Rsoilabs
      real tauL(3),rhoL(3),rhoS(3),reffbm(3),reffdf(3)
      real extkbm(3),extkdm(3)
      real Radabv(2),Qcan(3,2)
      real gddonset,VcmxT
!     extra variables used to run the model for the wagga data
      real topfws        ! from siol subroutine
      integer idoy,ihour,ileaf
      integer jrain,i,j,k
!   *** ..int
      real Tsnow,Twater,Tice,water_tw,ice_tw
      logical do_soilphy
!   ***
      real Tleaf(2) ! Tleaf added for testing the leaf temperature response to warming treatment Feb 2019
!     additional arrays to allow output of info for each layer
      real RnStL(5),QcanL(5),RcanL(5),AcanL(5),EcanL(5),HcanL(5)
      real GbwcL(5),GswcL(5),hG(5),hIL(5)
      real Gaussx(5),Gaussw(5),Gaussw_cum(5)
      real wcl(10)
      real Tsoill(10),testout(11),ice(10),thksl(10),liq_water(10)
      real input_tsoil(11)
      character*80 commts
!     Normalised Gaussian points and weights (Goudriaan & van Laar, 1993, P98)
!     5-point
      data Gaussx/0.0469101,0.2307534,0.5,0.7692465,0.9530899/
      data Gaussw/0.1184635,0.2393144,0.2844444,0.2393144,0.1184635/
      data Gaussw_cum/0.11846,0.35777,0.64222,0.88153,1.0/

!     calculate beam fraction in incoming solar radiation
      call  yrday(doy,hour,lat,radsol,fbeam)
      idoy=int(doy)
      hours=idoy*1.0+hour/24.0
      coszen=sinbet(doy,lat,pi,hour)             !cos zenith angle of sun

!     set windspeed to the minimum speed to avoid zero Gb
      if(wind.lt.0.01) wind=0.01
!     calculate soil albedo for NIR as a function of soil water (Garratt pp292)
      if(topfws.gt.0.5) then
            rhoS(2)=0.18
      else
            rhoS(2)=0.52-0.68*topfws
      endif
!        assign plant biomass and leaf area index at time t
!        assume leaf biomass = root biomass
      FLAIT =LAI
	  ! write (*,*) "in canopy LAI",LAI
      eairP=esat(Tair)-Dair                !air water vapour pressure
      radabv(1)=0.5*radsol                 !(1) - solar radn
      radabv(2)=0.5*radsol                 !(2) - NIR
!     call multilayer model of Leuning - uses Gaussian integration but radiation scheme
!     is that of Goudriaan
			! write (*,*) "gpp before xlayers",GPP
      call xlayers(Sps,Tair,Dair,radabv,fbeam,eairP,&                                   !
     &           wind,co2ca,fwsoil,wcl,FLAIT,coszen,idoy,hours,&
     &           tauL,rhoL,rhoS,xfang,extkd,extkU,wleaf,&
     &           Rconst,sigma,emleaf,emsoil,theta,a1,Ds0,&
     &           cpair,Patm,Trefk,H2OLv0,AirMa,H2OMw,Dheat,&
     &           gsw0,alpha,stom_n,wsmax,wsmin,VcmxT,&
     &           Vcmx0,eJmx0,conKc0,conKo0,Ekc,Eko,o2ci,&
     &           Eavm,Edvm,Eajm,Edjm,Entrpy,gam0,gam1,gam2,&
     &           extKb,Rsoilabs,Acan1,Acan2,Ecan1,Ecan2,&
     &           RnStL,QcanL,RcanL,AcanL,EcanL,HcanL,GbwcL,GswcL,gddonset,&
     &           testout,Rsoilab1,Rsoilab2,QLleaf,QLair,raero,do_soilphy,&  ! added from soil thermal ..int
     &           G,Esoil,Hsoil,Tleaf) ! G,Esoil,Hsoil added from soil thermal ..int
     ! Tleaf added for testing the leaf temperature response to warming treatment Feb 2019
			! write (*,*) "gpp after xlayers",GPP,"Acan1",Acan1,"Acan2",Acan2
!   *** ..int   added 'testout,Rsoilab1,Rsoilab2,QLleaf,QLair,raero,do_soilphy,G,Esoil,Hsoil'
         if (do_soilphy) then
             call Tsoil_simu(Rsoilab1,Rsoilab2,QLleaf,QLair,Tair,Dair,&
                    &         fbeam,FLAIT,sigma,emsoil,rhoS,Rconst,&
                    &         extkd,extkb,cpair,Patm,AirMa,H2OMw,&
                    &         H2OLv0,wcl,raero,wsmax,wsmin,wind,sftmp,Tsoill,testout,ht,ice,&
                    &         snow_depth,Tsnow,Twater,Tice,water_tw,ice_tw,diff_s,G,tsoil,&
                    &         diff_snow,albedo_snow,resht,thd_snow_depth,thksl,zwt,Esoil,Hsoil,liq_water, &
                    &         shcap_snow,condu_snow,condu_b,depth_ex,dcount_soil,input_tsoil)
         endif
!     write (84,184) Esoil
!184   format(f15.9,",")
!   ***

         Acanop=Acan1+Acan2
         Ecanop=Ecan1+Ecan2
         gpp=Acanop*3600.0*12.0                           ! every hour, mol to g C m-2 h-1

         transp=AMAX1(Ecanop*3600.0/(1.0e6*(2.501-0.00236*Tair)),0.) ! mm H2O /hour
         evap=AMAX1(Esoil*3600.0/(1.0e6*(2.501-0.00236*Tair)),0.)
!         evap=evap*0.8
!        H2OLv0=2.501e6               !latent heat H2O (J/kg)

      return
      end

!****************************************************************************
!   autotrophic respiration
    subroutine respiration(LAIMIN,GPP,Tair,Tsoil,DepH2O,&
     &                       Q10,Rl0,Rs0,Rr0,SNRauto,&
     &                       LAI,SLA,bmstem,bmroot,bmleaf,&
     &                       StemSap,RootSap,NSC,fnsc,&
     &                       RmLeaf,RmStem,RmRoot,Rmain)
!     calculate plant and soil respiration by the following equation:
!     RD=BM*Rd*Q10**((T-25)/10) (Sun et al. 2005. Acta Ecologica Sinica)
    implicit none
    real LAIMIN,LAI,GPP,SLA
    real Tair,Tsoil,DepH2O
    real bmstem,bmroot,bmleaf,StemSap,RootSap
    real NSC,fnsc
    real Q10
    real RmLeaf,RmStem,RmRoot,Rmain
    real Rl0,Rs0,Rr0,SNRauto
    real conv                  ! converter from "umol C /m2/s" to "gC/m2/hour"

    conv=3600.*12./1000000.    ! umol C /m2/s--> gC/m2/hour
!    print*,'respiration',Rl0,Rs0,Rr0
    if(LAI.gt.LAIMIN) then
        RmLeaf=Rl0*SNRauto*bmleaf*0.48*SLA*0.1     &
            &   *Q10**((Tair-10.)/10.)*fnsc*conv
        RmStem=Rs0*SNRauto*StemSap*0.001*Q10**((Tair-25.)/10.)*fnsc*conv
        RmRoot=Rr0*SNRauto*RootSap*0.001*Q10**((Tair-25.)/10.)*fnsc*conv
!        print*,'greater than LAImin',RmLeaf,RmStem,RmRoot
    else
        RmLeaf=0.3*GPP
        RmStem=0.3*GPP
        RmRoot=0.4*GPP
    endif
        Rmain=Rmleaf+Rmstem+Rmroot
    if(Rmain > 0.0015*NSC)then             ! If Total autotrophic respiration greater than 0.15% of Nonstructure Carbon, rescale.
        Rmleaf=Rmleaf/Rmain*0.0015*NSC
        Rmstem=Rmstem/Rmain*0.0015*NSC
        Rmroot=Rmstem/Rmain*0.0015*NSC
        Rmain=Rmleaf+Rmstem+Rmroot
    endif
!    print*,'end respiration',RmLeaf,RmStem,RmRoot
    return
    end

!*******************************************************************
!     subroutine for soil moisture
    subroutine soilwater(wsmax,wsmin,rdepth,FRLEN,THKSL,    &   !constants specific to soil/plant
     &                rain,transp,evap,wcl,runoff,infilt,   &   !inputs
     &                fwsoil,topfws,omega,wsc,zwt,phi,      &   !outputs
     &                liq_water,infilt_rate,melt,ta,day_mod, &  ! added from soil thermal ..int
     &                do_soilphy,snow_depth,ice,testout,m,use_plinit)
!     All of inputs, the unit of water is 'mm', soil moisture or soil water content is a ratio
    implicit none
!   soil traits
    real wsmax,wsmin,wsmaxL(10),wsminL(10) !from input percent x%
    real(KIND=8) FLDCAP,WILTPT ! ie. 0.xx
!   plant traits
    real rdepth
    integer nfr,m,use_plinit !m is the hour index
!   climate conditions
    real rain ! mm/hour
!   output from canopy model
    real evap,transp
!   output variables
    real fwsoil,topfws,omega
    real fw(10),ome(10)

    real thksl(10),depth(10),wsc(10),WUPL(10),EVAPL(10),SRDT(10)
    real plantup(10)
    real Tsrdt
    real frlen(10) !fraction of root length in every layer
    real wcl(10) !volum ratio
 !      real fwcln(10) !  fraction of water in layers, like field capacity
    real DWCL(10),Tr_ratio(10)
    real wtadd,twtadd,infilt,runoff,tr_allo

    real exchangeL,supply,demand,omegaL(10)
    integer i,j,k
    real infilt_max
!    ******************
 !      characters annotation for water table module  -MS
    real vtot,phi
    real zmax,thetasmin,zthetasmin,az
    real zwt,zwt1,zwt2,zwt3
 !      water table characters annotation end here  -MS
!    *******************
!   *** ..int added from soil thermal
    real melt,ta,rain_new,rain_t,snow_depth,infilt_rate
    integer day_mod
    logical do_soilphy

    real liq_water(10),ice(10),testout(11)
    real ddd,cc,infilt_dbmemo
!    integer days,dtimes
!   ***
!    infilt_max=15.
    infilt_max=4.
    WILTPT =wsmin/100.000
    FLDCAP =wsmax/100.000

    do i=1,10
        dwcl(i)=0.0
        evapl(i)=0.0
        WUPL(i)=0.0
        SRDT(i)=0.0
        DEPTH(i)=0.0
    enddo

!   Determine which layers are reached by the root system.
!   Layer volume (cm3)
    DEPTH(1)=THKSL(1)
    DO i=2,10
        DEPTH(i)=DEPTH(i-1)+THKSL(i)
    enddo
    do i=1,10
        IF(rdepth.GT.DEPTH(i)) nfr=i+1
    enddo
    IF (nfr.GT.10) nfr=10

!   *** ..int
!   ******** added for soil thermal
    if (do_soilphy) then
       rain_new = rain
!       if (ta .lt. -0.4) rain_new =0.       !dbice   !tuneice
      if (ta .lt. -4.) rain_new =0.       !dbice   !tuneice
!       if (testout(1) .lt. -4.) rain_new =0.
!  **********   here it defines how the melt water is added to water input
!  **********   add melted water hourly
       rain_t =melt/24+rain_new
!  **********   add melted water daily all at once

!       if (day_mod .eq. 0) then
!           rain_t =melt+rain_new
!       else
!           rain_t=rain_new
!       endif

!       print*,'infilt',rain_t,melt,rain_new   !dbmemo
           infilt=infilt+rain_t
!           infilt=infilt+rain_t * 0.8 ! added by Chris for interception
       if (ice(1) .gt. 0.0) then
           !infilt = 0.0
       endif
    else
        infilt=infilt+rain
    endif
!   ***
    infilt_dbmemo=infilt

! *** water infiltration through layers
!    infilt=infilt+rain  !mm/hour    ! ..int commented lines for soil thermal module, included in the previous loop

!   Loop over all soil layers.
    TWTADD=0
    IF(infilt.GE.0.0)THEN
!       Add water to this layer, pass extra water to the next.
!        cc = wcl(1)                            !dbmemo
        WTADD=AMIN1(INFILT,infilt_max,AMAX1((FLDCAP-wcl(1))*thksl(1)*10.0,0.0)) ! from cm to mm
!       change water content of this layer
!        write(*,*) 'before  update',wcl(1)    !dbmemo
        WCL(1)=(WCL(1)*(thksl(1)*10.0)+WTADD)/(thksl(1)*10.0)
!        ddd = (FLDCAP-cc)*thksl(1)*10.0        !dbmemo
!         dd = (FLDCAP-0.564999998)*thksl(1)*10.0   !dbmemo
!        write (*,*) 'wcl(1)',wcl(1), 'WTADD',WTADD,'INFILT',INFILT,'infilt_max',infilt_max,'ddd',ddd    !dbmemo
!       FWCLN(I)=WCL(I)       !  /VOLUM(I)! update fwcln of this layer
        TWTADD=TWTADD+WTADD       !calculating total added water to soil layers (mm)
        INFILT=INFILT-WTADD !update infilt
    ENDIF
!        write (*,*) 'wsc(1)',wsc(1)!dbmemo
! calculating runoff, I don't see differences in zwt
!  ******** runoff method 1 before !dbice
!    if (do_soilphy) then
!       if (wsc(1) .gt. 56.5) then  !be careful = phi*thksl(mm)*
!
!           runoff= INFILT*infilt_rate  !(infilt_rate = 0.001 defined earlier)    infilt_rate= 0.001
!       else
!!           runoff=INFILT*0.0019   ! no dif in 0.00019 and 0.0019
!           runoff=INFILT*infilt_rate
!!       write (*,*) runoff,infilt
!       endif
!    else
!          runoff=INFILT*0.001              ! Shuang added this elseif line
!    endif
!  ************************

!!  ******** runoff method 1
!    if (do_soilphy) then
!!       if (wsc(1) .lt. 20.5) then  !be careful = phi*thksl(mm)*
!       if (liq_water(1) .lt. 0.055) then   ! m
!           runoff= INFILT*0.2  !(infilt_rate = 0.0017 defined earlier by Yuan, changed  to 0.001 by shuang )
!       else
!           runoff=INFILT*0.005   ! no dif in 0.00019 and 0.0019
!!           runoff=INFILT*infilt_rate
!!       write (*,*) runoff,infilt
!       endif
!    else
!          runoff=INFILT*0.001              ! Shuang added this elseif line
!    endif
!!  ************************
 !  ******** runoff method 1 !dbice
    if (do_soilphy) then
!       if (wsc(1) .gt. 56.5) then  !be careful = phi*thksl(mm)*
!       if (wsc(1) .gt. 55.5) then  !be careful = phi*thksl(mm)*
!           runoff= INFILT*0.0003  !!(infilt_rate = 0.0017 defined earlier by Yuan, changed  to 0.001 by shuang )
!!           runoff= INFILT*infilt_rate
!       else
!           runoff=INFILT*0.0019   ! no dif in 0.00019 and 0.0019
!           runoff= INFILT*0.0002
           runoff= INFILT*0.005  ! modify
!           runoff=INFILT*infilt_rate
!       write (*,*) runoff,infilt
!       endif
    else
          runoff=INFILT*0.001              ! Shuang added this elseif line
    endif
!  ************************

!  ******** runoff method 2
!    runoff=INFILT*0.0019
!  ************************

!!  ******** runoff method 3 !tuneice
!    if (do_soilphy) then
!!       if (wsc(1) .lt. 20.5) then  !be careful = phi*thksl(mm)*
!       if (liq_water(1) .lt. 0.055) then   ! m
!           runoff= INFILT*0.002  !(infilt_rate = 0.0017 defined earlier by Yuan, changed  to 0.001 by shuang )
!       else
!           runoff=INFILT*0.005   ! no dif in 0.00019 and 0.0019
!!           runoff=INFILT*infilt_rate
!!       write (*,*) runoff,infilt
!       endif
!    else
!          runoff=INFILT*0.001              ! Shuang added this elseif line
!    endif
!!  ************************

!   ..int commented lines for soil thermal
!   runoff
!    runoff=INFILT*0.001   ! Shuang Modifed  Mar16 used to be 0.0019, the water lose too much lowest wt was >400
    infilt = infilt-runoff


!
!!!!******************************************0.22***************************************************************
!    write (*,*) 'use_plinit',use_plinit
    if (transp .gt. 0.15) then
     !   if (use_plinit .eq. 13 .or. use_plinit .eq. 23 ) then
		if (use_plinit .eq. 13 ) then
            infilt = infilt+transp*0.15
        elseif (use_plinit .eq. 15 ) then
            infilt = infilt+transp*0.15
        elseif (use_plinit .eq. 16 .or. use_plinit .eq. 26 .or. use_plinit .eq. 23) then
            infilt = infilt+transp*0.25


		elseif (use_plinit .eq. 25 ) then !.or. use_plinit .eq. 24
		    infilt = infilt+transp*0.5
        endif
    else
 !       if (use_plinit .eq. 13 .or. use_plinit .eq. 23) then
		 if (use_plinit .eq. 13) then
            infilt = infilt+transp*0.05
        elseif (use_plinit .eq. 15) then
            infilt = infilt+transp*0.05
        elseif (use_plinit .eq. 16 .or. use_plinit .eq. 26 .or. use_plinit .eq. 23) then
            infilt = infilt+transp*0.15

		elseif (use_plinit .eq. 25 ) then
	     	 infilt = infilt+transp*0.5
        endif
    endif

    if (evap .gt. 0.4) then
    !    if (use_plinit .eq. 13 .or. use_plinit .eq. 23 ) then
       if (use_plinit .eq. 13) then
            infilt = infilt+evap*0.15
        elseif (use_plinit .eq. 15) then
            infilt = infilt+evap*0.15
        elseif (use_plinit .eq. 16 .or. use_plinit .eq. 26 .or. use_plinit .eq. 23) then
            infilt = infilt+evap*0.25
			elseif (use_plinit .eq. 25 ) then
			infilt = infilt+evap*0.5
        endif
    else
	!    if (use_plinit .eq. 13 .or. use_plinit .eq. 23) then
	    if (use_plinit .eq. 13) then
            infilt = infilt+evap*0.05
        elseif (use_plinit .eq. 15) then
            infilt = infilt+evap*0.05
        elseif (use_plinit .eq. 16 .or. use_plinit .eq. 26 .or. use_plinit .eq. 23) then
                infilt = infilt+evap*0.15
		elseif (use_plinit .eq. 25 ) then
			infilt = infilt+evap*0.5
		endif
    endif


!    if (evap .gt. 0.4) then
!        infilt = infilt+evap!*0.5!*1.2
!    elseif (evap .le. 0.4 .and. evap .gt. 0.35) then
!        infilt = infilt+evap*0.5
!    else
!        infilt = infilt+evap*0.1!0.07
!    endif
!!*********************************************************************************************************
!   water redistribution among soil layers
    do i=1,10
!        wsc(i)=Amax1(0.00,(wcl(i)-wiltpt)*THKSL(i)*10.0)
        wsc(i)=Amax1(0.00,(wcl(i)-wiltpt)*THKSL(i)*10.0)
!   ..int commented lines for soil thermal
!        omegaL(i)=Amax1(0.001,(wcl(i)-WILTPT)/(FLDCAP-WILTPT))
        if (do_soilphy) then
           omegaL(i)=Amax1(0.001,(liq_water(i)*100./thksl(i)-WILTPT)/(FLDCAP-WILTPT))
!           print*,'omegaL',i,omegaL(i),liq_water(i),WILTPT,FLDCAP
        else
           omegaL(i)=Amax1(0.001,(wcl(i)-WILTPT)/(FLDCAP-WILTPT))
        endif
    enddo

!        write (*,*) wsc(1),'wsc(i)=Amax1(0.00,(wcl(i)-wiltpt)*THKSL(i)*10.0)'  !dbmemo

    supply=0.0
    demand=0.0

    !dbmemo
!    if (omegaL(1) .gt. 0.3 .and. (omegaL(2) .le. 0.3 .or. omegaL(3) .le. 0.3)) then
!        write (*,*) 'smaller than 0.3'
!    endif

    do i=1,9
        if(omegaL(i).gt.0.8)then
            supply=wsc(i)*(omegaL(i)-0.8)
!            supply=wsc(i)*omegaL(i)
            demand=(FLDCAP-wcl(i+1))*THKSL(i+1)*10.0      &
                &               *(1.0-omegaL(i+1))
!            exchangeL=AMIN1(supply,demand)
            exchangeL=AMIN1(supply,demand)   !revised by Chris Lu
            wsc(i)=wsc(i)- exchangeL
!            wsc(i)=AMAX1(10.00,(wsc(i)- exchangeL))
            wsc(i+1)=wsc(i+1)+ exchangeL        !revised by Shuang
            wcl(i)=wsc(i)/(THKSL(i)*10.0)+wiltpt
            wcl(i+1)=wsc(i+1)/(THKSL(i+1)*10.0)+wiltpt

            endif
    enddo
!        write (*,*) wsc(1),'wsc(i)=wsc(i)- exchangeL',exchangeL,'exchangeL',wiltpt,'wiltpt'   !dbmemo


    if(all(omegaL .gt. 0.8))then  !added by Chris to prevent subsurface runoff when upper layer is frozen
       wsc(10)=wsc(10)-wsc(10)*0.00001     ! Shuang modifed
       runoff = runoff+wsc(10)*0.00001     ! Shuang modifed
    wcl(10)=wsc(10)/(THKSL(10)*10.0)+wiltpt
    end if

!    end of water redistribution among soil layers

!   Redistribute evaporation among soil layers
    Tsrdt=0.0
    DO i=1,10   ! revised by Chris to prevent lower layers from being dried out
!    DO i=1,6
!   Fraction of SEVAP supplied by each soil layer
    if(ice(i) .gt. 0.01)exit
    SRDT(I)=EXP(-6.73*(DEPTH(I)-THKSL(I)/2.0)/100.0) !/1.987
!   SRDT(I)=AMAX1(0.0,SRDT(I)*(wcl(i)-wiltpt)) !*THKSL(I))
    Tsrdt=Tsrdt+SRDT(i)  ! to normalize SRDT(i)
!       if(i .gt. 6 .and. omegaL(i) .le. 0.3)exit
                  !Shuang edited based on Chris old edition
    enddo
!    print*,'before reassgning evap',evap
    do i=1,10
!       if(omegaL(i) .gt. 0.3)then        ! added by Chris to prevent deep layer evaporation when upper layer froze.
!        print*,'wsc before evap',i,wsc(i)
        if (Tsrdt .eq. 0.) then
            EVAPL(I)=0.
        else
        EVAPL(I)=Amax1(AMIN1(evap*SRDT(i)/Tsrdt,wsc(i)),0.0)  !mm
        DWCL(I)=EVAPL(I)/(THKSL(I)*10.0) !ratio
        wcl(i)=wcl(i)-DWCL(i)
        endif
!       else                              ! added by Chris to prevent deep layer evaporation when upper layer froze.
!          EVAPL(I) = 0.
!          DWCL(I)  = 0.
!       end if
!        print*,'dwcl',i,wcl(i),dwcl(i)
    enddo
    evap=0.0
    do i=1,10
        evap=evap+EVAPL(I)
    enddo

!   Redistribute transpiration according to root biomass
!   and available water in each layer
    tr_allo=0.0
    do i=1,nfr
        tr_ratio(i)=FRLEN(i)*wsc(i) !*(wcl(i)-wiltpt)) !*THKSL(I))
        tr_allo=tr_allo+tr_ratio(i)
    enddo
    do i=1,nfr
        if(tr_ratio(i) .gt. 0)then               !added by Chris
        plantup(i)=AMIN1(transp*tr_ratio(i)/tr_allo, wsc(i)) !mm
        else
           plantup(i)= 0.0
        wupl(i)=plantup(i)/(thksl(i)*10.0)
        wcl(i)=wcl(i)-wupl(i)
        end if
!        write (77,*) 'wupl(i))',wupl(i),'wcl(i)',wcl(i)
    enddo

!    write (*,*) 'wcl(1)',wcl(1),'wsc(1)',wsc(1),'wupl(1)',wupl(1),'liq_water(1)',liq_water(1), &
!    & 'DWCL(1)',DWCL(1),'omegaL(1)',omegaL(1),'exchangeL',exchangeL !dbmemo

!    write(81,801) wcl(1),wcl(2),wcl(3),wcl(4),wcl(5),WTADD,infilt,ddd,wupl(1),DWCL(1),exchangeL,rain_t,melt,rain_new,infilt_dbmemo
!801    format(15(f15.9,","))       ! dbmemo
    transp=0.0
    do i=1,nfr
        transp=transp+plantup(i)
    enddo
!    print*,'after reassgning transp',transp,liq_water(1:3),ice(1:3),infilt

!******************************************************
!   water table module starts here
!    vtot = MAX(145.,wsc(1)+wsc(2)+wsc(3)+infilt)!+wsc(4)+wsc(5)   !total amount of water in top 500mm of soil  mm3/mm2 infilt here is standing water   infilt has distributed to wsc?
    if (do_soilphy) then
!        vtot = wsc(1)+wsc(2)+wsc(3)+infilt+ice(1)*1000.*(10./9.)+ice(2)*1000.*(10./9.)+ice(3)*1000.*(10./9.)
!         vtot = wsc(1)+wsc(2)+wsc(3)+ice(1)*1000.*(10./9.)+ice(2)*1000.*(10./9.)+ice(3)*1000.*(10./9.)
        vtot = wsc(1)+wsc(2)+wsc(3)+infilt+wsc(4)+wsc(5)
!        vtot = (liq_water(1)+liq_water(2)+liq_water(3))*1000+(ice(1)+ice(2)+ice(3))*1000+infilt
!        vtot = wsc(1)+wsc(2)+wsc(3)+infilt+ice(1)*1000.*(9./10.)+ice(2)*1000.*(9./10.)+ice(3)*1000.*(9./10.)
!        write(*,*) ice(1)*1000.,ice(2)*1000.,ice(3)*1000.,wsc(1),liq_water(1)*1000.
    else
        vtot = wsc(1)+wsc(2)+wsc(3)+infilt+wsc(4)+wsc(5)
    endif

    !   infilt means standing water according to jiangjiang
!    vtot = MAX(145.,vtot+145.+rain-evap-transp-runoff)         ! vtot should not be smaller than 145, which is the water content when wt is at -300mm
    phi = 0.95   !soil porosity   mm3/mm3   the same unit with theta
    zmax = 500   !maximum water table depth   mm
    thetasmin = 0.25    !minimum volumetric water content at the soil surface   cm3/cm3
    zthetasmin = 100     !maximum depth where evaporation influences soil moisture   mm
    az = (phi-thetasmin)/zthetasmin     ! gradient in soil moisture resulting from evaporation at the soil surface    mm-1

    zwt1 = -sqrt(3.0*(phi*zmax-vtot)/(2.0*az))
    zwt2 = -(3.0*(phi*zmax-vtot)/(2.0*(phi-thetasmin)))
    zwt3 = vtot-phi*zmax
    if ((zwt1 .ge. -100) .and. (zwt1 .le. 0))   zwt = zwt1  !the non-linear part of the water table changing line
    if (zwt2 .lt. -100)                         zwt = zwt2  !the linear part of the water table changing line

!    if ((zwt2 .lt. -100) .and. (zwt2 .ge. -300))zwt = zwt2 !the linear part of the water table changing line valid when Vtot>145mm
!    if (zwt2 .le. -300)                         zwt = -300
    if (phi*zmax .lt. vtot)                     zwt = zwt3  !the linear part when the water table is above the soil surface
!    write (*,*) 'zwt',zwt,'zwt1',zwt1,'zwt2',zwt2,'zwt3',zwt3,'phi',phi,'zmax',zmax,'vtot',vtot,'az',az
!    write (*,*) 'vtot',vtot,'wsc(1))',wsc(1),'wsc(2)',wsc(2),'wsc(3)',wsc(3),'infilt',infilt
!    write (*,*) 'vtot',vtot,'liq_water(1)',liq_water(1)*1000,'liq_water(2)',liq_water(2)*1000,'liq_water(3)',liq_water(3)*1000, &
!    &   'ice(1)',ice(1)*1000,'ice(2)',ice(2)*1000,'ice(3)',ice(3)*1000,'infilt',infilt
!    if (do_soilphy) then
!        write(81,1810) WTADD,infilt,runoff,evap,transp,vtot,zwt,&!liq_water(1),liq_water(2),liq_water(3),liq_water(4),liq_water(5), &
!!        & liq_water(6),liq_water(7),liq_water(8),liq_water(9),liq_water(10), &
!!        & ice(1),ice(2),ice(3),ice(4),ice(5),ice(6),ice(7),ice(8),ice(9),ice(10), &
!        & wcl(1),wcl(2),wcl(3),wcl(4),wcl(5)!,wcl(6),wcl(7),wcl(8),wcl(9),wcl(10)
!    else
!    write(81,181)WTADD,infilt,runoff,evap,transp,vtot,zwt!,wsc(1),wsc(2),wsc(3),wsc(4),  &
!!        &        wsc(5),wsc(6),wsc(7),wsc(8),wsc(9),wsc(10),wcl(1),wcl(2),wcl(3),wcl(4),  &
!!        &        wcl(5),wcl(6),wcl(7),wcl(8),wcl(9),wcl(10)
!    endif
!181	format(27(f15.9,","))
!1810    format(37(f15.9,","))
!    write(*,*) 'zwt',zwt!,'evap',evap,'transp',transp,'vtot',vtot         !show on screen

!   water table module ends here
!******************************************************



!   Output fwsoil, omega, and topfws
! ..int commented lines below for soil thermal module
!
!    do i=1,nfr
!        ome(i)=(wcl(i)-WILTPT)/(FLDCAP-WILTPT)
!        ome(i)=AMIN1(1.0,AMAX1(0.0,ome(i)))
!        fw(i)=amin1(1.0,3.333*ome(i))
!    enddo
!    topfws=amin1(1.0,(wcl(1)-WILTPT)/((FLDCAP-WILTPT)))
!   ..int new lines added for soil thermal module
    do i=1,nfr
        if (do_soilphy) then
           ome(i)=(liq_water(i)*100./thksl(i)-WILTPT)/(FLDCAP-WILTPT)
           ome(i)=AMIN1(1.0,AMAX1(0.0,ome(i)))                 !!added by Chris
        else
           ome(i)=(wcl(i)-WILTPT)/(FLDCAP-WILTPT)
           ome(i)=AMIN1(1.0,AMAX1(0.0,ome(i)))
        endif
        fw(i)=amin1(1.0,3.333*ome(i))
    enddo

        if (do_soilphy) then
           topfws=amax1(0.0,topfws)
        else
           topfws=amin1(1.0,(wcl(1)-WILTPT)/((FLDCAP-WILTPT)))
        endif

    fwsoil=0.0
    omega=0.0
    do i=1,nfr
        fwsoil=fwsoil+fw(i)*frlen(i)
        omega=omega+ome(i)*frlen(i)
    enddo

!    write(81,181)WTADD,infilt,runoff,evap,transp,vtot,zwt,wsc(1),wsc(2),wsc(3),wsc(4),  &
!        &        wsc(5),wsc(6),wsc(7),wsc(8),wsc(9),wsc(10),wcl(1),wcl(2),wcl(3),wcl(4),  &
!        &        wcl(5),wcl(6),wcl(7),wcl(8),wcl(9),wcl(10)
!181	format(27(f15.9,","))

return
    end

!**********************************************************************
!     plant growth model
    subroutine plantgrowth(Tair,omega,GLmax,GRmax,GSmax,&
     &                       LAI,LAIMAX,LAIMIN,SLA,Tau_L,&
     &                       bmleaf,bmroot,bmstem,bmplant,&
     &                       Rootmax,Stemmax,SapS,SapR,&
     &                       StemSap,RootSap,Storage,GDD5,&
     &                       stor_use,onset,accumulation,gddonset,&
     &                       Sps,NSC,fnsc,NSCmin,NSCmax,&
     &                       NSN,CN,CN0,SNgrowth,N_deficit,&
     &                       store,add,L_fall,ht,&
     &                       NPP,alpha_L,alpha_W,alpha_R,&
     &                       RgLeaf,RgStem,RgRoot,Rgrowth,is_grass)
      implicit none
      real NSC,NSCmin,NSCmax,fnsc,N_deficit
      real CN(8),CN0(8),NSN,nsCN
      real SnscnL,SnscnS,SnscnR
      real store,Storage,GDD5,stor_use,accumulation,gddonset
      integer onset
      real GLmax,GRmax,GSmax,TauLeaf
      real GrowthP,GrowthL,GrowthR,GrowthS
      real Tair,omega,LAI,LAIMAX,LAIMIN,SLA
!     biomass
      real bmleaf,bmroot,bmstem,bmplant,NPP
      real ht,hmax,hl0,CNP0
      REAL LAIMAX0,la0,GPmax,acP,c1,c2
      real Rootmax,Stemmax,SapS,SapR
      real bmL,bmR,bmP,bmS,StemSap,RootSap
      real Rgrowth,Rgroot,Rgleaf,Rgstem
      real,save :: addaccu=0,GrowthLaccu=0,GrowthSaccu=0,GrowthRaccu=0
!     scalars
      real St,Sw,Ss,Sn,SL_rs,SR_rs,Slai,Sps,SNgrowth,phiN
      real RS,RS0,RSw
      real gamma_W,gamma_Wmax,gamma_T,gamma_Tmax,gamma_N
      real beta_T,Tcold,Twarm,Topt
      real bW,bT,W
      real L_fall,L_add,add,NL_fall,NL_add,Tau_L
      real alpha_L,alpha_W,alpha_R,alpha_St,aR,aL   ! aR aL added by Chris, internal scalers
      integer i
      logical is_grass

    Twarm=35.0
    Tcold=5.0
!    Tcold=0.0       ! For SPRUCE
    Topt=30.
    phiN=0.33

    bmL=bmleaf*0.48   ! Carbon
    bmR=bmRoot*0.48
    bmS=bmStem*0.48

    if(bmL.lt.NSC/0.333)bmL=NSC/0.333
    if(.not. is_grass)then   ! added by Chris
       if(bmS.lt.NSC/0.334)bmS=NSC/0.334
    end if
    if(bmR.lt.NSC/0.333)bmR=NSC/0.333
!    if(bmS.lt.NSC/0.334)bmS=NSC/0.334
    StemSap=SapS*bmS  ! Weng 12/05/2008
    RootSap=SapR*bmR
    if(StemSap.lt.0.001)StemSap=0.001
    if(RootSap.lt.0.001)RootSap=0.001

    bmP=bmL+bmR+bmS					! Plant C biomass
    acP=bmL+StemSap+bmS					! Plant available sapwood C
    CNp0=bmP/(bmL/CN0(1)+bmR/CN0(3)+bmS/CN0(2))		! Plant CN ratio

    if(.not. is_grass)then   ! added by Chris
       hmax=24.19  ! m
    hl0=0.00019  ! m2/kg C
    LAIMAX0=8.
    la0=0.2
       ht=hmax*(1.-exp(-hl0*bmP))                             ! Scaling plant C biomass to height
       LAIMAX=AMAX1(LAIMAX0*(1.-exp(-la0*ht)),LAIMIN+0.1)  ! Scaling plant height to maximum LAI
    else
        hmax=24.19   ! m
        hl0=0.00019  ! m2/kg C
        LAIMAX0=6.
        la0=0.2
    ht=hmax*(1.-exp(-hl0*bmP))				! Scaling plant C biomass to height
    LAIMAX=AMAX1(LAIMAX0*(1.-exp(-la0*ht)),LAIMIN+0.1)  ! Scaling plant height to maximum LAI
    end if

!   Phenology
    if((GDD5.gt.gddonset).and.onset.eq.0.and.storage.gt.stor_use) then
        onset=1
    endif
    if((onset.eq.1).and.(storage.gt.stor_use))then
!        write (*,*) LAI, LAIMAX, stor_use              ! LAI revisit
        if(LAI.lt.LAIMAX)add=stor_use
!              if(LAI.lt.LAIMAX)add=stor_use/20.0
        storage=storage-add
    else
        add=0.0
        onset=0
    endif
!    if(accumulation.lt.(NSCmax+0.005*RootSap))then                       !original
    if(accumulation.lt.(NSCmax+0.005*RootSap) .and. NSC .gt. NSCmin)then  !revised by Chris to prevent NSC decrease under NSCmin
        store=AMAX1(0.,0.005*NSC)			! 0.5% of nonstructure carbon is stored
    else
        store=0.0
    endif
    accumulation=accumulation+store

!   Scalars for plant growth
!      Sps=Amin1(1.0,3.33*AMAX1(0.0,1.0 - fnsc))
      Sps=Sps*(1.-exp(-phiN*NSN))	! Sps is not assigned previous, something is wrong. -JJJJJJJJJJJJJJJJJJJJJ
      Ss=AMIN1(1.0,2.*fnsc)
      RS0=1.0
      RS=bmR/bmL
      SL_rs=RS/(RS+RS0*(2.-W))
      SR_rs=(RS0*(2.-W))/(RS+RS0*(2.-W))
      Slai=amin1(1.0,2.333*(LAIMAX-LAI)/(LAIMAX-LAIMIN))
      St=AMAX1(0.0, 1.0-exp(-(Tair-gddonset/10.)/5.0))  !0.5 !
!      Sw=AMAX1(0.333, 0.333+omega)
      Sw=AMIN1(0.5, AMAX1(0.333, 0.333+omega))
      W = AMIN1(1.0,3.333*omega)

!     Plant growth and allocation, based on LM3V
      GPmax=(GLmax*bmL+GSmax*StemSap+GRmax*bmR) !/acP
      GrowthP=AMIN1(GPmax*fnsc*St*(1.-exp(-NSN)),  & !
     &              0.004*NSC,&
     &              0.004*NSN*CNp0)

!      c1=(bmR+200.)/bmL*CN(1)/CN0(1) !+N_deficit/NSN
!      c1=bmL/bmR*CN(1)/CN0(1) !+N_deficit/NSN
!      c2=0.5*250e3*SLA*0.00021*ht*2.
      !write(*,*)LAI
      !GrowthL=MAX(0.0,MIN(GrowthP*0.5,0.05*(LAIMAX-LAI)/SLA))    ! 1./(1.+c1+c2)
!      GrowthL=MAX(0.0,GrowthP*0.43)
      GrowthL=MAX(0.0,GrowthP*0.5)      ! updated when QC leaf and wood changed due to the change of plot area for tree biomass
      GrowthR=MIN(GrowthP*0.4,MAX(0.0,0.75/Sw*bmL-bmR))  ! *c1/(1.+c1+c2)
!        GrowthR=MIN(GrowthP*0.35,MAX(0.0,0.75/Sw*bmL-bmR))  ! *c1/(1.+c1+c2)
      if(.not. is_grass)then   ! added by Chris
      GrowthS=MAX(0.0,GrowthP - (GrowthL+GrowthR) )         ! *c2/(1.+c1+c2)
        if(LAI .gt. LAIMAX .and. GrowthR+GrowthS .ne. 0)then ! added by Mary Chris, stop growing leaves if LAI>LAIMAX
         GrowthR=GrowthR/(GrowthR+GrowthS)*(GrowthL+GrowthR+GrowthS)
         GrowthS=GrowthS/(GrowthR+GrowthS)*(GrowthL+GrowthR+GrowthS)
         GrowthL=0
     endif
      else
         if(GrowthR .ne. 0 .or. GrowthL .ne. 0)then
            aR=GrowthR/(GrowthR+GrowthL)
            aL=GrowthL/(GrowthR+GrowthL)
            GrowthR=aR*GrowthP
            GrowthL=aL*GrowthP
         end if
         GrowthS = 0.0
      end if


      NPP = GrowthL + GrowthR + GrowthS + add       ! Modified by Jiang Jiang 2015/10/13
!      write (*,*) "add", add                       ! LAI revisit
      addaccu=addaccu+add
      GrowthLaccu=GrowthLaccu+GrowthL
      GrowthRaccu=GrowthRaccu+GrowthR
      GrowthSaccu=GrowthSaccu+GrowthS
!      print*,'add',addaccu,GrowthLaccu,GrowthRaccu,GrowthSaccu
      if(NPP.eq.0.0)then
         if(.not. is_grass)then   ! added by Chris
            alpha_L=0.333
            alpha_W=0.333
            alpha_R=0.333
      else
            alpha_L=0.5
            alpha_W=0.0
            alpha_R=0.5
         end if
      else
            alpha_L=(GrowthL+add)/NPP
            alpha_W=GrowthS/NPP
            alpha_R=GrowthR/NPP
      endif
!      write (*,*) 'GrowthL',GrowthL, 'GrowthR',GrowthR, 'GrowthS',GrowthS,'GrowthP',GrowthP,'add',add
!     Carbon cost for growth
!     Rgrowth,Rgroot,Rgleaf,Rgstem, 0.5 is from IBIS and Amthor, 1984
      Rgleaf=0.5*GrowthL
      Rgstem=0.5*GrowthS
      Rgroot=0.5*GrowthR
      Rgrowth=Rgleaf+Rgstem+Rgroot

!     Leaf litter

      gamma_Wmax=0.12/24. ! maxmum leaf fall rate per hour
      gamma_Tmax=0.12/24.

      bW=4.0
      bT=2.0

      if(Tair.gt.(Tcold+10.)) then
            beta_T=1.
      else
            if(Tair.gt.Tcold)beta_T=(Tair-Tcold)/10.
            if(Tair.LE.Tcold)beta_T=0.0
      endif

      if (tau_L < 8760.)then
                gamma_W=(1. - W)     **bW  * gamma_Wmax
                gamma_T=(1. - beta_T)**bT * gamma_Tmax
      else
                gamma_W=0.
                gamma_T=0.
      endif
      gamma_N=1.0/Tau_L*Sw      ! Modify by Jiang Jiang 2015/10/20
!      print*,'gamma_N',Tau_L,Sw
      if(LAI < LAIMIN) then
            gamma_W=0.
            gamma_T=0.
            gamma_N=0.
      endif
    !  L_fall=bmleaf*0.48*AMIN1((gamma_T+gamma_N),0.99)
!      print*,'L_fall',bmleaf,gamma_N
      L_fall=bmleaf*0.48*gamma_N

      return
      end

!************************************************************************
!     carbon transfer according to Xu et al. 2007
      subroutine TCS_CN(Tair,Tsoil,omega,runoff,&
     &               NPP,GPP,alpha_L,alpha_W,alpha_R,L_fall,&
     &               tauC,QC,OutC,Rh_pools,Rnitrogen,NSC,  &
     &               CNmin,CNmax,NSNmax,NSNmin,alphaN,     &        ! nitrogen
     &               NSN,N_uptake,N_miner,QN,QNminer,TD,   &
     &               CN,CN0,fnsc,rdepth,N_deficit,N_immob, &
     &               N_leaf,N_wood,N_root,N_LF,N_WF,N_RF,  &
     &               N_deposit,N_fixation,N_leach,N_vol,   &
     &               SNvcmax,SNgrowth,SNRauto,SNrs,Q10rh,  &
     &               tsoill,testout,do_soilphy,is_grass,   &
	 & etaL,etaW,etaR,f_F2M,f_C2M,f_C2S,f_M2S,f_M2P,f_S2P,f_S2M,f_P2M)

      implicit none
      real NPP,NPP_L,NPP_W,NPP_R,GPP
      real L_fall,L_add,LAI,SLA,rdepth
      real Tair,Tsoil,omega,runoff,obs_soilprofc(150)
!     allocation ratios
      real alpha_L,alpha_W,alpha_R
!     pools
      real Q_plant,QC(8),TauC(8),OutC(8)
      real etaL,etaW,etaR                ! the percentage of fine litter of the litters from plant parts
      real f_F2M,f_C2M,f_C2S,f_M2S,f_M2P,f_S2P,f_S2M,f_P2M
      real Rh_pools(5),Q10h(5),Q10rh ! Q10 of the litter and soil C pools
!     the fraction of C-flux which enters the atmosphere from the kth pool
      real f_CO2_fine,f_CO2_coarse,f_CO2_Micr,f_CO2_Slow,f_CO2_Pass
!     for nitrogen sub-model
      real CN0(8),CN(8),OutN(8),QN(8),QNminer,QNplant,TD
      real CNmin,CNmax,NSNmax,NSNmin,NSN
      real CN_plant,CN_foliage
      real N_demand,N_deficit,N_immob,N_imm(5),N_fixation,Nfix0
      real N_transfer,N_miner,N_uptake,N_deposit,N_loss,N_leach,N_vol
      real alphaN,Qroot0,Cfix0
      real Scalar_N_flow,Scalar_N_T
      real N_leaf,N_wood,N_root
      real N_LF,N_WF,N_RF
      real NSC,fnsc,ksye
      real SNvcmax,SNgrowth,SNRauto,SNrs
      real kappaVcmax
      real SNfine,SNcoarse,SNmicr,SNslow,SNpass
      real Rnitrogen,costCuptake,costCfix,costCreuse
      real Creuse0,Nup0,N_deN0,LDON0
!     the variables relative to soil moisture calcualtion
      real S_omega    !  average values of the moisture scaling functions
      real S_t(5)     !  average values of temperature scaling functions
      real S_w_min    !  minimum decomposition rate at zero available water
!     For test
      real totalC1,totalN1,C_in,C_out,N_in,N_out,totalC2,totalN2
      real ScNloss

      integer i,j,k,n,m
      integer day,week,month,year

!  *** ..int
!  added for soil thermal
      real tsoill(10),frac_soc(10),testout(11),tsoil_layer(11)
      logical do_soilphy
      logical is_grass

      tsoil_layer = testout
!      frac_soc=(/0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1/)          !tuneice
      frac_soc=(/0.75,0.2,0.02,0.015,0.005,0.0,0.0,0.0,0.0,0.0/)
!     temperature sensitivity of Rh_pools
!      Q10h=(/2.0,2.0,2.0,2.0,2.0/)  ! for Oak Ridge
      Q10h=(/Q10rh,Q10rh,Q10rh,Q10rh,Q10rh/)
!
      Qroot0=500.
      Nfix0=1./60.   ! maximum N fix ratio, N/C
      Nup0 =0.02     ! nitrogen uptake rate
      Cfix0=12.      ! C cost per N for fixation
      ksye=0.05      ! C cost per N for uptake
      Creuse0=2.     ! C cost per N for resorption
      ScNloss=1.
      N_deN0=1.E-3*ScNloss   ! 1.E-3, 5.E-3, 10.E-3, 20.E-3
      LDON0=1.E-3*ScNloss

      Rnitrogen=0.
!     for N scalars
      CNmin=40.0
      CNmax=200.0
!     Max and min NSN pool
      NSNmax = QN(1) + 0.2*QN(2) + QN(3)  ! 15.0
      if (is_grass) then
          NSNmin = 1        !CiPEHR grassland value
      else
          NSNmin = 0.01     !SPRUCE forest value
      endif
  !  ! partitioning coefficients
      ! etaL=0.6          ! 60% of foliage litter is fine, didn't use
      ! etaW=0.15        ! 15% of woody litter is fine
      ! etaR=0.85         ! 85% of root litter is fine  , didn't use
      ! f_F2M=0.55        ! *exp((CN0(4)-CN_fine)*0.1)
      ! f_C2M=0.275       ! *exp((CN0(5)-CN_coarse)*0.1)
      ! f_C2S=0.275       ! *exp((CN0(5)-CN_coarse)*0.1)
      ! f_M2S=0.3
      ! f_M2P=0.1
      ! f_S2P=0.2        !0.03 Change by Jiang Jiang 10/10/2015
      ! f_S2M=0.5
      ! f_P2M=0.45

!     calculating soil scaling factors, S_omega and S_temperature
      S_w_min=0.08 !minimum decomposition rate at zero soil moisture
      S_omega=S_w_min + (1.-S_w_min) * Amin1(1.0, 0.3*omega)

      S_t=(/0.,0.,0.,0.,0./)
!  *** ..int
!  ***commented for CWE

!      do i=1,5
!!        S_t(i)=Q10h(i)**((Tsoil-5.)/10.)  ! Oak
!         S_t(i)=Q10h(i)**((Tsoil-10.)/10.)  ! Duke
!      enddo
!  ***
      if (do_soilphy) then

          do i=1,5
             if(i.lt.3) then    ! couarse and fine litter use surface layer soil temperature
!               S_t(i)=Q10h(i)**((Tsoil-5.)/10.)  ! Oak
                S_t(i)=Q10h(i)**((tsoil_layer(2)-10.)/10.)  ! Duke
             else
                do j=1,10       ! fast,slow and passive pool use weighed soil temperature in layers according to soc distribution
                    S_t(i)=S_t(i)+frac_soc(j)*Q10h(i)**((tsoil_layer(j+1)-10.)/10.)  ! Duke
                enddo
             endif
          enddo
      else
          do i=1,5
!            S_t(i)=Q10h(i)**((Tsoil-5.)/10.)  ! Oak
             S_t(i)=Q10h(i)**((Tsoil-10.)/10.)  ! Duke
          enddo
      endif


!     Calculating NPP allocation and changes of each C pool
      NPP_L = alpha_L * NPP           ! NPP allocation
      NPP_W = alpha_W * NPP
      NPP_R = alpha_R * NPP
!     N scalars on decomposition
      SNfine  =exp(-(CN0(4)-CN(4))/CN0(4))
      SNcoarse=exp(-(CN0(5)-CN(5))/CN0(5))
      SNmicr  =exp(-(CN0(6)-CN(6))/CN0(6))
      SNslow  =1. !exp(-(CN0(7)-CNC(7))/CN0(7))
      SNpass  =exp(-(CN0(8)-CN(8))/CN0(8))

!     the carbon leaving the pools
      OutC(1)=L_fall
      OutC(2)=QC(2)/tauC(2)*S_omega !*exp(CN(2)/CN0(2)-1.)
      OutC(3)=QC(3)/tauC(3)*S_omega

      OutC(4)=QC(4)/tauC(4)*S_omega* S_T(1)*CN(4)/CN0(4)!*SNfine
      OutC(5)=QC(5)/tauC(5)*S_omega* S_T(2)*CN(5)/CN0(5)!*SNcoarse
      OutC(6)=QC(6)/tauC(6)*S_omega* S_T(3)!*SNmicr
      OutC(7)=QC(7)/tauC(7)*S_omega* S_T(4)!*SNslow
      OutC(8)=QC(8)/tauC(8)*S_omega* S_T(5)!*SNpass

!     heterotrophic respiration from each pool
      Rh_pools(1)=OutC(4)* (1. - f_F2M)
      Rh_pools(2)=OutC(5)* (1. - f_C2M - f_C2S)
      Rh_pools(3)=OutC(6)* (1. - f_M2S - f_M2P)
      Rh_pools(4)=OutC(7)* (1. - f_S2P - f_S2M)
      Rh_pools(5)=OutC(8)* (1. - f_P2M)

!========================================================================
!     Nitrogen part
!     nitrogen leaving the pools and resorption
      do i=1,8
         if(CN(i) .ne. 0)then  !edited by Chris avoid /zero
         OutN(i) = OutC(i)/CN(i)
         else
            OutN(i) = 0.0
         end if
      enddo


!     nitrogen mineralization
      N_miner=OutN(4)* (1. - f_F2M)  &
     &       +OutN(5)* (1. - f_C2M - f_C2S) &
     &       +OutN(6)* (1. - f_M2S - f_M2P) &
     &       +OutN(7)* (1. - f_S2P - f_S2M) &
     &       +OutN(8)* (1. - f_P2M)


!     Nitrogen immobilization   !Chris added QNminer_active to account for thaw depth in permafrost ecosystems
      N_imm=0.
      N_immob=0.
      if(QNminer>0)then
          do i=4,8
            if(CN(i)>CN0(i))then
                N_imm(i-3)=Amin1(QC(i)/CN0(i)-QC(i)/CN(i)  &
     &             ,0.1*QNminer)
                N_immob=N_immob+N_imm(i-3)
            endif
          enddo
      endif

!     Let plant itself choose the strategy between using C to uptake
!     or fix N2 by comparing C invest.
!     N demand
      N_demand=NPP_L/CN0(1)+NPP_W/CN0(2)+NPP_R/CN0(3) !+N_deficit
!     Nitrogen input:
      N_transfer=0.
	N_uptake=0.
	N_fixation=0.
      costCuptake=0.
      costCfix=0.
      costCreuse=0.
!     1. Nitrogen resorption
      N_transfer=(OutN(1) + OutN(2) +OutN(3))*alphaN
      costCreuse= Creuse0*N_transfer
      N_demand=N_demand-N_transfer

      If(N_demand>0.0)then

!     2.  N uptake
          if(ksye/QNminer<Cfix0)then
              N_uptake=AMIN1(N_demand+N_deficit,      &
     &                       QNminer*QC(3)/(QC(3)+Qroot0), &
     &                       Nup0*NSC/(ksye/QNminer))
              costCuptake=N_uptake*(ksye/QNminer)
              N_demand=N_demand-N_uptake
          elseif(NSN<24.*30.*N_demand)then
!     3.  Nitrogen fixation
              N_fixation=Amin1(N_demand,fnsc*Nfix0*NSC)
              costCfix=Cfix0*N_fixation
              N_demand=N_demand-N_fixation
          endif
      endif
      N_deficit=N_deficit+N_demand
!      print*,'N_deficit,QC1',NPP,N_deficit,N_demand,N_uptake,N_fixation,QNminer_active,QNminer
      if(.not. is_grass)then       !added by Chris to regulate NPP when N is limited
         NPP = NPP - N_deficit / (alpha_L/CN(1) + alpha_W/CN(2) + alpha_R/CN(3))
         GPP = GPP - N_deficit / (alpha_L/CN(1) + alpha_W/CN(2) + alpha_R/CN(3))
      else
         NPP = NPP - N_deficit / (alpha_L/CN(1) + alpha_R/CN(3))
         GPP = GPP - N_deficit / (alpha_L/CN(1) + alpha_R/CN(3))
      end if
!      print*,'QC1,NPP',NPP,N_deficit , alpha_L,CN(1) , alpha_R,CN(3)
      NPP_L = alpha_L * NPP           ! NPP allocation
      NPP_W = alpha_W * NPP
      NPP_R = alpha_R * NPP
      N_deficit = 0
!     update NSN
      NSN=NSN+N_transfer+N_uptake+N_fixation
!     Total C cost for nitrogen
      Rnitrogen=costCuptake+costCfix+costCreuse

!      Oak Ridge N fixation rate:
!      asymbiotic: 2 mg N/m2/yr ;  symbiotic: 65 mg/m2/yr, Oak Ridge
!      N_fixation=0.067/8760. ! Oak Ridge
!      N_fixation=0.23/8760.  ! Duke

!     Nitrogen using, non-structural nitrogen pool, NSN
!      N_leaf =AMIN1(NPP*alpha_L/CN(1)+QC(1)/CN0(1)-QC(1)/CN(1),0.2*NSN)
      N_leaf =AMAX1(AMIN1(NPP*alpha_L/CN(1)+QC(1)/CN0(1)-QC(1)/CN(1),0.2*NSN),0.0) !revised by Chris to avoid negative N_Leaf
      if(.not. is_grass)then
!         N_wood =AMIN1(NPP*alpha_W/CN(2)                         ,0.1*NSN)
         N_wood =AMAX1(AMIN1(NPP*alpha_W/CN(2)                      ,0.1*NSN),0.0) ! revised by Chris to avoid negatiive N_wood
      else
         N_wood = 0
      end if
!      N_root =AMIN1(NPP*alpha_R/CN(3)+QC(3)/CN0(3)-QC(3)/CN(3),0.2*NSN)
      N_root =AMAX1(AMIN1(NPP*alpha_R/CN(3)+QC(3)/CN0(3)-QC(3)/CN(3),0.2*NSN),0.0) ! revised by Chris to avoid negatiive N_root

!      N_leaf =AMAX1(AMIN1(NPP*alpha_L/CN(1)+QC(1)/CN0(1)-QC(1)/CN(1),0.05*(NSN-NSNmin)),0.) !revised by Crhis on Sep. 3rd
!      if(.not. is_grass)then
!         N_wood =AMAX1(AMIN1(NPP*alpha_W/CN(2)   ,0.1*NSN),0.)
!      else
!         N_wood = 0
!      end if
!      N_root =AMAX1(AMIN1(NPP*alpha_R/CN(3)+QC(3)/CN0(3)-QC(3)/CN(3),0.05*(NSN-NSNmin)),0.)
      NSN=NSN-(N_leaf+N_wood+N_root)

      N_LF=OutN(1)*(1.-alphaN)
      N_WF=OutN(2)*(1.-alphaN)
      N_RF=OutN(3)*(1.-alphaN)

!     update QNminer
      QNminer=QNminer+N_miner+N_deposit  &
     &              -(N_uptake+N_immob)


!     Loss of mineralized N and dissolved organic N
      Scalar_N_flow=0.5*runoff/rdepth
!      Scalar_N_T=0.005*(Tsoil+273.)/(Tsoil+273+333.)

!   *** .int
!*****************
!   commented line for soil thermal
!      Scalar_N_T=N_deN0*exp((Tsoil-25.)/10.)
!   added lines for soil thermal
      if (do_soilphy) then
          Scalar_N_T = 0.0
          do j=1,10
              Scalar_N_T = Scalar_N_T + frac_soc(j)*N_deN0*exp((tsoil_layer(j+1)-25.)/10.)
          enddo
      else
          Scalar_N_T=N_deN0*exp((Tsoil-25.)/10.)
      endif
!******************
!   ***
      N_leach=Scalar_N_flow*QNminer+Scalar_N_flow*QN(6)*LDON0
      N_vol  =Scalar_N_T*QNminer
      N_loss =N_leach + N_vol

!     update QNminer
      QNminer=QNminer-N_loss
!      QNminer_active=QNminer_active-N_loss


!     update plant carbon pools, ! daily change of each pool size
      !print*,'sasu check1',OutC(1),NPP_L,QC(1)
!      print*,'QC1',QC(1),OutC(1),NPP_L
      QC(1)=QC(1) - OutC(1) + NPP_L
      QC(2)=QC(2) - OutC(2) + NPP_W
      QC(3)=QC(3) - OutC(3) + NPP_R
      QC(4)=QC(4) - OutC(4) + OutC(1)+etaW*OutC(2)+OutC(3)
      QC(5)=QC(5) - OutC(5) + (1.-etaW)*OutC(2)
      QC(6)=QC(6) - OutC(6) + f_F2M*OutC(4)+f_C2M*OutC(5)     &
     &                      + f_S2M*OutC(7)+f_P2M * OutC(8)
      QC(7)=QC(7) - OutC(7)+f_C2S*OutC(5)+f_M2S*OutC(6)
      QC(8)=QC(8) - OutC(8)+f_M2P*OutC(6)+f_S2P*OutC(7)
!print*,'QC1',QC(1),OutC(1),NPP_L
      Q_plant =QC(1) + QC(2) + QC(3)
!     update nitrogen pools
      QN(1)=QN(1) - OutN(1) + N_leaf
      QN(2)=QN(2) - OutN(2) + N_wood
      QN(3)=QN(3) - OutN(3) + N_root
      QN(4)=QN(4) - OutN(4)+ N_imm(1)     &
     &            + (OutN(1) + etaW*OutN(2) + OutN(3))*(1.-alphaN)
      QN(5)=QN(5) - OutN(5) + N_imm(2)   &
     &            + (1.-etaW)*OutN(2)*(1.-alphaN)

      QN(6)=QN(6) - OutN(6) + N_imm(3) - Scalar_N_flow*QN(6)*LDON0  &
     &            + f_F2M*OutN(4)+f_C2M*OutN(5)  &
     &            + f_S2M*OutN(7)+f_P2M*OutN(8)
      QN(7)= QN(7) - OutN(7) + N_imm(4)  &
     &                         + f_C2S*OutN(5) &
     &                         + f_M2S*OutN(6)
      QN(8)= QN(8) - OutN(8) + N_imm(5) &
     &         + f_M2P*OutN(6) + f_S2P*OutN(7)
      QNplant = QN(1) + QN(2)+ QN(3)

!     update C/N ratio
      where(QN .lt. 1.e-30)         ! added by Chris
        QN = 1.e-30                 !
      endwhere                      !
      where(QC .lt. 1.e-30)         !
        QC = 1.e-30                 !
      endwhere                      !
      CN=QC/QN
      CN_foliage=(QC(1)+QC(3))/(QN(1)+QN(3))
!     calculate N related scalars for Oak Ridge
!      SNvcmax =exp(-(CN(1)-CN0(1))) ! /CN0(1) ! Oak Ridge
!      SNgrowth=exp(-(CN(1)-CN0(1))/CN0(1)) !  AMAX1((CNmax-CN_foliage)/(CNmax-CNmin),0.0)+0.25
!      SNRauto =AMAX1((CNmax-CN_foliage)/(CNmax-CNmin),0.0)+0.5
!      SNrs=1.

!     calculate N related scalars for Duke FACE
      kappaVcmax=CN0(1)/1.
      SNvcmax =exp(-kappaVcmax*(CN(1)-CN0(1))/CN0(1)) ! /CN0(1) ! Duke
      SNvcmax =AMAX1(AMIN1(SNvcmax,1.),0.)   ! added by Chris
      SNgrowth=exp(-(CN(1)-CN0(1))/CN0(1)) !  AMAX1((CNmax-CN_foliage)/(CNmax-CNmin),0.0)+0.25
      SNRauto =exp(-(CN(1)-CN0(1))/CN0(1)) !  AMAX1((CNmax-CN_foliage)/(CNmax-CNmin),0.0)+0.5
      SNrs=1.

      return
      end

!   *** int
!      ************************************************************************************************
!      *****************************   subroutines from methane and soil thermal modules **************
!      ************************************************************************************************
      subroutine snow_d(rain_d,lat,days,ta,snow_dsim,fa,fsub,rho_snow,melt,dcount,decay_m)
       real lat,tr,daylength,dec,melt,fa,sublim,dsnow,snow_in,decay_m,fsub
       real rain_d,snow_dsim,rho_snow,dcount,ta
       integer days
       real snow_dsim_pre

!       rho_snow =100.
!       fa=0.1
!       fsub=0.1
       tr=0.0174532925

       dec=sin(((real(days)-70.)/365.)*360.*tr)*23.44
       daylength=acos(-tan(lat*tr)*tan(dec*tr))/7.5
       daylength=daylength/tr/24.

       if (snow_dsim .ge. 0.) then
           dcount = dcount +1.
       else
           dcount =0.
       endif

       sublim=0.
       if (ta .gt. 0. .and. snow_dsim .gt. 0.) sublim=fsub*715.5*daylength*esat(ta)/(ta+273.2)*0.001   ! 0.001 from Pa to kPa
       !if (sublim .lt. 0.1) sublim=0.
       !sublim=0.
       !sublim=AMIN1(sublim,0.2)
       !melt=fa*(2.63+2.55*ta+0.0912*ta*rain_d)

       !if (snow_dsim .gt. 0.7) sublim = 10.
       melt=0.
!       if (ta .gt. 0. .and. snow_dsim .gt. 0.) melt=fa*(2.63+2.55*ta+0.0912*ta*rain_d)       !yy version
       if (ta .gt. 1.0e-10 .and. snow_dsim .gt. 0.) melt=fa*(2.63+2.55*ta+0.0912*ta*rain_d)   !dbmemo updated version
!       write(*,*) 'melt=fa*(2.63+2.55*ta+0.0912*ta*rain_d)','fa',fa,'ta',ta,'rain_d',rain_d
       !if (ta .gt. 0. .and. snow_dsim .gt. 0.) melt=fa*(0.55*ta)

       if (dcount .gt.0. .and. ta .lt.5.) then
!           write(*,*)'melt_befor',melt         !dbmemo dbice
           melt=melt*EXP(-decay_m*dcount/365.)  !dbmemo dbice
!           write(*,*)'melt_after',melt
       endif

       !write(*,*)EXP(-3.*dcount/365.)

       !melt=AMIN1(melt, snow_dsim*rho_snow-sublim)
       !if (melt .lt. 2.) melt=0.
       if (ta .le. 0.) then         ! dbmemo second bug in dbmemo
           snow_in =rain_d
       else
           snow_in = 0.
       endif

       dsnow=snow_in-sublim-melt
       snow_dsim_pre = snow_dsim
       snow_dsim =snow_dsim + dsnow/rho_snow

       if (snow_dsim .le. 0.0) then
          snow_dsim=0.0
          melt = snow_dsim_pre*rho_snow +snow_in-sublim    !! for water part
       endif
       melt=AMAX1(melt, 0.)

 !      write(*,*)'snow_dsim',snow_dsim
!       write(*,*)'snow_dsim',snow_dsim
      ! write(*,*)'doy',pi

!       write (*,*) 'melt',melt,'snow_dsim_pre',snow_dsim_pre,'snow_in',snow_in,'ta',ta,'rain_d',rain_d, &        ! dbmemo
!       &  'sublim',sublim,'decay_m',decay_m,'dcount',dcount,'fa',fa  ! dbmemo
!       write (*,*) 'variables for sublim',sublim,'fsub',fsub,'daylength',daylength,'snow_dsim',snow_dsim   ! dbmemo



!       write(89,189) melt,snow_dsim,snow_in,ta
!189    format(4(f11.4,","))

    return
    end

!    !    ========================================================================================
      subroutine Tsoil_simu(Rsoilab1,Rsoilab2,QLleaf,QLair,Tair,Dair,&
&         fbeam,FLAIT,sigma,emsoil,rhoS,Rconst,&
&         extkd,extkb,cpair,Patm,AirMa,H2OMw,&
&         H2OLv0,wcl,raero,wsmax,wsmin,wind,sftmp,Tsoill,testout,ht,ice,&
&         snow_depth,Tsnow,Twater,Tice,water_tw,ice_tw,diff_s,G,tsoil,&
&         diff_snow,albedo_snow,resht,thd_snow_depth,thksl,zwt,Esoil,Hsoil,liq_water,&
&         shcap_snow,condu_snow,condu_b,depth_ex,dcount_soil,input_tsoil)
      implicit none
      integer i
      real tsoil
      real Rsoilab1,Rsoilab2,qlleaf,qlair,tair,Dair,fbeam,flait,sigma,emsoil
      real rhoS(3),rconst,extkd,extkb,cpair,patm,airma,h2omw,h2olv0,raero,wsmax,wsmin
      real esoil,G,hsoil,wind,ht,esat,theta_sat_min,Rsoilabs,Rsoil,difsv2,difsv1
      real delta
      !real thksl(10)
      real TairK,H2OLv
      real ice(10)
      real wcl(10),thksl(10),ufw(10),frac_ice1,frac_ice2
      real,dimension(10):: Tsoill,liq_water
      real,dimension(11):: testout
      real,dimension(11):: input_tsoil
      real WILTPT,FILDCP,temph1,temph2
      real sftmp,hitmax,rflen,zopnd,thkns1,thkns2
      real Twater, flux_water,Tsnow,flux_snow,Tice
      real condu_water,shcap_water,shcap_ice,shcap_snow,condu_snow,depth_ex
      real albedo_snow, albedo_water,ice_incr,heat_excess,heat_adjust,ice_tw,water_tw
      real inter_var,latent_heat_fusion,QLsoil,Rsoilab3
      real rhocp,slope,psyc,Cmolar,fw1,resoil,rLAI,resht,resdh,dnr,dsh,dgh,dle,drsdh
      real f_om,theta_sat_om,b_om,b_min,phi_om,phi_min,theta_sat,b_tot,phi_sat,gravi
      real water_table_depth,snow_depth,temph_water,temph_snow
      real condu_air,shcap_air,condu(10), shcap(10), condu_ice,tsoill_pre, thd_t
      real ice_density,condu_soil,shcap_soil
      real thd_snow_depth,resht_lai,zwt,snow_depth_t
      real diff_s, diff_snow,condu_s,tsoill_0,diff_air,d_cor,condu_b,dcount,dcount_soil
      real sftmp_pre
      integer n_layers

      real, allocatable ::depth_z(:)
      n_layers=10
      allocate(depth_z(n_layers))

      tsoill_0=input_tsoil(1)
      tsoill(1:10)=input_tsoil(2:11)
      !write(*,*)thd_t
      ! soil thermal conductivity W m-2 K-1
      ice_density=916.!916.
!      thkns1=thksl(1)/2.
      thkns1=thksl(1)/4.
      shcap_ice=2117.27*ice_density
      condu_ice=2.29
      condu_water=0.56!0.56
      shcap_water=4188000.
      condu_soil=0.25
      shcap_soil=2600000.
      condu_s=0.25
!      thd_t=0.0
      thd_t=-1.0

      diff_snow=3600.*condu_snow/shcap_snow*10000.
      diff_s=3600.*condu_b/shcap_soil*10000.

      latent_heat_fusion = 333700.   ! j kg-1
      condu_air=0.023
      shcap_air=1255.8

      diff_air=3600.*condu_air/shcap_air*10000.

      water_tw=zwt*0.001-ice_tw ! might means total water that is liquid, add up all layers
      water_table_depth=zwt*0.1

      snow_depth_t = snow_depth - 0.46*0.0     ! warming in Tair impact on snow_depth
                                               ! in unit cm 0.46 based on snow_depth vs. tair regression
      if (snow_depth_t .lt. thd_snow_depth) snow_depth_t =0.0

       if (snow_depth_t .gt. 0.) then
           dcount_soil = dcount_soil +1./24.
       else
           dcount_soil =0.
       endif

      if (water_table_depth .lt. 4. .and. water_table_depth .gt. 0.0) water_table_depth =0.    ! avoid numerical issues when
!      if (water_table_depth .lt. -99.) water_table_depth =-30.    ! temporary for NaN
!      if (water_table_depth .lt. -299.) water_table_depth =-30.    ! -299 is a more reasonable value Shuang Ma
      albedo_water =0.1
      ! soil water conditions
      WILTPT=wsmin/100.
      FILDCP=wsmax/100.
      TairK=Tair+273.2

      flux_snow = 0.0

      depth_z=(/0., 0., 0., 0., 0., 0., 0.,0.,0.,0./)
!      ..int add unfrozen water ratio
!      ufw=(/0.0042,0.0063,0.0063,0.0063,0.0063,0.0063,0.0063,0.0063,0.0063,0.0063/)
      ufw=(/0.0163,0.0263,0.0563,0.0563,0.0563,0.1162,0.1162,0.1162,0.1162,0.1162/)
!      ufw=(/0.0042,0.009,0.009,0.0563,0.0563,0.1162,0.1162,0.1162,0.1162,0.1162/)
      frac_ice1 = 0.01!0.015
      frac_ice2 = 0.001!0.01
!      if (snow_depth_t .gt. 0.0) then
!          emsoil =0.98
!      elseif (water_table_depth .gt. 0.0) then
!          emsoil =0.99
!      endif

      QLsoil=emsoil*sigma*((sftmp+273.2)**4)
      Rsoilab3=(QLair+QLleaf)*(1.0-rhoS(3))-QLsoil
!      write (77,*) 'QLair',QLair,'QLleaf',QLleaf,'rhoS(3))',rhoS(3),'QLsoil',QLsoil,'sftmp',sftmp

   ! Total radiation absorbed by soil
      if (snow_depth_t .gt. 0.0) then
         Rsoilabs=(Rsoilab1+Rsoilab2)*(1-albedo_snow)/(1-0.1)+Rsoilab3
      elseif (water_table_depth .gt. 0.0) then
         Rsoilabs=(Rsoilab1+Rsoilab2)*(1-albedo_water)/(1-0.1)+Rsoilab3
      else
      Rsoilabs=Rsoilab1+Rsoilab2+Rsoilab3
      endif

!    thermodynamic parameters for air
      rhocp=cpair*Patm*AirMa/(Rconst*TairK)
      H2OLv=H2oLv0-2.365e3*Tair
      slope=(esat(Tair+0.01)-esat(Tair))/0.01

      psyc=Patm*cpair*AirMa/(H2OLv*H2OMw)
      Cmolar=Patm/(Rconst*TairK)
      fw1=AMIN1(AMAX1((FILDCP-wcl(1))/(FILDCP-WILTPT),0.3),1.0)
!
      if (water_table_depth .gt. 0.0) then
         Rsoil = 0.
      else
         Rsoil=30.*exp(0.2/fw1)
!!    ******************************************************************
!!       Chris added for permafrost soil evaporation
!!         Rsoil=200.*exp(-0.2/fw1)
!!         Rsoil=38113.*exp(-13.515*fw1)   !following Mahfouf and Noilhan 1991; Passerat 1986
!!         Rsoil0=6
!         Rsoil=10**Rsoil0*exp(-13.515*fw1)   !following Mahfouf and Noilhan 1991; Passerat 1986
!!         print*,'Rsoil0',Rsoil0,fw1
!!         Rsoil=Rsoil0*exp(1.0/fw1)
!!         Rsoil=20*exp(1.0/fw1)
!!    ******************************************************************
      endif
      !Rsoil=40.
      !Rsoil=5.
      rLAI=exp(FLAIT)
!     latent heat flux into air from soil
!           Eleaf(ileaf)=1.0*
!     &     (slope*Y*Rnstar(ileaf)+rhocp*Dair/(rbH_L+raero))/    !2* Weng 0215
!     &     (slope*Y+psyc*(rswv+rbw+raero)/(rbH_L+raero))
!
      Esoil=(slope*(Rsoilabs-G)+rhocp*Dair/(raero+rLAI))/       &
     &      (slope+psyc*(Rsoil/(raero+rLAI)+1.))
!     write (77,*) 'Esoil',Esoil,'slope',slope,'Rsoilabs',Rsoilabs,'G',G,'rhocp',rhocp,'Dair',Dair,'(raero+rLAI)',(raero+rLAI)
!     write (77,*) 'psyc',psyc,'Rsoil',Rsoil

!     !!    ******************************************************************
!!   Chris added for permafrost soil
!     Esoil=(slope*(Rsoilabs-G)+rhocp*Dair/(raero+rLAI))/       &
!     &      (slope+psyc*((Rsoil+20.5)/(raero+rLAI)+1.))
!!      print*,'Esoil',slope,psyc*(Rsoil/(raero+rLAI)+1.),Esoil
!!!    ******************************************************************     !

     !if (snow_depth_t .gt. 0.) Esoil=0.

!      endif
     !Esoil=0.
     resht_lai=resht*FLAIT
     !resht_lai= resht*exp(FLAIT)/15. ! need improvement, should be a function of LAI
      !if (water_table_depth .gt. 0.0) resht_lai=resht/FLAIT*0.2

      !resht_lai=200.
      Hsoil=rhocp*(sftmp-Tair)/resht_lai

!     write (84,184) Esoil,slope,Rsoilabs,G,rhocp,Dair,raero,rLAI,psyc,Rsoil,  &
!     &  Hsoil,sftmp,Tair,resht_lai
!184   format(14(f15.9,","))

      !Hsoil=rhocp*(sftmp-Tair)/resht_lai
      !Hsoil=1010.*1.17*(sftmp-Tair)/resht_lai
      i=1;
      condu(i)=(FILDCP-wcl(i))*condu_air+liq_water(i)/(thksl(i)*0.01)*condu_water+ &
         &  ice(i)/(thksl(i)*0.01)*condu_ice +(1-FILDCP)*condu_soil
      shcap(i)=(FILDCP-wcl(i))*shcap_air+liq_water(i)/(thksl(i)*0.01)*shcap_water+ &
            ice(i)/(thksl(i)*0.01)*shcap_ice +(1-FILDCP)*shcap_soil
      difsv1=3600.*condu(i)/shcap(i)*10000.
      !print*,'shcap',shcap(i),condu(i)

      G=condu(1)*(sftmp-tsoill(1))/(thksl(1)/2.*0.01)
      if (snow_depth_t .gt. 0.0) then
          G=condu_snow*(sftmp-Tsnow)/(snow_depth_t/2.*0.01)
      endif

      ! thksl(1)
      !G=0.
      ! Residual heat energy.
      RESDH=Rsoilabs-Hsoil-Esoil-G
      !print*,'RESDH',Rsoilabs,Hsoil,Esoil,G,RESDH
      !G=RESDH

      ! First derivative of net radiation; sensible heat; ground heat;
      DNR=4.*emsoil*sigma*(sftmp+273.2)**3
      DSH=rhocp/resht_lai
      DGH=condu_s/(thksl(1)/2.*0.01)
      DLE=(DNR+DGH)*slope/(slope+psyc*(Rsoil/(raero+rLAI)+1.))
      drsdh=-DNR-DSH-DGH-DLE
    ! Calculate increment DELTA.
      DELTA=resdh/drsdh
      sftmp_pre=sftmp

      sftmp=sftmp-DELTA
!      write (77,*) 'sftmp',sftmp,'DELTA',DELTA,'resdh',resdh,'drsdh',drsdh
      if (ABS(sftmp_pre -sftmp) .gt. 15. ) sftmp=sftmp_pre  !if abs(Delta)>20
!      write (77,*) 'sftmp',sftmp
      tsoill_0=sftmp
    ! Temperature dynamics along soil profile
     !difsv1=diff_s

!     if (snow_depth_t .gt. 0.) then
!        d_cor=20.
!        diff_snow=d_cor*diff_snow/snow_depth_t
!        write(*,*)snow_depth_t
!     endif

     do i=1,10
        Tsoill_pre=tsoill(i)
        !print*,'tsoill',i,tsoill(i)


        if (water_table_depth .lt. 0.0 .and. -water_table_depth .lt. depth_z(i)) then
            liq_water(i)=FILDCP*thksl(i)*0.01-ice(i)
        else
            liq_water(i)=wcl(i)*thksl(i)*0.01-ice(i)
        endif
        !print*,'liq_water',i,water_table_depth,thksl(i),ice(i),wcl(i),FILDCP


        if (i .eq. 1) then
            depth_z(1)=thksl(1)
        else
            depth_z(i)=depth_z(i-1)+thksl(i)
        endif

!        thkns2=(thksl(i)+thksl(i+1))/2.

        if (i .le. 9) then                      !Shuang revised on 4/19/2019
            thkns2=(thksl(i)+thksl(i+1))/2.
        else
            thkns2=(thksl(i)+20.0)/2.
        endif

        if (i .eq. 10) then
         difsv2=3600.*condu(i)/shcap(i)*10000.
        else
         condu(i+1)=(FILDCP-wcl(i+1))*condu_air+liq_water(i+1)/(thksl(i+1)*0.01)*condu_water+ &
         &  ice(i+1)/(thksl(i+1)*0.01)*condu_ice +(1-FILDCP)*condu_soil
         shcap(i+1)=(FILDCP-wcl(i+1))*shcap_air+liq_water(i+1)/(thksl(i+1)*0.01)*shcap_water+ &
            ice(i+1)/(thksl(i+1)*0.01)*shcap_ice +(1-FILDCP)*shcap_soil

!         if(i .eq. 1)print*,'difsv2',difsv2,shcap(i+1),condu(i+1),FILDCP,wcl(i+1),liq_water(i+1), ice(i+1),condu_soil
         difsv2=3600.*condu(i+1)/shcap(i+1)*10000.
        endif

        temph2=(difsv1+difsv2)*(Tsoill(i)-Tsoill(i+1))/thkns2
!        if(i .eq.  1)print*,'temph2',i,difsv1,difsv2,thkns2,Tsoill(i),Tsoill(i+1),shcap(i+1)


        !(dcount_soil/150.)**3.*
      !!!!!!!!!!!!!!!!!!!! start first layer !!!!!!!!!!!!!!!!!!!!!!
        !!!!!! adjust if there are snow or water layer above !!!!!!!!!!!!!!!!!!!!
        if(i.eq.1) then
           if (snow_depth_t .gt. 0.) then
               temph_snow = Amin1(diff_snow,difsv1)*(Tsnow-Tsoill(1))/((snow_depth_t+thksl(1))/2.)
               Tsnow=Tsnow+(exp(-depth_ex*snow_depth_t)*diff_snow*(sftmp-Tsnow)/(snow_depth_t/2.) &
        &              -temph_snow)/(snow_depth_t/2.+(snow_depth_t+thksl(1))/2.)

              !print*,'Tsoill,here0',Tsoill(1)
               Tsoill(1)=Tsoill(1)+(temph_snow &
        &              -temph2)/((snow_depth_t+thksl(1))/2.+thkns2)
!               print*,'Tsoill,here2',Tsoill(1),temph_snow,snow_depth_t,thkns1,thkns2

               if (Tsnow .gt.0.0) then
                   Tsnow =0.0
                   Tsoill(1)=0.
               endif

                !write(*,*)temph2
               drsdh =0.0    ! temporarily set drsdh =0 for heat adjustment of soil when
               tsoill_0= (Tsoill(1)+Tsnow)/2.
           elseif (water_table_depth .gt. 0.) then
               temph_water = (3600.*condu_water/shcap_water*10000.+difsv1)*(Twater-Tsoill(1))/((water_table_depth+thksl(1))/2.)! there is snow layer
               Twater=Twater+(2.*3600.*condu_water/shcap_water*10000.*(sftmp-Twater)/(water_table_depth/2.) &
        &              -temph_water)/(water_table_depth/2.+(water_table_depth+thksl(1))/2.)

         !!!!!!!!!!!!!!!!!!  Phase change surface water !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
               if (Twater .lt. 0.0 .and. water_tw .gt. 0.0) then  ! freeze
                   heat_excess=-(shcap_water/360000.*water_tw*100.-drsdh)*Twater
                   ice_incr=heat_excess*3600./latent_heat_fusion/ice_density
!!       ..int add mechanism of unfrozen water in frozen soil layers, typically happens in high latitude region
!!              according to obs soil water content, winter water never goes below 0.063 at -20cm and 0.042 at surface layer
!! $$$$$$$$$$$      !tuneice
!                if (ice_incr .lt. 0.) then
!                   if (i .eq. 1.) then
!                       if (liq_water(i) .le. ufw(i)) then
!!                           ice_incr = 0. !ice_incr*0.1
!                          ice_incr = ice_incr*frac_ice1
!                       endif
!    !               elseif (i .eq. 2) then
!    !                   if (liq_water(i) .le. 0.063) then
!    !                       ice_incr = 0.
!    !                   endif
!                   elseif ( i .gt. 1.) then
!                       if (liq_water(i) .le. ufw(i)) then
!!                           ice_incr = ice_incr*0. !0.9
!                           ice_incr = ice_incr*frac_ice2
!                       endif
!                   endif
!                endif
!! $$$$$$$$$$$

                   !write(*,*)'water_tw',water_tw
                   if (ice_incr .lt. water_tw) then
                     ice_tw=ice_tw +ice_incr
                     water_tw=water_tw-ice_incr
                     Twater=0.0
                     Tice=0.0
                   else
                     ice_tw=ice_tw +water_tw
                     water_tw=0.0
                     Tice = Tice - latent_heat_fusion*(ice_incr-water_tw)*ice_density/(shcap_ice*ice_tw)
                   endif
               elseif (Twater .gt. 0.0 .and. ice_tw .gt. 0.0) then    ! thraw
                   heat_excess=(shcap_water/360000.*ice_tw*100.-drsdh)*Twater
                   ice_incr=heat_excess*3600./latent_heat_fusion/ice_density
!! $$$$$$$$$$$
!! $$$$$$$$$$$      !tuneice
!                if (ice_incr .lt. 0.) then
!                   if (i .eq. 1.) then
!                       if (liq_water(i) .le. ufw(i)) then
!!                           ice_incr = 0. !ice_incr*0.1
!                          ice_incr = ice_incr*frac_ice1
!                       endif
!    !               elseif (i .eq. 2) then
!    !                   if (liq_water(i) .le. 0.063) then
!    !                       ice_incr = 0.
!    !                   endif
!                   elseif ( i .gt. 1.) then
!                       if (liq_water(i) .le. ufw(i)) then
!!                           ice_incr = ice_incr*0. !0.9
!                           ice_incr = ice_incr*frac_ice2
!                       endif
!                   endif
!                endif
!! $$$$$$$$$$$
!! $$$$$$$$$$$
!
!

                   if (ice_incr .lt. ice_tw) then
                     ice_tw=ice_tw -ice_incr
                     water_tw=water_tw+ice_incr
                     Twater=0.0
                     Tice=0.0
                   else
                     water_tw=water_tw +ice_tw
                     ice_tw=0.0
                     Twater = Twater + latent_heat_fusion*(ice_incr-ice_tw)*ice_density/(shcap_water*water_tw)
                   endif
              !write(*,*)'heat_excess',ice_incr-ice_tw
               endif
   !!!!!!!!!!!!!!!!!!!!!!!!! end of phase change for surface layer !!!!!!!!!!!!!!!!!!!
             !print*,'Tsoill,here2',Tsoill(1)

               temph2=(difsv1+3600.*condu_water/shcap_water*10000.)*(Tsoill(i)-Tsoill(i+1))/thkns2
               if (water_tw .eq. 0.0 .and. ice_tw .gt. 0.0) then
                   Tsoill(1)=Tsoill(1)+(2.*3600.*condu_ice/shcap_ice*10000.*(Tice-Tsoill(1))/thkns1 &
        &              -temph2)/(thkns1+thkns2)
               else
                   Tsoill(1)=Tsoill(1)+(2.*3600.*condu_water/shcap_water*10000.*(Twater-Tsoill(1))/thkns1 &
        &              -temph2)/(thkns1+thkns2)
               endif
               drsdh =0.0    ! temporarily set drsdh =0 for heat adjustment of soil
!               print*,'Tsoill,here3',Tsoill(1),condu_ice,shcap_ice,Tice,thkns1,thkns2,diff_s,Twater,temph2
          else
         !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
         !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

             !print*,'Tsoill,here3',Tsoill(1)
               Tsoill(1)=Tsoill(1)+(diff_s*(sftmp-Tsoill(1))/thkns1 &
        &              -temph2)/(thkns1+thkns2)
!             print*,'Tsoill,here4',Tsoill(1),thkns1,thkns2,thkns1,diff_s,sftmp,temph2
          endif
        !!!!!  phase change in top soil
          heat_excess=drsdh*(thd_t-Tsoill(i))+shcap(i)*thksl(i)*(Tsoill(i)-thd_t)/360000.
          ice_incr=heat_excess*3600./latent_heat_fusion/ice_density
!          print*,'ice_incr',i,ice_incr,heat_excess,latent_heat_fusion,ice_density,drsdh,thd_t,Tsoill(i),shcap(i),thksl(i)
!
!! $$$$$$$$$$$
!! $$$$$$$$$$$      !tuneice
!                if (ice_incr .lt. 0.) then
!                   if (i .eq. 1.) then
!                       if (liq_water(i) .le. ufw(i)) then
!!                           ice_incr = 0. !ice_incr*0.1
!                          ice_incr = ice_incr*frac_ice1
!                       endif
!    !               elseif (i .eq. 2) then
!    !                   if (liq_water(i) .le. 0.063) then
!    !                       ice_incr = 0.
!    !                   endif
!                   elseif ( i .gt. 1.) then
!                       if (liq_water(i) .le. ufw(i)) then
!!                           ice_incr = ice_incr*0. !0.9
!                           ice_incr = ice_incr*frac_ice2
!                       endif
!                   endif
!                endif
!! $$$$$$$$$$$
!! $$$$$$$$$$$
!          if (i .eq. 1) then
!            write (*,*) '1',ice(1)
!          endif


          inter_var = ice(i)
          if (ice_incr .lt. 0.) then     ! freeze
              ice(i)=Amin1(liq_water(i)+inter_var,ice(i)-ice_incr)
          else
              ice(i) = Amax1(ice(i)-ice_incr,0.0)
          endif

!          if (i .eq. 1) then
!                write (*,*) '2 ice(1)',ice(1),'liq_water(1)',liq_water(1),'inter_var',inter_var,'ice_incr',ice_incr
!          endif
         !! readjust energy and temp
          heat_adjust=heat_excess-latent_heat_fusion*(inter_var-ice(i))*ice_density/3600.
          Tsoill(i)=thd_t+heat_adjust/(shcap(i)*thksl(i)/360000.-drsdh)
        else
!            if ( i .gt. 9) then
!                temph2=0
!                thkns2=500  ! boundary conditions, rethink
!            endif
            if ( i .gt. 9) then
                temph2=0.00003
                thkns2=500  ! boundary conditions, rethink
!                thkns2=thkbot  ! Chris added this parameter for CIPHER
            endif



            Tsoill(i)=Tsoill(i)+(temph1-temph2)/(thkns1+thkns2)
            heat_excess=shcap(i)*thksl(i)*(Tsoill(i)-thd_t)/360000.
            ice_incr=heat_excess*3600./latent_heat_fusion/ice_density

!! $$$$$$$$$$$
!! $$$$$$$$$$$      !tuneice
!                if (ice_incr .lt. 0.) then
!                   if (i .eq. 1.) then
!                       if (liq_water(i) .le. ufw(i)) then
!!                           ice_incr = 0. !ice_incr*0.1
!                          ice_incr = ice_incr*frac_ice1
!                       endif
!    !               elseif (i .eq. 2) then
!    !                   if (liq_water(i) .le. 0.063) then
!    !                       ice_incr = 0.
!    !                   endif
!                   elseif ( i .gt. 1.) then
!                       if (liq_water(i) .le. ufw(i)) then
!!                           ice_incr = ice_incr*0. !0.9
!                           ice_incr = ice_incr*frac_ice2
!                       endif
!                   endif
!                endif
!! $$$$$$$$$$$
!! $$$$$$$$$$$
!


            inter_var = ice(i)
            if (ice_incr .lt. 0.) then     ! freeze
               ice(i)=Amin1(liq_water(i)+inter_var,ice(i)-ice_incr)
            else
               ice(i) = Amax1(ice(i)-ice_incr,0.0)
            endif
!            print*,'ice2',ice(i),ice_incr,inter_var
                         !! readjust energy and temp
            heat_adjust=heat_excess-latent_heat_fusion*(inter_var-ice(i))*ice_density/3600.
            Tsoill(i)=thd_t+heat_adjust/(shcap(i)/360000.*thksl(i))
        endif

        if (ABS(tsoill_pre -tsoill(i)) .gt. 5. ) Tsoill(i)=tsoill_pre
          TEMPH1=TEMPH2
          THKNS1=THKNS2
          DIFSV1=DIFSV2
     enddo

      ! use on site soil temperature to drive the model
      tsoill_0=input_tsoil(1)
      tsoill(1:10)=input_tsoil(2:11)


     testout(1)=tsoill_0
     !testout(1)=tsnow
     testout(2:11)=tsoill(1:10)
     !testout(1:10)=tsoill(2)
     !testout(1)=dcount_soil
     !testout(1:10)=liq_water(1:10)
     !testout(1:10)=ice
     !testout(1)=Hsoil

!     write(82,182) testout(1),testout(2),testout(3),testout(4),testout(5)
!182     format(5(f15.9,","))
     deallocate(depth_z)
     return
     end

 subroutine methane(Rh_pools,Tsoil,zwt,wsc,thksl,depth,      &
        &           phi,LAIMIN,LAIMAX,dpatm,         &
        &           ProCH4,Pro_sum,OxiCH4,Oxi_sum,Fdifu,Ebu_sum_sat,Ebu_sum_unsat,Pla_sum,simuCH4,CH4,CH4_V,   &
        &           r_me,Q10pro,kCH4,Omax,CH4_thre,Tveg,Tpro_me,Toxi,  &
        &           f,Nbub,bubprob,Vmaxfraction,     &                                 !DA parameters
        &           methanebP,methaneP,presP,pwater,Vp,bubble_methane_tot,  &		!with initial values
        &           testout,do_soilphy,do_co2_da,do_da,do_methane_da,do_methane_fcast,do_EBG)

!******************************************************************************************************************************
!****!introduce variables and constants used in this subroutine
!******************************************************************************************************************************
!     set soil layers
!******************************************************************************************************************************
      implicit none
!      integer i,MEMCMC
      integer i
      integer,parameter :: nlayers=10       !use this statement to set the parameter value
      real zwt,dpatm     !dpatm is dynamic atmospheric pressure unit Pa, it is used only in calculating ebullition
      real consum
!******************************************************************************************************************************
!     set values for MEMCMC
!******************************************************************************************************************************
      integer,parameter :: miterms=29
      integer,parameter :: ilines=9000
!******************************************************************************************************************************
!     CH4 Production
!******************************************************************************************************************************
!      real Rhetero
      real Rh(nlayers),Rh_pools(5),Rh_h,ProCH4(nlayers),Pro_sum,Rh_h_new
      real r_me         !release ratio of CH4 to CO2
      real Q10pro
      real fSTP(nlayers)         !CH4 production factor of soil temperature
      real vt,xt
      real Tmax_me,Tpro_me
      real fpH          !CH4 production factor of soil pH
      real fEhP         !CH4 production factor of soil redox potential
      real FRLEN(nlayers),FRLEN_PMT(nlayers)        !fraction of root in each layer
      real Tsoil
!******************************************************************************************************************************
!     CH4 Oxidation
!******************************************************************************************************************************
      real CH4(nlayers),CH4_V(nlayers)          !both are CH4 concentration: CH4(nlayers)unit gC/m2, CH4_V(nlayers) unit g C/ m3
      real wsc(nlayers)
      real OxiCH4(nlayers),Oxi_sum       !CH4 oxidation
      real Omax_layers(nlayers),Omax       !maximum oxidation rate
      real kCH4_layers(nlayers),kCH4       !system specific half saturation constant
      real Q10oxi
      real fCH4(nlayers)         !CH4 oxidation factor of CH4 concentration
      real fSTO(nlayers)         !CH4 oxidation factor of soil temperature
      real fEhO         !CH4 oxidation factor of soil redox potential
      real Toxi
!******************************************************************************************************************************
!     CH4 Diffusion
!******************************************************************************************************************************
      real Deff(nlayers)     !CH4 effective diffusivity !!used in mineral soil  v1.1
      real D_CH4_a           !CH4 diffusion coefficient in air  !unit cm2 s-1   diffusivity of CH4 in air
      real D_CH4_w           !CH4 diffusion coefficient in water  !unit cm2 s-1   diffusivity of CH4 in water
      real phi          !soil porosity  also used in water table part
      real fwater(nlayers),fair(nlayers)
      real D_CH4_soil(nlayers),D_CH4_soil_a(nlayers),D_CH4_soil_b(nlayers)      !!used in organic peat soil  v1.2
      real fcoarse      !relative volume of coarse pores depending on soil texture  Zhuang 2004
      real ftort        !tortuosity coefficient with a value of 0.66    Walter and Heimann 2000
      !suggesting that the distance covered by diffusion is about two thirds of the length of the real average path
      real SAND         !relative contents of sand (%) in the soil
      real PVSAND       !relative volume of coarse pores in sandy soils     set to 0.45     value from Walter 2001
      real SILT         !relative contents of silt (%) in the soil
      real PVSILT       !relative volume of coarse pores in silty soils     set to 0.20     value from Walter 2001
      real CLAY         !relative contents of clay (%) in the soil
      real PVCLAY       !relative volume of coarse pores in clayish soils     set to 0.14   value from Walter 2001
      real DEPTH(10)        !depth in soil  will define it inside this subroutine again      resolution 100mm 200mm
      real THKSL(10)        !will define it inside this subroutine again
      real Fdifu(nlayers)
      real CH4_atm      !concentration of CH4 in atmosphere     seen as 0 cause the value is too low someone use 0.076
      real simuCH4      !simulated CH4 emission
!***********  Boundary condition parameters    *************
      real ScCH4                                 !Schmidt numbers for methane Wania
      real pistonv                               !Piston velocity
      real Ceq                                   !equilibrium concentration of gas in the atmosphere
      real kHinv                                 !Henry's coefficient dependent variable on left side of equation, T is the independent variable
      real kH_CH4         !Henry's constant at standard temperature (CH4) Unit L atm mol-1
      real CHinv          !Coefficient in Henry's Law Unit K
      real Tsta           !standard temperature Unit K
      real Ppartial       !CH4 partial pressure in air Unit atm
      real Cold           !last time step of ch4 concentration on first soil layer
      integer jwt    !index of the soil layer right above the water table (-)
      integer mwt    !index of wt for EBG, which layer wt is at
!******************************************************************************************************************************
!     Ebullition
!******************************************************************************************************************************
      real CH4_thre,CH4_thre_ly(nlayers),EbuCH4(nlayers),Kebu
      real Ebu_sum_unsat,Ebu_sum_sat,Ebu_sum          !sum value one dimension is enough
      integer wtlevelindex
      real rouwater,g,Rgas,V   ! local paras for ebullition concentration threshold calculation
      real f,Nbub,bubprob,Vmaxfraction
      real methanebP(nlayers),methaneP(nlayers),presP(nlayers),pwater(nlayers),Vp(nlayers),bubble_methane_tot
      real mebu_out2(nlayers)
!******************************************************************************************************************************
!     Plant transport
!******************************************************************************************************************************
      real PlaCH4(nlayers),Pla_sum,Pla_consum
      real LAIMIN,LAIMAX
      real Tveg,Tgr,Tmat,fgrow,Pox,Kpla
!******************************************************************************************************************************
!******************************************************************************************************************************
      ! Yuan added for soil temp
      logical do_soilphy,do_co2_da,do_methane_da,do_methane_fcast,do_EBG,do_da
      real testout(11), tsoil_layer(11)
!******************************************************************************************************************************
!******************************************************************************************************************************
      real rh_layert
      !      MEMCMC=0   ! note here, any changes here result unexpected bug
      Rh_h=Rh_pools(1)+Rh_pools(2)+Rh_pools(3)+Rh_pools(4)+Rh_pools(5)  !hourly Rh_f + Rh_c + Rh_Micr + Rh_Slow + Rh_Pass
!      phi = 0.565


      tsoil_layer = testout


! testing the EBG ebullition method:
    FRLEN = (/0.75,0.2,0.02,0.02,0.01,0.0,0.0,0.0,0.0,0.0/)
    FRLEN_PMT = (/0.75,0.2,0.02,0.02,0.01,0.0,0.0,0.0,0.0,0.0/)


      simuCH4 = 0.0                 ! v1.2
      rh_layert=0.0
      do i = 1, nlayers
                                        !!!!!!!put it out of the subroutine
         !****************************************************
         !* Rh weighed according to the distribution of root *
         !****************************************************
!              if (i .LE. 3) then                                 ! the empirical method used here is from CLM4.5
!                 Rh(i)= 0.5*Rh_h*FRLEN(i)+((0.5*Rh_h)/0.3)*0.1
!                 ! Rh(h,i)Rh produced by each layer per hour  unit should be g C m-2 h-1
!              else                                               ! i*10: depth of ith soil layers
!                 Rh(i)= 0.5*Rh_h*FRLEN(i)
!              endif
!!
!!        *************   **********    **************    *****************    *********************
!            ! the empirical method used here is from CLM4.5
                 Rh(i)= 0.5*Rh_h*FRLEN(i) + 0.5*Rh_h*(thksl(i)/depth(10))
                rh_layert=rh_layert+Rh(i)
!                 write (*,*) i, Rh(i)/Rh_h,rh_layert/Rh_h,phi

      enddo

!******************************************************************************************************************************
!******************************************************************************************************************************

     !****************************************************
     !A. methane production     hourly  gC m-2 hour-1
     !Methane production is modeled as an anaerobic process that occurs in the saturated zone of the soil profile ZHUANG
     !****************************************************
     !Rh_h=Rh_pools(1)+Rh_pools(2)+Rh_pools(3)+Rh_pools(4)+Rh_pools(5)  !hourly Rh_f + Rh_c + Rh_Micr + Rh_Slow + Rh_Pass
     !r assignment
!      r_me=0.3      !find in parafile
      Tmax_me=45.0
!      Tpro_me=10.0
!      Q10pro=3.0    !find in parafile
      do i = 1,nlayers
          if (do_soilphy) then
              if (tsoil_layer(i+1) .lt. 0.0) then
                  fSTP(i) = 0.0
              else if (tsoil_layer(i+1) .gt. Tmax_me) then
                  fSTP(i) = 0.0
              else if (tsoil_layer(i+1) .ge. 0.0 .and. tsoil_layer(i) .le. Tmax_me) then
                  fSTP(i) = Q10pro**((tsoil_layer(i+1)-Tpro_me)/10)        !Tsoil is the only variable
              endif
          else
              if (Tsoil .lt. 0.0) then
                  fSTP(i) = 0.0
              else if (Tsoil .gt. Tmax_me) then
                  fSTP(i) = 0.0
              else if (Tsoil .ge. 0.0 .and. Tsoil .le. Tmax_me) then
                  fSTP(i) = Q10pro**((Tsoil-Tpro_me)/10)        !Tsoil is the only variable
              endif
          endif
      enddo
     !fpH assignment
      fpH=1.0
     !fEhP assignment
      fEhP=1.0


      Pro_sum=0.0
      do i = 1,nlayers
!          (depth(i)*10)                   !convert unit from cm to mm
!          (THKSL(i)*10)                   !convert unit from cm to mm convert the unit in each of the equations
          if ((depth(i)*10) .le. -zwt) then
                  ProCH4(i)=0.0
          else
              if (((depth(i)*10.0)-(THKSL(i)*10.0)) .lt. -zwt) then
                  ProCH4(i)=Rh(i)*r_me*fSTP(i)*fpH*fEhP*(((depth(i)*10.0)-(-zwt))/(THKSL(i)*10.0))     ! *percent
              elseif (((depth(i)*10.0)-(THKSL(i)*10.0)) .ge. -zwt) then
                  ProCH4(i)=Rh(i)*r_me*fSTP(i)*fpH*fEhP
              endif
          endif
          Pro_sum=Pro_sum+ProCH4(i)
      enddo
!      write (*,*) 'tsoil_layer(2))',tsoil_layer(2),'Rh_pools(1)',Rh_pools(1),'wsc(1)',wsc(1),'zwt',zwt,'dpatm',dpatm,&
!      & r_me,Q10pro,Omax,CH4_thre,Tveg
     !**************************************************
     !Add CH4 production to CH4 pool    (gC layer -1)=(gC m-2)
     !**************************************************
!      write (*,*) 'before pro CH4(123)', CH4(1),CH4(2),CH4(3)
      do i=1,nlayers
          CH4(i) = CH4(i) + ProCH4(i)
!          CH4_V(i) = CH4(i)/(wsc(i)*0.001)
          CH4_V(i) = CH4(i)/(THKSL(i)*0.01)
      enddo
!      write (*,*) 'after pro CH4(123)', CH4(1),CH4(2),CH4(3)

!     END OF METHANE PRODUCTION

!     ********************************************************************************************************************
!     B. methane oxidation      hourly  unit gC m-2 h-1     !!!!!!!!!!!method of CLM and Zhuang!!!!!!!!!!!!
!     Methane oxidation is modeled as an aerobic process that occurs in the unsaturated zone of the soil profile ZHUANG
!     ********************************************************************************************************************
!     fSTO assignment
!     ***************
      Q10oxi=2.0      !Zhu 2014 results from previous studies  unit 1  also used by zhang
!      Toxi=10.0       !Zhuang 2004 table1 Boreal Forest Wetland
      do i=1,nlayers
          if (do_soilphy) then
              fSTO(i)=Q10oxi**((tsoil_layer(i+1)-Toxi)/10.0)
          else
              fSTO(i)=Q10oxi**((Tsoil-Toxi)/10.0)
          endif
      enddo
!     fEhO assignment
      fEhO=1.0        !Walter 2000  did not consider it, equal to value of 1

!     Omax assignment
!     ***************
      Oxi_sum=0.0
      do i = 1,nlayers
!      Omax=1.5
!      Omax=15.0  !!find in parafile Zhuang 2004 table1 Boreal Forest Wetland umol L-1 h-1 system specific maximum oxidation coefficient
!     convert the unit of Omax from umol L-1 h-1 to gC m-2 h-1
     !/1000,000 to get mol
     !*12 cmass to get gC
     !*1000 to get from dm-3(L) to m-3
     !*(wsc*0.001) to get unit of omax_layers from m-3 to m-2     !caution that wsc unit is mm
     !** w  /   (w/t)           CLM used
!      Omax_layers(i)=(Omax/(1000000))*12*1000*(wsc(i)*0.001)     !convert the unit of Omax from umol L-1 h-1 to gC m-2 h-1
      Omax_layers(i)=(Omax/(1000000))*12*1000*(THKSL(i)*10.0)*0.001     !modified on 11/27/2016 no sig change in oxidation and emission
     !in unsaturated part of oxidation in CLM, they used the Omax/10 but did not expained why   they also /water volume

     !fCH4 assignment
!     ***************
!      kCH4=5.0     !!find in parafile Zhuang 2004 range between 1 and 66.2μmol L-1 system specific half saturation constant  1.0e
!     convert the unit of kCH4 from μmol L-1 to gC m-2
!      kCH4_layers(i)=(kCH4/(1000000))*12*1000*(wsc(i)*0.001)    !convert the unit of kCH4 from umol L-1 to gC m-2
      kCH4_layers(i)=(kCH4/(1000000))*12*1000*(THKSL(i)*10.0)*0.001
!     then calculate fCH4 with CH4(i) and kCH4_layers(i)
      fCH4(i)=CH4(i)/(kCH4_layers(i)+CH4(i))   !  CH4 concentration factor

          if ((depth(i)*10.0) .le. -zwt) then                !unit of Omax: gC m-2 h-1
                  OxiCH4(i)=Omax_layers(i)*fCH4(i)*fSTO(i)*fEhO!*0.1      !wrong:*(THKSL(i)/1000)!mm to m account for the thickness
!                  OxiCH4(i)=CH4(i)*0.001
          else
              if (((depth(i)*10.0)-(THKSL(i)*10.0)) .lt. -zwt) then
                  if (i .eq. 1) then
                  OxiCH4(i)=Omax_layers(i)*fCH4(i)*fSTO(i)*fEhO*((-zwt)/(THKSL(i)*10.0))
                  else
                  OxiCH4(i)=Omax_layers(i)*fCH4(i)*fSTO(i)*fEhO*(((-zwt)-(depth(i-1)*10.0))/(THKSL(i)*10.0))      !  *percent
                  endif
!                  OxiCH4(i)=CH4(i)*0.001*(((-zwt)-(depth(i-1)*10.0))/(THKSL(i)*10.0))
              else if (((depth(i)*10.0)-(THKSL(i)*10.0)) .ge. -zwt) then
                  OxiCH4(i)= 0.0
              endif
          endif


          if (OxiCH4(i) .gt. CH4(i)) then
              OxiCH4(i)=CH4(i)
          endif

      Oxi_sum=Oxi_sum+OxiCH4(i)
     ! write (*,*) 'Oxi_sum',Oxi_sum
      enddo

     !*******************************************************************
     !minus CH4 oxidation from CH4 pool
     !*******************************************************************
!      write (*,*) 'before oxi CH4(123)', CH4(1),CH4(2),CH4(3)
      do i=1,nlayers
          CH4(i) = CH4(i) - OxiCH4(i)               !minus CH4 oxidation from CH4 pool
!         CH4_V(i) = CH4(i)/(wsc(i)*0.001)
          CH4_V(i) = CH4(i)/(THKSL(i)*0.01)          !convert concentration from gC/m2 to gC/m3
                                                    !CH4_V(i) can be used for DA with observation data in soil layers
      enddo
!      write (*,*) 'after oxi CH4(123)', CH4(1),CH4(2),CH4(3)
!      write (*,*) 'before difu CH4(1)',CH4(1),'wsc(1)',wsc(1),'CH4_V(1)',CH4_V(1)
!     END OF METHANE OXIDATION

!     ****************************************************
!     C. methane diffusion
!     ****************************************************
!     Parameters assignment
      D_CH4_a=0.2            !unit cm2 s-1   D_CH4_a is the molecular diffusion coefficient of methane in air
      D_CH4_a=(D_CH4_a/10000.0)*3600.0        !unit m2 h-1

      D_CH4_w=0.00002        !unit cm2 s-1   D_CH4_a is the molecular diffusion coefficient of methane in water
      D_CH4_w=(D_CH4_w/10000.0)*3600.0        !unit m2 h-1

      ftort=0.66        !tortuosity coefficient with a value of 0.66    Walter and Heimann 2000

!     parameters for fcoarse algorithm
      SAND=0.4             !   %   SPRUCE site value    0.4
      SILT=0.4             !   %   SPRUCE site value   0.4
      CLAY=0.2             !   %   SPRUCE site value   0.2
      PVSAND=0.45       !relative volume of coarse pores in sandy soils       set to 0.45     value from Walter 2001 zhuang
      PVSILT=0.20       !relative volume of coarse pores in silty soils       set to 0.20     value from Walter 2001 zhuang
      PVCLAY=0.14       !relative volume of coarse pores in clayish soils     set to 0.14     value from Walter 2001 zhuang
      fcoarse=SAND*PVSAND+SILT*PVSILT+CLAY*PVCLAY
      CH4_atm=0.076       !unit umol L-1
!      CH4_atm=0.0       !unit umol L-1

!       ******************************************************************************************************
!       * Peat soil solution for diffusion coefficient: Equations for D_CH4_soil *         v1.2    Millington and Quirk Model
!       ******************************************************************************************************
      do i=1,nlayers
          fwater(i) = wsc(i)/(THKSL(i)*10)
          fair(i) = phi-fwater(i)

        D_CH4_soil_a(i) = (((fair(i))**(10/3))/((phi)**2))*D_CH4_a
        D_CH4_soil_b(i) = D_CH4_w
        if (fair(i) .ge. 0.05) then
            D_CH4_soil(i) = D_CH4_soil_a(i)
        else
            D_CH4_soil(i) = D_CH4_soil_b(i)
        endif
!        D_CH4_soil(i) = ge(fair,0.05)*D_CH4_soil_a(i) + lt(fair,0.05)*D_CH4_soil_b(i)


!        Here I divided into saturated layer and unsaturated layer conditions because in most cases fair is > 0.05 and that there might be too much diffusion v1.2
        ! or maybe I can adjust the value of threshold 0.05 to around 0.08 as in most cases fwater=0.88 fair=0.07
!          if (zwt .ge. 0.0) then                                  !when water table is above the soil surface
!              Deff(i) = D_CH4_W
!          elseif (zwt .lt. 0.0) then                                  !when water table is below the soil surface
!              if ((depth(i)*10.0) .le. -zwt) then               !acrotelm layers
!                  Deff(i) = D_CH4_soil(i)
!              elseif (((depth(i)*10.0)-(THKSL(i)*10.0)) .lt. -zwt) then       !partly acrotelm layer
!                  Deff(i) = D_CH4_soil(i)
!              elseif (((depth(i)*10.0)-(THKSL(i)*10.0)) .ge. -zwt) then   !catotelm layers
!                  Deff(i) = D_CH4_W
!              endif
!          endif

        ! in this case diffusion should be more
        Deff(i) = D_CH4_soil(i)
      enddo


!       ******************************************************************************************************
!       * Mineral soil solution for diffusion coefficient: Equations for D_CH4_soil *         v1.1   Three-porosity-model
!       ******************************************************************************************************
!      do i = 1,nlayers
!          fwater = wsc(i)/(THKSL(i)*10)
!!          fair = phi-fwater
!!          fwater = 0.68         ! switch on when testing the effect of fwater on diffusion 0.6 crash 0.7fine  02172017
!          Deff(i) = D_CH4_a*fcoarse*ftort*phi*(phi-fwater)+D_CH4_w*fwater           !
!      enddo


         !convert the unit of CH4_atm from umol L-1 to gC m-3
             !/1000,000 to get mol
             !*12 cmass to get gC
             !*1000 to get from dm-3(L) to m-3
          CH4_atm = (CH4_atm/1000000)*12*1000

!      Fdifu(1) = Deff(1)*(CH4_V(1)-CH4_atm)/(THKSL(1)*0.01)         !refer to the interface of methane flux from layer 1 to atmosphere  cm to m   switch on/off
!     !New improvement 2017: Boundary condition
      kH_CH4 = 714.29
      CHinv = 1600.0
      Tsta = 298.15
!
      Ppartial = 1.7E-6     !unit atm  partial pressure of methane in atmosphere
! *****  before Tsoil layers were added
          if (.not. do_soilphy) then
              ScCH4 = 1898 - 110.1*Tsoil + 2.834*Tsoil**2 - 0.02791*Tsoil**3
                pistonv = 2.07 * (ScCH4/600)**(-1/2)  !n=-1/2   pistonv unit=m/s in Wania's paper but cm/h in the code
                 pistonv = pistonv*0.01   ! convert from cm/h to m/h
              kHinv = kH_CH4 /(exp(CHinv*(1.0/(Tsoil+273.15)-1.0/Tsta)))
              Ceq = Ppartial / kHinv    ! Ceq: mol L-1   p_partial: atm  kHinv atm mol-1
               Ceq = Ceq * 12 * 1000    ! Ceq mol/L to g/m3
          endif
! ********************************
       if (zwt .ge. -100) then   !index j, water table is right below the jth layer
           jwt=0.
       elseif (zwt .lt. -100 .and. zwt .ge. -500.0) then  !layer 1-5
!           jwt=int(-zwt/100)-1
                jwt=int(-zwt/100)
       else
!           jwt=int((-zwt-500)/200+5)-1
           jwt=int((-zwt-500)/200+5)
           if (jwt .gt. 10) then         !sm
               jwt = 10.
       endif
       endif
!       write (77,*) 'jwt',jwt,'zwt',zwt
! *******2*************************
       do i=1,nlayers

! *****  after Tsoil layers were added
          if (do_soilphy) then
              ScCH4 = 1898 - 110.1*tsoil_layer(i+1) + 2.834*(tsoil_layer(i+1))**2 - 0.02791*(tsoil_layer(i+1))**3
              pistonv = 2.07 * (ScCH4/600)**(-1/2)  !n=-1/2   pistonv unit=m/s in Wania's paper but cm/h in the code
                 pistonv = pistonv*0.01   ! convert from cm/h to m/h
              kHinv = kH_CH4 /((exp(CHinv*(1.0/(tsoil_layer(i+1)+273.15)-1.0/Tsta))))
              Ceq = Ppartial / kHinv    ! Ceq: mol L-1   p_partial: atm  kHinv：L atm mol-1
               Ceq = Ceq * 12 * 1000    ! Ceq mol/L to g/m3
          endif
! ********************************
           if (i .eq. 1 .and. jwt .ge. 1) then
!               Fdifu(i) = Deff(i)*(CH4_V(i)-CH4_atm)/(wsc(i)*0.001)
               Fdifu(i) = Deff(i)*(CH4_V(i)-CH4_atm)/(THKSL(i)*0.01)
!               write (77,*) 'Fjwt=1','Fdifu(1)',Fdifu(i),'CH4_V(1)',CH4_V(1),'CH4_atm',CH4_atm,'wsc(1)',wsc(1)
           elseif (i .eq. 1) then !.and. jwt .eq. 0
               Cold = CH4_V(i)
               CH4_V(i) = Ceq + (Cold-Ceq)*exp(-pistonv/(wsc(i)*0.001)) !pistonv/wsc m/m unit=1
!               CH4_V(i) = Ceq + (Cold-Ceq)*exp(-pistonv/(THKSL(i)*0.01))
               Fdifu(i) = (Cold-CH4_V(i))*(wsc(i)*0.001)
!               Fdifu(i) = (Cold-CH4_V(i))*(THKSL(i)*0.01)
!             write (77,*) 'Hjwt=0','Fdifu(1)',Fdifu(i),'Cold',Cold,'CH4_V(1)',CH4_V(i),'difference',(Cold-CH4_V(i))
!             write (77,*) 'Hjwt=0','Ceq',Ceq,'pistonv',pistonv,'wsc(1)',wsc(1)
           elseif (i .le. nlayers .and. i .ne. jwt+1) then
!               Fdifu(i)= Deff(i)*(CH4_V(i)-CH4_V(i-1))/(wsc(i)*0.001)
               Fdifu(i)= Deff(i)*(CH4_V(i)-CH4_V(i-1))/(THKSL(i)*0.01)
               if (i .eq. 2) then
!                  write (77,*) 'Fcalcu Fdifu(2)',Fdifu(2),'CH4_V(2)',CH4_V(2),'CH4_V(1)',CH4_V(1),'Deff(2)',Deff(2),'wsc(2)',wsc(2)
               endif
           elseif (i .le. nlayers .and. i .eq. jwt+1) then
               Cold = CH4_V(i)
               CH4_V(i) = Ceq + (Cold-Ceq)*exp(-pistonv/(wsc(i)*0.001)) !pistonv/wsc m/m unit=1
!               CH4_V(i) = Ceq + (Cold-Ceq)*exp(-pistonv/(THKSL(i)*0.01))
               Fdifu(i) = (Cold-CH4_V(i))*(wsc(i)*0.001)
!               Fdifu(i) = (Cold-CH4_V(i))*(THKSL(i)*0.01)
               if (i .eq. 2) then
!                  write (77,*) 'Hcalcu Fdifu(2)',Fdifu(2),'CH4_V(2)',CH4_V(2),'CH4_V(1)',CH4_V(1),'Deff(2)',Deff(2),'wsc(2)',wsc(2)
!                  write (77,*) 'Hcalcu Fdifu(2)','Ceq',Ceq,'pistonv',pistonv,'wsc(2)',wsc(2)
           endif
           endif

       enddo
!  !s       write (*,*) 'Fdifu(1)',Fdifu(1),'CH4_V(1)',CH4_V(1),'Deff(1)',Deff(1),'Deff(2)',Deff(2),'wsc(1)',wsc(1),'wsc(2))',wsc(2)
! ********************************
!! *******1*************************
!       do i=1,nlayers
!           if (i .eq. 1 .and. jwt .ge. 1) then
!               Fdifu(i) = Deff(i)*(CH4_V(i)-CH4_atm)/(wsc(i)*0.01)
!           elseif (i .eq. 1) then !.and. jwt .eq. 0
!               Fdifu(i) =  pistonv * (CH4_V(i) - Ceq)
!           elseif (i .le. nlayers .and. i .ne. jwt+1) then
!               Fdifu(i)= Deff(i)*(CH4_V(i)-CH4_V(i-1))/(wsc(i)*0.01)
!           elseif (i .le. nlayers .and. i .eq. jwt+1) then
!               Fdifu(i) =  pistonv * (CH4_V(i) - Ceq)
!           endif
!       enddo
!!!!! ********3************************
!      Fdifu(1) =  pistonv * (CH4_V(1) - Ceq)
!      do i = 2,nlayers                                  !refer to flux from layer ii to ii-1
!          Fdifu(i)= Deff(i)*(CH4_V(i)-CH4_V(i-1))/(wsc(i)*0.01)      !the unit of Fdifu is gC/m-2/h
!      enddo
!!! ********************************
      !below I try to keep the CH4 flux no larger than the amount of CH4 that exist at the moment   V1.1 V1.2
      do i=1,nlayers+1
!!          write (*,*) 'i',i,'CH4(i-1)',CH4(i-1)
          if (i .eq. 1) then
              if (Fdifu(i) .gt. 0.0 .and. (Fdifu(i)) .gt. CH4(i)) then
              Fdifu(i)=CH4(i)
!              elseif (Fdifu(i) .lt. 0.0) then
!              Fdifu(i)=-CH4(i-1)
              endif
          elseif (i .gt.1) then
              if (Fdifu(i) .gt. 0.0 .and. (Fdifu(i)) .gt. CH4(i)) then
                  Fdifu(i)=CH4(i)
              elseif (Fdifu(i) .lt. 0.0 .and. (abs(Fdifu(i))) .gt. CH4(i-1)) then
!              write (*,*) 'Fdifu(i)',Fdifu(i)
                  Fdifu(i)=-CH4(i-1)
!              write (*,*) 'i',i,'CH4(i-1)',CH4(i-1)
              endif

          endif
      enddo

!      CH4(1) = CH4(1) + (0.0+Fdifu(1))/(THKSL(1)*0.01)
!      do i=1,nlayers
!          CH4_V(i) = CH4(i)/(wsc(i)*0.001)
!          CH4_V(i) = CH4(i)/(THKSL(i)*0.01)
!      enddo
!      write (77,*) 'before cal with fick law','CH4_V(1)',CH4_V(1),'CH4_V(2)',CH4_V(2),'CH4_V(3)',CH4_V(3),'wsc(1)',wsc(1)
      do i = 1,nlayers-1                                  !loop of time
          CH4(i) = CH4(i) + (Fdifu(i+1)-Fdifu(i))*1 ! *1   * 1 hour /hour   /15min  *0.25h
!          CH4(i) = CH4(i) - 0.1*CH4(i)
!          write (*,*) 'before jus',CH4(1),'Fdifu(i+1)-Fdifu(i)',Fdifu(2)-Fdifu(1),'Fdifu(2)',Fdifu(2),'Fdifu(1)',Fdifu(1)
          if (CH4(i) .lt. 0.0) then                     ! this part need to be improved until deleted   V1.2
              CH4(i) = 0.0
          endif
!          if (i .eq. 1) then
!          CH4_V(i) = CH4(i)/(wsc(i)*0.001)
!          CH4_V(i) = CH4(i)/(THKSL(i)*0.01)
!              write (77,*)'in cal with fick law','CH4_V(1)',CH4_V(1),'Fdifu(1)',Fdifu(1),'Fdifu(2)',Fdifu(2),'CH4(1)',CH4(1)
!          endif
      enddo
        CH4(10) = CH4(10) - Fdifu(10)                                   !MODIFIED ON 07/25/2016
          if (CH4(10) .lt. 0.0) then                                    !defined the Fdifu(11) to be 0.0
              CH4(10)= 0.0                                              ! switch on/off
          endif
      do i=1,nlayers
!          CH4_V(i) = CH4(i)/(wsc(i)*0.001)
          CH4_V(i) = CH4(i)/(THKSL(i)*0.01)
      enddo

!      write (77,*) 'after cal with fick law','CH4_V(1)',CH4_V(1),'CH4_V(2)',CH4_V(2),'CH4_V(3)',CH4_V(3)
!      write (77,*) 'afterdif simuCH4',simuCH4,'(1)',CH4_V(1),'(2)',CH4_V(2),'(3)',CH4_V(3),'(4)',CH4_V(4),'(5)',CH4_V(5)
!      write (77,*) '(6)',CH4_V(6),'(7)',CH4_V(7),'(8)',CH4_V(8),'(9)',CH4_V(9),'(10)',CH4_V(10)
      simuCH4 = simuCH4 + Fdifu(1)
!      write (*,*) 'after difu CH4(123)', CH4(1),CH4(2),CH4(3)
!     ********************************************************************************************************************
    ! D. methane ebullition     !assume bubbles can reach the water table within 1 h&
                                !& the bubbles is added to the methane concentration in the soil layer just above the wt
                                !& and then diffused through layers
                                !mechanisms selectable: ECT (concentration threshold) and EBG (bubble growth)
                                !EBG is added as a subroutine on Nov 26th 2018, so that minimum changes to the original code
          Ebu_sum_unsat=0.0
          Ebu_sum_sat=0.0                                      !initial value
          Ebu_sum = 0.0

          rouwater = 1000.   !kg/m3
          g = 9.81; ! m/s2
          Rgas = 8.3145; ! m3 Pa/K/mol

      if (do_EBG) then
!          GOTO 170
!          write (*,*) 'before EBG CH4(5)', CH4(5)
          call ebullition_EBG(CH4,CH4_V,simuCH4,zwt,dpatm,tsoil_layer,wsc,THKSL,depth,  &
                & rouwater,g,Rgas,f,Nbub,bubprob,Vmaxfraction,methanebP,methaneP,  &
                & presP,pwater,Vp,bubble_methane_tot,Ebu_sum,Ebu_sum_sat,Ebu_sum_unsat,mebu_out2)
!          write (*,*) "end of EBG CH4(5)", CH4(5)
          else
          !use ECT mechanisms for ebullition
!     ********************************************************************************************************************
! ECT, by default
! this subroutine is modified on 02132017 by deleting the unsat from bubble and add unsat to
              !concentration so as to increase diffusion
! just by searching "switch" you can switch from old to new mode by adding or deleting "!"
! modified threshold value to 100 for testing
!     ********************************************************************************************************************
          Kebu=1.0                    !unit  h-1   rate constant

      do i=1,nlayers
          V = 0.05708 - 0.001545*MAX(0.0, tsoil_layer(i+1)) + 0.00002069*(MAX(0.0, tsoil_layer(i+1)))**2 ![m3 CH4 m-3 H2O in soil]
!          V = 0.05708 - 0.001545*tsoil_layer(i+1) + 0.00002069*tsoil_layer(i+1)**2  ![m3 CH4 m-3 H2O in soil]
!    **************************************************************************************************************************
!              pwater = rouwater*g*(wsc(i)*0.001)    !kg/m3    convert wsc from % to m
!    ******   water height not correct, change to this:
          if (depth(i) .le. (-zwt)*0.1) then
              pwater(i) = rouwater*g*(depth(i)*0.01-(-zwt)*0.001)   ![kg m s-2 or N], pwater/m2 = N/m2 = Pa
          else
              pwater(i) = 0.
          endif
!    **************************************************************************************************************************
          CH4_thre = ((dpatm + pwater(i))*V/(Rgas*(tsoil_layer(i+1)+273.15)))*1000!-200  ! mol CH4 /m3 to mmol CH4 /m3
!                  CH4_thre=700.0  !!find in parafile  !unit  umol L-1 according to Walter's 500-1000
          CH4_thre_ly(i)=(CH4_thre*1.0e-6)*12*1000*(wsc(i)*0.001)    !convert the unit of CH4_thre from µmol L-1 to gC m-2
          if (CH4_thre .lt. 1300.) then
!              write (*,*) CH4_thre
          endif
!          if (CH4_thre .lt. 1200) then
!          write (*,*) 'i',i,'CH4_thre',CH4_thre,'dpatm',dpatm,'wsc',wsc(i)*0.001,'tsoil_layer(i+1)',tsoil_layer(i+1)
!          endif
      enddo

!      write (*,*) 'before ebu CH4(123)', CH4(1),CH4(2),CH4(3)
      if (zwt .ge. 0.0) then                                  !when water table is above the soil surface
          do i=1,nlayers
              if (CH4(i) .gt. CH4_thre_ly(i)) then
                      EbuCH4(i)=Kebu*(CH4(i)-CH4_thre_ly(i))     !only if the concentration is larger than threshold
              else !if (CH4(i) .le. CH4_thre_ly(i)) then
                      EbuCH4(i)=0.0
              endif
              Ebu_sum_sat=Ebu_sum_sat+EbuCH4(i)               !& the bubbles are directly added into CH4 efflux into atmosphere
              CH4(i)=CH4(i)- EbuCH4(i)                        !& update the concentration at the end of this hour in each layers
          enddo
      endif
!      write (*,*) CH4(1),CH4_thre_ly(1),EbuCH4(1),Ebu_sum_sat
!
      if (zwt .lt. 0.0) then                                  !when water table is below the soil surface
        do i=1,nlayers
            if ((depth(i)*10.0) .le. -zwt) then               !acrotelm layers
                EbuCH4(i)=0.0
                Ebu_sum_unsat=Ebu_sum_unsat+EbuCH4(i)
                CH4(i)=CH4(i)- EbuCH4(i)
            else
                if (((depth(i)*10.0)-(THKSL(i)*10.0)) .le. -zwt) then       !partly acrotelm layer
                    wtlevelindex = i
                    if (CH4(i) .gt. CH4_thre_ly(i)) then
                      EbuCH4(i)=Kebu*(CH4(i)-CH4_thre_ly(i))!*(((depth(i)*10.0)-(-zwt))/(THKSL(i)*10.0))        ! * percent
                    else !if (CH4(i) .le. CH4_thre_ly(i)) then                     ??????????,??????????????????
                      EbuCH4(i)=0.0
                    endif
                  CH4(i)=CH4(i)- EbuCH4(i)

                  Ebu_sum_unsat=Ebu_sum_unsat+EbuCH4(i)                ! !  modified by Mary on 02132017
                  CH4(wtlevelindex-1)=CH4(wtlevelindex-1)+EbuCH4(i)    !!!!!-1-!!!! !switch on in new mode should be added
                  !add burst bubbles below surface to diffusion modified by Mary on 02132017
                 ! the problem is the resolution of soil layer is 10cm and EbuCH4(i) is directly added to the upper layer
                  !of boundary layer   02152017

                else if (((depth(i)*10.0)-(THKSL(i)*10.0)) .ge. -zwt) then   !catotelm layers
                    if (CH4(i) .gt. CH4_thre_ly(i)) then
                      EbuCH4(i)=Kebu*(CH4(i)-CH4_thre_ly(i))
                    else !if (CH4(i) .le. CH4_thre_ly(i)) then
                      EbuCH4(i)=0.0
                    endif
                  CH4(i)=CH4(i)- EbuCH4(i)

!                  wtlevelindex equal to the last layer (wt layer)) that give a value to it, in all the layers below the wt layer
                  CH4(wtlevelindex-1)=CH4(wtlevelindex-1)+EbuCH4(i)     !!!!!-2-!!!! !switch on in new mode should be added
                  !modified by Mary on 02152017
                  Ebu_sum_unsat=Ebu_sum_unsat+EbuCH4(i)                  ! modified by Mary on 02132017

                endif
            endif
        enddo
      endif
    !      write (*,*) 'after ebu CH4(123)', CH4(1),CH4(2),CH4(3)
            Ebu_sum= Ebu_sum_sat
            simuCH4=simuCH4+Ebu_sum_sat                         !& the bubbles are directly added into CH4 efflux into atmosphere
    !    write (*,*) Ebu_sum
            ! ********************************
!       if (zwt .ge. -100) then   !index j, water table is right below the jth layer
!           mwt=0.
!       elseif (zwt .ge. -500.0) then  !layer 1-5
!!           jwt=int(-zwt/100)-1
!                mwt=int(-zwt/100)+1
!       else
!!           jwt=int((-zwt-500)/200+5)-1
!           mwt=int((-zwt-500)/200+5)+1
!       endif

      endif
!     ******************************************************************************************************
    ! E. plant mediated methane transportation      totoally used Walter's model also used by Zhuang et. al
!     ******************************************************************************************************
170   continue
        Kpla=0.01         !unit h-1
!      Kpla=0.01         !unit h-1
!      Tveg=0.3 ! a factor describing the quality of plant-mediated transport depend on the density of plant stands and plant types
!      0 for boreal forest and 0.5 for tundra
      !find in parafile !
    ! the Tsoil used here would be better if refer to the 20cm soil temperature after &
    ! & the accomplishment of soil heat dynamics module. according to Zhuang. however Walter used 50cm soil temp.
      Tgr=2.0               !unit degree Celsius if annual mean temp is below 5 (otherwise 7)
      Tmat=Tgr+10.0         !unit degree Celsius
      Pox=0.5               !50% of mediated methane are oxidised
    ! define fgrow
      if (.not. do_soilphy) then
          if (Tsoil .lt. Tgr) then
              fgrow=LAIMIN
          else if (Tsoil .ge. Tgr .and. Tsoil .le. Tmat) then
    !          fgrow=LAIMIN+(LAIMAX+2)*(1-((Tmat-Tsoil)/(Tmat-Tgr))**2)
              fgrow=LAIMIN+(LAIMAX)*(1-((Tmat-Tsoil)/(Tmat-Tgr))**2)
          else if (Tsoil .gt. Tmat) then
    !          fgrow=LAIMAX+2
              fgrow=LAIMAX
          endif
      else
          if (tsoil_layer(3) .lt. Tgr) then
              fgrow=LAIMIN
          else if (tsoil_layer(3) .ge. Tgr .and. tsoil_layer(3) .le. Tmat) then
    !          fgrow=LAIMIN+(LAIMAX+2)*(1-((Tmat-Tsoil)/(Tmat-Tgr))**2)
              fgrow=LAIMIN+(LAIMAX)*(1-((Tmat-tsoil_layer(3))/(Tmat-Tgr))**2)
!              WRITE (*,*) 'fgrow',fgrow,'LAIMIN',LAIMIN
          else if (tsoil_layer(3) .gt. Tmat) then
    !          fgrow=LAIMAX+2
              fgrow=LAIMAX
          endif
      endif
!      write (*,*) 'before pmt CH4(123)', CH4(1),CH4(2),CH4(3),'Tsoil',Tsoil,'tsoil_layer(2)',tsoil_layer(2),'Tgr',Tgr,'Tmat',Tmat
      Pla_sum=0.0
	Pla_consum=0.0
      do i=1,nlayers
          PlaCH4(i)=Kpla*Tveg*FRLEN_PMT(i)*fgrow*CH4(i)*(1-Pox)
!          PlaCH4(i)=Kpla*Tveg*FRLEN(i)*fgrow*CH4(i)
!          write (*,*) 'i',i,'PlaCH4',PlaCH4(i),'fgrow',fgrow,'LAIMIN',LAIMIN,'LAIMAX',LAIMAX+2
          Pla_sum=Pla_sum+PlaCH4(i)
	Pla_consum=Pla_consum+Kpla*Tveg*FRLEN_PMT(i)*fgrow*CH4(i)*Pox
!          CH4(i)=CH4(i)-PlaCH4(i)
          CH4(i)=CH4(i)-Kpla*Tveg*FRLEN_PMT(i)*fgrow*CH4(i)!PlaCH4(i)/(1-Pox)

!          CH4_V(i) = CH4(i)/(wsc(i)*0.001)
          CH4_V(i) = CH4(i)/(THKSL(i)*0.01)         !convert concentration from gC/m2 to gC/m3
!           write (77,*) 'in PMT i',i,'CH4(i)',CH4(i),'CH4_V(i)',CH4_V(i)
      enddo
!      write (77,*) 'afterPMT simuCH4',simuCH4,'(1)',CH4_V(1),'(2)',CH4_V(2),'(3)',CH4_V(3),'(4)',CH4_V(4),'(5)',CH4_V(5)
!      write (77,*) '(6)',CH4_V(6),'(7)',CH4_V(7),'(8)',CH4_V(8),'(9)',CH4_V(9),'(10)',CH4_V(10)
!      consum=simuCH4+OxiCH4(1)+OxiCH4(2)+OxiCH4(3)+OxiCH4(4)+OxiCH4(5)+OxiCH4(6)+OxiCH4(7)+OxiCH4(8)+OxiCH4(9)+OxiCH4(10)
      simuCH4=simuCH4+Pla_sum

!     calculate carbon balance, -produced CH4+oxidized CH4
      Rh_h_new = Rh_h-Pro_sum+Oxi_sum+Pla_consum
	! write (*,*) 'Pro_sum',Pro_sum,'Oxi_sum',Oxi_sum,'Pla_consum',Pla_consum





      do i=1,5  !update Rh_pools(i) and then transfer out of the methane subroutine
          Rh_pools(i)=Rh_h_new*(Rh_pools(i)/Rh_h)
      enddo


! !      if (MEMCMC .eq. 0) then
    ! if (.not. do_da) then
        ! if (.not. do_methane_fcast) then
! !        write (*,*) 'zwt',zwt
            ! write (83,283) zwt,testout(11),Rh_pools(1),Rh_pools(2),Rh_pools(3),Rh_pools(4),Rh_pools(5), &
              ! & wsc(1),wsc(2),wsc(3),wsc(4),wsc(5),wsc(6),wsc(7),wsc(8),wsc(9),wsc(10),  &
              ! & testout(2),testout(3),testout(4),testout(5),testout(6),testout(7),testout(8),  &
              ! & testout(9),testout(10),testout(1),dpatm,LAIMAX

! !        else
! !            write(83,183)zwt,Tsoil,Rh_pools(1),Rh_pools(2),Rh_pools(3),Rh_pools(4),Rh_pools(5), &
! !              & wsc(1),wsc(2),wsc(3),wsc(4),wsc(5),wsc(6),wsc(7),wsc(8),wsc(9),wsc(10)
! !        endif
! !183   format(17(f15.9,","))
! 283   format(29(f15.9,","))
        ! endif
    ! endif
!      !write(*,*) 'zwt',zwt,'simuCH4',simuCH4         !show on screen
! ***********     write out hourly value for methane module
!    if (do_EBG) then
!      write(82,182)zwt,simuCH4,Pro_sum,Pla_sum,Ebu_sum_sat,Ebu_sum_unsat,Fdifu(1), &
!              & Rh(1),Rh(2),Rh(3),Rh(4),Rh(5),Rh(6),Rh(7),Rh(8),Rh(9),Rh(10),   &
!              & ProCH4(1),ProCH4(2),ProCH4(3),ProCH4(4),ProCH4(5),ProCH4(6),ProCH4(7),ProCH4(8),ProCH4(9),ProCH4(10),   &
!              & PlaCH4(1),PlaCH4(2),PlaCH4(3),PlaCH4(4),PlaCH4(5),PlaCH4(6),PlaCH4(7),PlaCH4(8),PlaCH4(9),PlaCH4(10),   &
!              & mebu_out2(1),mebu_out2(2),mebu_out2(3),mebu_out2(4),mebu_out2(5),mebu_out2(6),mebu_out2(7),mebu_out2(8),&
!              & mebu_out2(9),mebu_out2(10), &
!              & Fdifu(1),Fdifu(2),Fdifu(3),Fdifu(4),Fdifu(5),Fdifu(6),Fdifu(7),Fdifu(8),Fdifu(9),Fdifu(10), &
!              & CH4(1),CH4(2),CH4(3),CH4(4),CH4(5),CH4(6),CH4(7),CH4(8),CH4(9),CH4(10), &
!              & CH4_V(1),CH4_V(2),CH4_V(3),CH4_V(4),CH4_V(5),CH4_V(6),CH4_V(7),CH4_V(8),CH4_V(9),CH4_V(10), &
!              & OxiCH4(1),OxiCH4(2),OxiCH4(3),OxiCH4(4),OxiCH4(5),OxiCH4(6),OxiCH4(7),OxiCH4(8),OxiCH4(9),OxiCH4(10)!,   &
!!              & wsc(1),wsc(2),wsc(3),wsc(4),wsc(5),wsc(6),wsc(7),wsc(8),wsc(9),wsc(10), &
!!              & Rh_pools(1),Rh_pools(2),Rh_pools(3),Rh_pools(4),Tsoil
!
!    else
!      write(82,182)zwt,simuCH4,Pro_sum,Pla_sum,Ebu_sum_sat,Ebu_sum_unsat,Fdifu(1), &
!              & Rh(1),Rh(2),Rh(3),Rh(4),Rh(5),Rh(6),Rh(7),Rh(8),Rh(9),Rh(10),   &
!              & ProCH4(1),ProCH4(2),ProCH4(3),ProCH4(4),ProCH4(5),ProCH4(6),ProCH4(7),ProCH4(8),ProCH4(9),ProCH4(10),   &
!              & PlaCH4(1),PlaCH4(2),PlaCH4(3),PlaCH4(4),PlaCH4(5),PlaCH4(6),PlaCH4(7),PlaCH4(8),PlaCH4(9),PlaCH4(10),   &
!              & EbuCH4(1),EbuCH4(2),EbuCH4(3),EbuCH4(4),EbuCH4(5),EbuCH4(6),EbuCH4(7),EbuCH4(8),EbuCH4(9),EbuCH4(10), &
!              & Fdifu(1),Fdifu(2),Fdifu(3),Fdifu(4),Fdifu(5),Fdifu(6),Fdifu(7),Fdifu(8),Fdifu(9),Fdifu(10), &
!              & CH4(1),CH4(2),CH4(3),CH4(4),CH4(5),CH4(6),CH4(7),CH4(8),CH4(9),CH4(10), &
!              & CH4_V(1),CH4_V(2),CH4_V(3),CH4_V(4),CH4_V(5),CH4_V(6),CH4_V(7),CH4_V(8),CH4_V(9),CH4_V(10), &
!              & OxiCH4(1),OxiCH4(2),OxiCH4(3),OxiCH4(4),OxiCH4(5),OxiCH4(6),OxiCH4(7),OxiCH4(8),OxiCH4(9),OxiCH4(10)!,   &
!!              & wsc(1),wsc(2),wsc(3),wsc(4),wsc(5),wsc(6),wsc(7),wsc(8),wsc(9),wsc(10), &
!!              & Rh_pools(1),Rh_pools(2),Rh_pools(3),Rh_pools(4),Tsoil
!
!182   format(87(f15.9,","))
!    endif
!      endif
!
! ***********     write out hourly value for methane module
      return
      end

!   *************************************************************************************
!   subroutine EBG used by methane submodel
subroutine ebullition_EBG(CH4,CH4_V,simuCH4,zwt,dpatm,tsoil_layer,wsc,THKSL,depth,  &
                & rouwater,g,Rgas,f,Nbub,bubprob,Vmaxfraction,methanebP,methaneP,  &
                & presP,pwater,Vp,bubble_methane_tot,Ebu_sum,Ebu_sum_sat,Ebu_sum_unsat,mebu_out2)
! INPUT:
!		CH4 = porewater methane in the whole layer, unit=gC/m2, size=nlayers,CH4_V(i) = CH4(i)/(wsc(i)*0.001)
!		CH4_V(nlayers) = porewater methane concentration, unit=gC/m3, size=nlayers,CH4_V(i) = CH4(i)/(wsc(i)*0.001)
!		simuCH4 = methane efflux, added up with diffusion, ebullition, and PMT
!		nlayers = number of layers, 10 by default
!		zwt = water table level, unit = mm, size=1, below surface when zwt<0
!		dpatm = atm pressure, input from the atmospheric forcing file, unit=Pa, estimated value from CNCEPT, used by CLM
!		tsoil_layer = soil temperature of different layers, unit=Celsius, size = nlayers
!       wsc = volumetric content of soil water in a layer, unit=mm, size = nlayers
!		THKSL = thickness of the (i)th soil layer in the model, unit=cm, size = nlayers
!     	depth = depth of the (i)th soil layer, unit=cm, size = nlayers
!		rouwater = density of water, 1000. kg/m3
!		g = 9.81 ! m/s2
!		Rgas = 8.3145 ! m3 Pa/K/mol
!OUTPUT:
!		Ebu_sum = sum of ebullited methane finally get into the atm, size = 1,unit=gC/m2
!		EbuCH4(nlayers) = ebullited methane each time step from one layer, size = nlayers,unit=gC/m2
!		Ebu_sum_sat = ebullited methane each time step from one layer when water table is higher than soil surface, added
                !up to calculate Ebu_sum
!		Ebu_sum_unsat = ebullited methane each time step from one layer when water table is below the soil surface, add to
                !CH4 and diffused up

        implicit none
        integer i,mwt,ind
        ! INPUT parameters:
        real rouwater,g,Rgas
        integer, parameter :: nlayers=10
        real CH4(nlayers),CH4_V(nlayers),simuCH4,zwt,dpatm,tsoil_layer(11),wsc(nlayers),THKSL(nlayers),depth(nlayers)
        ! OUTPUT parameters:
        real Ebu_sum,Ebu_sum_sat,Ebu_sum_unsat,EbuCH4(nlayers)
        ! INTERNAL parameters:
        !  		! xP: amount of x in each layer [mol], really [mol] not [mol m-3]
        real Vp(nlayers),Vtmp(nlayers)	!total volume of the bubbles in a layer, size(nlayers), unit m3/layer
        real methanebP(nlayers) !amount of CH4 moles in bubbles, size(nlayers), unit mol/layer, not concentration, not m-3
        real methaneP(nlayers)  !amount of CH4 moles in porewater, size (nlayers), unit mol/layer  CH4(i) gC/layer
        real mrateP(nlayers)	!The rate at which gas transfer with bubbles modifies gas at each layer, [mol s-1 layer-1]
        real met_db(nlayers)	!calculated in the exceeded bubble module, pore water CH4 concentration change rate due to
        !interaction with bubbles, unit = mol hr-1, size=nz
        real mCwP				!CH4 molar density in the water (mol m-3), size=1


        real dc
        real Dw,Hcp,mebu_out,r,randbub
        real, parameter :: peat_coeff_w = 0.9
        real, parameter :: Dw_298 = 1.5e-9 ! [m2 s-1]
        real mnv! CH4 molar density in the bubble (mol m-3)           ! Shuang mnv=cb in their paper

        real bubble_methane_tot	!amount of CH4 stored in bubbles
        real mebu_rate_out      !pore water CH4 concentration change rate due to interaction with bubbles, unit = mol s-1, size=nz
        real mebu_out2(nlayers) ! ebullition from the layers are temporarily saved here
        real Vout		! in the equation 8), the exceeded volume of methane in bubbles
        real nout		!nout = Febu in equation 8) EBG, unit mol. = bubble conc * volume
        !real gases_out(2)  !1 for ebu into air, 2 for ebu into the lowest air layer
        real presP(nlayers) ! total pressure of air and water in layers
        real pwater(nlayers)! water pressure in layers
        real tempP(nlayers)  ! Kalvin soil temperature
        real met_alphaP(nlayers) !methane solubility
        real a,b,c  !constants used to calculate methane solubility
        ! half-life of supersaturated dissolved methane
        !integer, parameter :: dp = selected_real_kind(15, 300)
        real, parameter :: ebu_hl = 1800. ! 30 minutes, 1800 s
        real, parameter :: k = log(2.0)/ebu_hl  ! turnover rate s-1
        real, parameter :: pi = 3.141592653589793
!          !  1 = methane ebullition into air
!          !  2 = methane ebullition total (when WTD is below peat surface, ebullition is
!          !      released in the lowest air layer inside peat)
!        integer, parameter :: mebuair = 1, mebutot = 2
        !*******************
        ! input parameters
        !*******************

        real f !threshold fraction of pore space filled with gas bubbles needed for ebullition or
                                ! CH4 mixing ratio in bubbles (mol mol-1)
        real Nbub ! Amount of bubbles in one model layer. This directly impacts the CH4 exchange
                                ! rate between pore water and bubbles
        real Vmaxfraction ! Maximum fraction of volume occupied by bubbles (10 %)
                                                        ! If this is exceeded, then the extra volume is released
        real bubprob ! probability that a bubble will get stuck at one layer
        !********************************************************************************


!******************************************************************************
!******************************************************************************
! inside the time loop starts here, add to methane module
!******************************************************************************

!****  #2. add mwt as index for the wt layer  *************
       if (zwt .ge. -100) then   !index mwt, water table is right at the mwt th layer
           mwt=1.
       elseif (zwt .ge. -500.0) then  !layer 1-5
           mwt=int(-zwt/100)+1
       else
           mwt=int((-zwt-500)/200+5)+1
           if (mwt .gt. 10) then         !sm
               mwt = 10.
       endif
       endif
!       if (zwt .le. -100.) then
!           write (*,*) 'mwt',mwt,'zwt',zwt
!       endif
!****  #2. end of mwt as index for the wt layer  *************


!****  #3. update value, might not be necessary
    do i=1,nlayers

	methaneP(i) = CH4(i)/12		!##need to make sure CH4 is updated at the end of EBG
!				  gC/layer  /12   unit molC/layer
	tempP(i) = tsoil_layer(i+1)+273.15 !unit Kelvin

	if (i .ge. mwt) then
            pwater(i) = rouwater*g*(depth(i)*0.01-(-zwt)*0.001)
        else
            pwater(i)  = 0.
        endif
	presP(i) = dpatm + pwater(i)  ! unit Pa

	Vp(i) = methanebP(i) * Rgas * tempP(i)/(presP(i) * f)  !Vp is updated since methanebP is updated in the middle of the EBG
!******************************************************************************
!        write (*,*) 'Vp update1', Vp(i)

!*******#4. bubble_methane_tot, bubble_methane_tot is accumulated total of all the 10 layers,
                !I assume air peat layer Vp=0, yes that's right ****
!amount of CH4 stored in bubbles   !Shuang this is equation (10), update number of CH4 in bubbles
!bubble_methane_tot = sum(f * presP(i)/(Rgas * (tsoil_layer(i+1)+273.15)) * Vp)
        bubble_methane_tot = bubble_methane_tot+f * presP(i)/(Rgas * tempP(i)) * Vp(i)
!
!******************************************************************************


!*******#5. methane_solubility (alpha) ****************************************
!calculate methane_solubility (alpha) using tempP,a,b,c,Rgas and Hcp
!alpha: unit [mol(CH4,water) m(water)-3 mol(CH4,air)-1 m(air)3]
!Hcp: unit [mol(CH4) m(H2O)-3 Pa-1]
!Rgas = 8.3144621_dp ! [J mol-1 K-1]
	a = 1.3e-3
	b = 1700.
	c = 298.0
    ! Tang et al. 2010, eq. A4
    ! see also
        Hcp = a * exp(b * (1./tempP(i) - 1./c)) * 9.86923266716e-3
        met_alphaP(i) = Rgas * tempP(i) * Hcp
!            write (*,*) 'i',i,'methaneP(i)',methaneP(i),'CH4(i)',CH4(i),'methanebP(i)',methanebP(i)
    enddo
!******************************************************************************
!    gases_out = 0
    mebu_rate_out = 0
!*******#6. *******************************************************************
! methane_to_bubble - Transferring CH4 between bubbles and the surrounding pore water
! input
     ! INPUT:
     !       presP = pressure vector, unit=Pa, size=nz
     !       tempP = pore water temperature vector, unit=K, size=nz
     !       methaneP = CH4 pore water concentration vector, unit=mol/layer, size=nz
     !       met_alphaP = CH4 solubility (dimensionless Henry solubility) vector, unit=-, size=nz
     !       nz = amount of model layers, size=1
     !       geom = model geometry
     !       por = peat porosity, unitless, size=1
     !       Vp = bubble volume vector, unit=m3, size=nz
     ! OUTPUT:
     !       mrateP = mebu_rateP = methane_d = met_d = pore water CH4 concentration change rate due to interaction with bubbles,
             !unit = mol s-1, size=nz
!   grows (and shrinks) bubbles in each layer based on Henry's law
!  equation 6
!    write (*,*) "1 stopping point"
    mrateP = 0
!! if layers with water peat mixture exist
    do i = mwt,nlayers
! CH4 molar density in the water (mol m-3)
        mCwP = methaneP(i) / ((wsc(i)*0.001)*1);
! concentration difference between pore water and bubble surface
        dc = (mCwP - met_alphaP(i) * f * presP(i)/(Rgas * tempP(i))) !  Shuang this is part 2 of equation (5)
!        mol m-3
!        write (*,*) 'dc i',i,'mCwP',mCwP,'methaneP(i))',methaneP(i)

        if (Vp(i) == 0) then										!Shuang equation (6)
          ! creating a bubble from the excess CH4
          if (dc > 0) then
            ! making sure that CH4 exchange FROM bubble TO water does not exist when there is no bubble
            mrateP(i) = -k * dc * ((wsc(i)*0.001)*1)
!            write (*,*) 'Vp=0, dc>0 i',i, 'mrateP(i)',mrateP(i)
            !(geom % dzP(i) * por) thickness of the layer * porosity (*1 m2) = water volume
!			mol s-1		s-1	 mol m-3	m3
            !when mrateP is negative it means transfer from water to bubble
          end if
          !"Nbub" no need to consider Nbub because mrateP is already the total exchange amount

        else
          ! growing the bubble only if it already exists

          ! radius of one bubble (m)
          r = (3.0/4.0 * Vp(i)/Nbub/pi)**(1.0/3.0)		! r updated with Vp, calculated from the last time step in EBG

          ! CH4 diffusion coefficient in water & peat mixture
!          Dw = methane_D_water(tempP(i)) !this function outputs Dw
!

        Dw = peat_coeff_w * Dw_298 * (tempP(i)/298.)
    ! if (temperature < 273.15) Dw = 0

          ! change in pore water CH4 due to mass transfer with one bubble   !Shuang part of equation (5)
          mrateP(i) = -4.0 * pi * r * Dw * dc
!          write (*,*) 'mrateP(i)',mrateP(i),'r',r,'dc',dc
!            write (*,*) 'Vp/=0 i',i, 'mrateP(i)',mrateP(i)
          ! Nbub bubbles
          mrateP(i) = mrateP(i) * Nbub			!mol s-1
        end if
! ***** end of #6. methane_to_bubble output is mrateP = mebu_rateP = methane_d=met_d
!******************************************************************************

!        write (*,*) '6 i',i,'methaneP(i)',methaneP(i),'CH4(i)',CH4(i),'methanebP(i)',methanebP(i),'mrateP(i)',mrateP(i)
!******************************************************************************
! ***** #7. now we are calculating methanebP, amount of CH4 moles in bubbles, size(nlayers), unit mol
! removing/adding the same amount of CH4 to the bubbles that was added/removed
			! to the pore water due to interaction with the bubbles
!        write (*,*) '7 i',i,'Vp update2', Vp(i),'methanebP(i)',methanebP(i),'mrateP(i)',mrateP(i),'r',r,'dc',dc
	methanebP(i) = methanebP(i) - 3600 * mrateP(i) ! %% the unit of mrateP is mol s-1  %%%%%%%%%%%
!								s in a hr   mol/s       because the model time step is a hour
!										        bubble to water when mrateP is positive
!        write (*,*) 'i',i,'methaneP(i)',methaneP(i),'methanebP(i)',methanebP(i),'mrateP(i)',mrateP(i)
        ! making sure that the concentrations do not go negative
        if (methanebP(i) < 0) then
          methaneP(i) = methaneP(i) + methanebP(i)
          methanebP(i) = 0
        end if
!        write (*,*) '+bub i',i,'methaneP(i)',methaneP(i),'mrateP(i)',mrateP(i)
! *****************************************************************************
! updating bubble volumes
	Vp(i) = methanebP(i) * Rgas * tempP(i)/(presP(i) * f)
! *****************************************************************************
!        write (*,*) 'i',i,'Vp update2', Vp(i),'methanebP(i)',methanebP(i)

! ***** #8. *********************************************************************
! pore water CH4 concentration change rate due to interaction with bubbles    negative mrateP: lost methane from water to bubbles
        methaneP(i) = methaneP(i) + 3600 * mrateP(i)		! %%%%%%%%%%%%%%%%%%%%%%
!        write (*,*) '+mrateP i',i,'methaneP(i)',methaneP(i),'mrateP(i)',mrateP(i)
        mebu_rate_out = mebu_rate_out + 3600 * mrateP(i)	! total of all the layers
!mebu_rate_out=pore water CH4 concentration change rate due to interaction with bubbles, unit = mol s-1, size=nz

      ! change rate of pore water CH4 due to exchange with bubble
        mebu_rate_out = mebu_rate_out/1  !1 hr for big_dt... it is only an output
		!written as mebu_rate_out in the bigstep module, changed to mebu_rateP, but never used, just an output
! *****************************************************************************
    enddo
!    write (*,*) "2 stopping point"
! *****************************************************************************
! releasing part of the gas volume if it exceeds certain size
 ! INPUT:
     !       Vp = bubble volume vector, unit=m3, size=nz
     !       presP = pressure vector, unit=Pa, size=nz
     !       tempP = pore water temperature vector, unit=K, size=nz
     !       geom = model geometry
     !       por = peat porosity, unitless, size=1
     !       dt = model time step, unit=s,size=1
     !       nz = amount of model layers, size=1
     !       methanebP = CH4 bubble concentration vector, unit=mol, size=nz
     ! OUTPUT:
     !       met_db = pore water CH4 concentration change rate due to interaction with bubbles, unit = mol hr-1, size=nz
     !       mebu_out = CH4 released in bubbles to deepest air layer, unit = mol hr-1, size=1

 ! If bubble in a certain layer grows larger than Vmax then it is transported to the deepest air layer
     ! Currently considers only CH4
      do i = 1,nlayers
         met_db(i) = 0	!met_db: due to bubble
             mebu_out = 0	!mebu_out: one dimension
         mebu_out2(i) = 0;    ! mebu_out2 = ebullition from the layers are temporarily saved here
         Vtmp(i) = Vp(i)
      enddo

 ! layers with water peat mixture exist
       ! looping from bottom to top layer of water-peat mix
      do i = 10, mwt, -1
         ! CH4 molar density in the bubble (mol m-3)           ! Shuang mnv=cb in their paper
        mnV = f * presP(i)/(Rgas * tempP(i))
					!! 		 CH4 molar density in the water (mol m-3)
					!        mCwP = methaneP(i) / ((wsc(i)*0.001)*1);
					!	     methanebP(i) = f * presP(i) * Vp/(Rgas * tempP(i))  !unit mol/layer

         ! releasing the bubble if it exceeds certain size   ! threshold Vmax
!        write (*,*) 'i',i,'Vtmp(i)',Vtmp(i),'Vmaxfraction', Vmaxfraction,'wsc(i)',wsc(i)
        if ((Vtmp(i) - Vmaxfraction * (wsc(i)*0.001)*1) > 1e-11) then

           ! bubble was released

 !Equation 8)
          Vout = Vtmp(i) - Vmaxfraction * ((wsc(i)*0.001)*1)
          Vtmp(i) = Vmaxfraction * ((wsc(i)*0.001)*1)

! the size of the bubble increases as it ascends, but the amount of moles in the bubble stay the same
          nout = mnV * Vout                             ! Shuang nout=Febu in the paper, unit mol, mnV=cb, Vout=the rest
          methanebP(i) = methanebP(i) - nout
!          write (*,*) 'mnV * Vout  i',i,'mnV',mnV,'Vout',Vout,'nout',nout
!***** this is 'if bubble got stuck loop'
          ind = i
          do while (Vout > 0 .AND. ind >= mwt + 1)
            ind = ind - 1

            call RANDOM_NUMBER(randbub)
!            write (*,*) 'randbub',randbub
            if (randbub <= bubprob) then
                ! bubble got stuck, and bubble is added back to the upper i-1 layer
              methanebP(ind) = methanebP(ind) + nout
              Vtmp(ind) = methanebP(ind) * Rgas * tempP(ind)/(f * presP(ind))

              Vout = 0
              nout = 0
            end if

          end do

! bubble did not get stuck => it is released to the lowest air layer
! This 'if' loop and the 'do while' loop is either or, Vout will be 0 if the do while loop worked
          if (Vout > 0) then
            mebu_out2(i) = nout/1	!dt  here I assign 1 hour

          end if
!     write (*,*) 'Vout > 0  i',i,'Vout',Vout,'mebu_out2(i)',mebu_out2(i)
        end if
!        write (*,*) 'i',i,'Vout',Vout,'mnV',mnV,'nout',nout
      end do   !end of do i = 10, 2, -1
!     write (*,*) "3 stopping point"


! updating the bubble volume profile
      Vp = Vtmp
    ! a1: First box of peat-air. If 0, there is no peat-air, a2 has no meaning.
    ! a2: Last box of peat-air.
    ! w1: First box of peat-water. If 0, no peat-water, w2 has no meaning.
    ! w2: Last box of peat-water.
      if (mwt .gt. 1) then! if air-peat layer is present
        met_db(mwt-1) = sum(mebu_out2) ! bubbles released to deepest air layer, sum of all the water layers
         ! ebu_out is already 0, no need to set again
      else			      ! if all layers are flooded, porewater CH4 was already updated
        mebu_out = sum(mebu_out2);
!        write (*,*) 'mwt mebu_out',mebu_out,mebu_out2
      end if

! end of releasing part of the gas volume if it exceeds certain size
! *****************************************************************************


! *****************************************************************************
    do i = 1,nlayers
        ! bubbles are released to the lowest air layer if wtd is below surface
        !   if wtd is above surfacr all the met_db(i)=0
        methaneP(i) = methaneP(i) + 1 * met_db(i) !big_dt replaced with 1hr  %%%%%%%%%%%% need to edit: add to with layer
!        write (*,*) '+db i',i,'methaneP(i)',methaneP(i)
    !     methaneP = methaneP + 1 * met_db

    !  integer, parameter :: mebuair = 1, mebutot = 2
    !  1 = methane ebullition into air
    !  2 = methane ebullition total (when WTD is below peat surface, ebullition is
    !      released in the lowest air layer inside peat)

        ! for output
            CH4(i)=12*methaneP(i)
!            CH4_V(i)=CH4(i)/(wsc(i)*0.001)
          CH4_V(i) = CH4(i)/(THKSL(i)*0.01)
    enddo
    ! mebu_out and met_db are larger than 0. the amount of CH4 gets out
    ! amount of CH4 released to the atmosphere  !%%%% I changed gases_out_bigstep into gases_out=Ebu_sum_unsat  sat
    Ebu_sum_sat = Ebu_sum_sat + (1 * mebu_out)*12		!big_dt replaced with 1hr  %%%% mol/layer to gC/layer %%%%%%%%
	! amount of CH4 released to the lowest air layer if WTD is below the surface
    Ebu_sum_unsat = Ebu_sum_unsat + 1 * sum(met_db)*12	!big_dt replaced with 1hr  %%%% mol/layer to gC/layer %%%%%%%%

    if (Ebu_sum_sat .ne. 0.) then
!        write (*,*) 'Ebu_sum_sat', Ebu_sum_sat
    endif
    if (Ebu_sum_unsat .ne. 0.) then
!        write (*,*) 'Ebu_sum_unsat', Ebu_sum_unsat
    endif

    simuCH4=simuCH4+Ebu_sum_sat
!    write (*,*) 'mebu_out',mebu_out,'Ebu_sum_sat',Ebu_sum_sat
! 	gases_out=gases_out vector containing CH4 flux caused by ebullition
! *****************************************************************************
!    gases_out_rates = gases_out / dt    !Shuang dt=24*3600

    ! amount of CH4 stored in bubbles
!	bubble_methane_tot = bubble_methane_tot+f * presP(i)/(Rgas * tempP(i)) * Vp(i)
    bubble_methane_tot = sum(f * presP/(Rgas * tempP) * Vp)   !this is equation (10)
!    methanebub2 = bubble_methane_tot


!    write (69,609) CH4(1),CH4(2),CH4(3),CH4(4),CH4(5),CH4(6),CH4(7),CH4(8),CH4(9),CH4(10), &	! concentrations
!    & CH4_V(1),CH4_V(2),CH4_V(3),CH4_V(4),CH4_V(5),CH4_V(6),CH4_V(7),CH4_V(8),CH4_V(9),CH4_V(10), &
!    & Vp(1),Vp(2),Vp(3),Vp(4),Vp(5),Vp(6),Vp(7),Vp(8),Vp(9),Vp(10), &		! bubble volumes
!    & mrateP(1),mrateP(2),mrateP(3),mrateP(4),mrateP(5), &	! flux of methane in and out from the bubble
!    & mrateP(6),mrateP(7),mrateP(8),mrateP(9),mrateP(10), &	! methane fluxes
!    & Ebu_sum_sat,Ebu_sum_unsat,simuCH4,bubble_methane_tot
!609	format(43(f11.4,","),f11.4)
!    write (*,*) "4 stopping point"
    return
    end
!   *************************************************************************************

!     end of adding subroutines for methane and soil thermal
!     *** ..int
!     ========================================================================================
!     subroutines used by canopy submodel
      subroutine xlayers(Sps,Tair,Dair,radabv,fbeam,eairP,&                                   ! G,Esoil, deleted  ..int
     &           wind,co2ca,fwsoil,wcl,FLAIT,coszen,idoy,hours,&
     &           tauL,rhoL,rhoS,xfang,extkd,extkU,wleaf,&
     &           Rconst,sigma,emleaf,emsoil,theta,a1,Ds0,&
     &           cpair,Patm,Trefk,H2OLv0,AirMa,H2OMw,Dheat,&
     &           gsw0,alpha,stom_n,wsmax,wsmin,VcmxT,&
     &           Vcmx0,eJmx0,conKc0,conKo0,Ekc,Eko,o2ci,&
     &           Eavm,Edvm,Eajm,Edjm,Entrpy,gam0,gam1,gam2,&
     &           extKb,Rsoilabs,Acan1,Acan2,Ecan1,Ecan2,&
     &           RnStL,QcanL,RcanL,AcanL,EcanL,HcanL,GbwcL,GswcL,gddonset,&
     &           testout,Rsoilab1,Rsoilab2,QLleaf,QLair,raero,do_soilphy,&
     &           G,Esoil,Hsoil,Tleaf) ! G,Esoil,Hsoil added from soil thermal ..int
     ! Tleaf added for testing the leaf temperature response to warming treatment Feb 2019


!    the multi-layered canopy model developed by
!    Ray Leuning with the new radiative transfer scheme
!    implemented by Y.P. Wang (from Sellers 1986)
!    12/Sept/96 (YPW) correction for mean surface temperature of sunlit
!    and shaded leaves
!    Tleaf,i=sum{Tleaf,i(n)*fslt*Gaussw(n)}/sum{fslt*Gaussw(n)}
!
      real Gaussx(5),Gaussw(5)
      real layer1(5),layer2(5)
      real tauL(3),rhoL(3),rhoS(3),Qabs(3,2),Radabv(2),Rnstar(2)
      real Aleaf(2),Eleaf(2),Hleaf(2),Tleaf(2),co2ci(2)
      real gbleaf(2),gsleaf(2),QSabs(3,2),Qasoil(2)
      integer ng,nw
      real rhoc(3,2),reff(3,2),kpr(3,2),scatt(2)       !Goudriaan

      real rsoil,rlai,raero,LAI
      real wsmax,wsmin,WILTPT,FILDCP,wcl(10),VcmxT
      real gddonset
!    additional arrays to allow output of info for each Layer
      real RnStL(5),QcanL(5),RcanL(5),AcanL(5),EcanL(5),HcanL(5)
      real GbwcL(5),GswcL(5)

!   *** ..int
!*************************
      real testout(11)
      logical do_soilphy
!   *** .int

! Normalised Gaussian points and weights (Goudriaan & van Laar, 1993, P98)
!* 5-point
      data Gaussx/0.0469101,0.2307534,0.5,0.7692465,0.9530899/
      data Gaussw/0.1184635,0.2393144,0.2844444,0.2393144,0.1184635/

!     soil water conditions
      WILTPT=wsmin/100.
      FILDCP=wsmax/100.
!     reset the vairables
      Rnst1=0.0        !net rad, sunlit
      Rnst2=0.0        !net rad, shaded
      Qcan1=0.0        !vis rad
      Qcan2=0.0
      Rcan1=0.0        !NIR rad
      Rcan2=0.0
      Acan1=0.0        !CO2
      Acan2=0.0
      Ecan1=0.0        !Evap
      Ecan2=0.0
      Hcan1=0.0        !Sens heat
      Hcan2=0.0
      Gbwc1=0.0        !Boundary layer conductance
      Gbwc2=0.0
      Gswc1=0.0        !Canopy conductance
      Gswc2=0.0
      Tleaf1=0.0       !Leaf Temp
      Tleaf2=0.0

!     aerodynamic resistance
      raero=50./wind

!    Ross-Goudriaan function for G(u) (see Sellers 1985, Eq 13)
      xphi1 = 0.5 - 0.633*xfang -0.33*xfang*xfang
      xphi2 = 0.877 * (1.0 - 2.0*xphi1)
      funG=xphi1 + xphi2*coszen                             !G-function: Projection of unit leaf area in direction of beam

      if(coszen.gt.0) then                                  !check if day or night
        extKb=funG/coszen                                   !beam extinction coeff - black leaves
      else
        extKb=100.
      end if

!     Goudriaan theory as used in Leuning et al 1995 (Eq Nos from Goudriaan & van Laar, 1994)
!     Effective extinction coefficient for diffuse radiation Goudriaan & van Laar Eq 6.6)
      pi180=3.1416/180.
      cozen15=cos(pi180*15)
      cozen45=cos(pi180*45)
      cozen75=cos(pi180*75)
      xK15=xphi1/cozen15+xphi2
      xK45=xphi1/cozen45+xphi2
      xK75=xphi1/cozen75+xphi2
      transd=0.308*exp(-xK15*FLAIT)+0.514*exp(-xK45*FLAIT)+     &
     &       0.178*exp(-xK75*FLAIT)
      extkd=(-1./FLAIT)*alog(transd)
	  ! write (*,*) "xlayers cal extkd",extkd,"FLAIT",FLAIT,"transd",transd
      extkn=extkd                        !N distribution coeff

!canopy reflection coefficients (Array indices: first;  1=VIS,  2=NIR
!                                               second; 1=beam, 2=diffuse
      do nw=1,2                                                      !nw:1=VIS, 2=NIR
       scatt(nw)=tauL(nw)+rhoL(nw)                      !scattering coeff
       if((1.-scatt(nw))<0.0)scatt(nw)=0.9999           ! Weng 10/31/2008
       kpr(nw,1)=extKb*sqrt(1.-scatt(nw))               !modified k beam scattered (6.20)
       kpr(nw,2)=extkd*sqrt(1.-scatt(nw))             !modified k diffuse (6.20)
       rhoch=(1.-sqrt(1.-scatt(nw)))/(1.+sqrt(1.-scatt(nw)))            !canopy reflection black horizontal leaves (6.19)
       rhoc15=2.*xK15*rhoch/(xK15+extkd)                                !canopy reflection (6.21) diffuse
       rhoc45=2.*xK45*rhoch/(xK45+extkd)
       rhoc75=2.*xK75*rhoch/(xK75+extkd)
       rhoc(nw,2)=0.308*rhoc15+0.514*rhoc45+0.178*rhoc75
       rhoc(nw,1)=2.*extKb/(extKb+extkd)*rhoch                          !canopy reflection (6.21) beam
       reff(nw,1)=rhoc(nw,1)+(rhoS(nw)-rhoc(nw,1))   &                   !effective canopy-soil reflection coeff - beam (6.27)
     &            *exp(-2.*kpr(nw,1)*FLAIT)
       reff(nw,2)=rhoc(nw,2)+(rhoS(nw)-rhoc(nw,2))   &                   !effective canopy-soil reflection coeff - diffuse (6.27)
     &            *exp(-2.*kpr(nw,2)*FLAIT)
      enddo


!     isothermal net radiation & radiation conductance at canopy top - needed to calc emair
      call Radiso(flai,flait,Qabs,extkd,Tair,eairP,cpair,Patm, &
     &            fbeam,airMa,Rconst,sigma,emleaf,emsoil,       &
     &            emair,Rnstar,grdn)
      TairK=Tair+273.2
		! write(*,*) "1 Radiso Tair",Tair,"Rnstar",Rnstar
!         print*,'Tair',Tair
!     below
      do ng=1,5
         flai=gaussx(ng)*FLAIT
!        radiation absorption for visible and near infra-red
         call goudriaan(FLAI,coszen,radabv,fbeam,reff,kpr,      &
     &                  scatt,xfang,Qabs)
!        isothermal net radiation & radiation conductance at canopy top
         call Radiso(flai,flait,Qabs,extkd,Tair,eairP,cpair,Patm,   &
     &               fbeam,airMa,Rconst,sigma,emleaf,emsoil,        &
     &               emair,Rnstar,grdn)
         windUx=wind*exp(-extkU*flai)             !windspeed at depth xi
         scalex=exp(-extkn*flai)                    !scale Vcmx0 & Jmax0
         Vcmxx=Vcmx0*scalex
         eJmxx=eJmx0*scalex
!         print*,'Vcmxx',Vcmxx,Vcmx0,scalex
		! write(*,*) "2 Radiso Tair",Tair,"Rnstar",Rnstar
         if(radabv(1).ge.10.0) then                          !check solar Radiation > 10 W/m2
!           leaf stomata-photosynthesis-transpiration model - daytime
            call agsean_day(Sps,Qabs,Rnstar,grdn,windUx,Tair,Dair,      &
     &               co2ca,wleaf,raero,theta,a1,Ds0,fwsoil,idoy,hours,  &
     &               Rconst,cpair,Patm,Trefk,H2OLv0,AirMa,H2OMw,Dheat,  &
     &               gsw0,alpha,stom_n,VcmxT,                                &
     &               Vcmxx,eJmxx,conKc0,conKo0,Ekc,Eko,o2ci,            &
     &               Eavm,Edvm,Eajm,Edjm,Entrpy,gam0,gam1,gam2,         &
     &               Aleaf,Eleaf,Hleaf,Tleaf,gbleaf,gsleaf,co2ci,gddonset)
         else
            call agsean_ngt(Sps,Qabs,Rnstar,grdn,windUx,Tair,Dair,      &
     &               co2ca,wleaf,raero,theta,a1,Ds0,fwsoil,idoy,hours,  &
     &               Rconst,cpair,Patm,Trefk,H2OLv0,AirMa,H2OMw,Dheat,  &
     &               gsw0,alpha,stom_n,                                 &
     &               Vcmxx,eJmxx,conKc0,conKo0,Ekc,Eko,o2ci,            &
     &               Eavm,Edvm,Eajm,Edjm,Entrpy,gam0,gam1,gam2,         &
     &               Aleaf,Eleaf,Hleaf,Tleaf,gbleaf,gsleaf,co2ci)
         endif
         fslt=exp(-extKb*flai)                        !fraction of sunlit leaves
         fshd=1.0-fslt                                !fraction of shaded leaves
         Rnst1=Rnst1+fslt*Rnstar(1)*Gaussw(ng)*FLAIT  !Isothermal net rad`
         Rnst2=Rnst2+fshd*Rnstar(2)*Gaussw(ng)*FLAIT
         RnstL(ng)=Rnst1+Rnst2
!
         Qcan1=Qcan1+fslt*Qabs(1,1)*Gaussw(ng)*FLAIT  !visible
         Qcan2=Qcan2+fshd*Qabs(1,2)*Gaussw(ng)*FLAIT
         QcanL(ng)=Qcan1+Qcan2
!
         Rcan1=Rcan1+fslt*Qabs(2,1)*Gaussw(ng)*FLAIT  !NIR
         Rcan2=Rcan2+fshd*Qabs(2,2)*Gaussw(ng)*FLAIT
         RcanL(ng)=Rcan1+Rcan2
!
         if(Aleaf(1).lt.0.0)Aleaf(1)=0.0      !Weng 2/16/2006
         if(Aleaf(2).lt.0.0)Aleaf(2)=0.0      !Weng 2/16/2006

         !print*,'fslt5',extkb,flai,fslt,fshd
         Acan1=Acan1+fslt*Aleaf(1)*Gaussw(ng)*FLAIT*stom_n    !amphi/hypostomatous
         Acan2=Acan2+fshd*Aleaf(2)*Gaussw(ng)*FLAIT*stom_n
		 ! write (*,*)'cal Acan1',Acan1,'Acan2',Acan2
         ! print*,'Acan1',ng,Acan1,fslt,Aleaf(1),Gaussw(ng),FLAIT,stom_n,extKb,flai
         ! print*,'Acan2',ng,Acan2,fshd,Aleaf(2),Gaussw(ng),FLAIT,stom_n
         AcanL(ng)=Acan1+Acan2

         layer1(ng)=Aleaf(1)
         layer2(ng)=Aleaf(2)

         Ecan1=Ecan1+fslt*Eleaf(1)*Gaussw(ng)*FLAIT
         Ecan2=Ecan2+fshd*Eleaf(2)*Gaussw(ng)*FLAIT
         EcanL(ng)=Ecan1+Ecan2
!
         Hcan1=Hcan1+fslt*Hleaf(1)*Gaussw(ng)*FLAIT
         Hcan2=Hcan2+fshd*Hleaf(2)*Gaussw(ng)*FLAIT
         HcanL(ng)=Hcan1+Hcan2
!
         Gbwc1=Gbwc1+fslt*gbleaf(1)*Gaussw(ng)*FLAIT*stom_n
         Gbwc2=Gbwc2+fshd*gbleaf(2)*Gaussw(ng)*FLAIT*stom_n
!
         Gswc1=Gswc1+fslt*gsleaf(1)*Gaussw(ng)*FLAIT*stom_n
         Gswc2=Gswc2+fshd*gsleaf(2)*Gaussw(ng)*FLAIT*stom_n
!
         Tleaf1=Tleaf1+fslt*Tleaf(1)*Gaussw(ng)*FLAIT
         Tleaf2=Tleaf2+fshd*Tleaf(2)*Gaussw(ng)*FLAIT
      enddo  ! 5 layers

      FLAIT1=(1.0-exp(-extKb*FLAIT))/extkb
      Tleaf1=Tleaf1/FLAIT1
      Tleaf2=Tleaf2/(FLAIT-FLAIT1)

!     Soil surface energy and water fluxes
!    Radiation absorbed by soil
      Rsoilab1=fbeam*(1.-reff(1,1))*exp(-kpr(1,1)*FLAIT)        &
     &         +(1.-fbeam)*(1.-reff(1,2))*exp(-kpr(1,2)*FLAIT)          !visible
      Rsoilab2=fbeam*(1.-reff(2,1))*exp(-kpr(2,1)*FLAIT)        &
     &         +(1.-fbeam)*(1.-reff(2,2))*exp(-kpr(2,2)*FLAIT)          !NIR
      Rsoilab1=Rsoilab1*Radabv(1)
      Rsoilab2=Rsoilab2*Radabv(2)
!
      Tlk1=Tleaf1+273.2
      Tlk2=Tleaf2+273.2
!      temp1=-extkd*FLAIT
      QLair=emair*sigma*(TairK**4)*exp(-extkd*FLAIT)
      QLleaf=emleaf*sigma*(Tlk1**4)*exp(-extkb*FLAIT)           &
     &      +emleaf*sigma*(Tlk2**4)*(1.0-exp(-extkb*FLAIT))
      QLleaf=QLleaf*(1.0-exp(-extkd*FLAIT))
      QLsoil=emsoil*sigma*(TairK**4)
      Rsoilab3=(QLair+QLleaf)*(1.0-rhoS(3))-QLsoil

!    Net radiation absorbed by soil
!    the old version of net long-wave radiation absorbed by soils
!    (with isothermal assumption)
!     Rsoil3=(sigma*TairK**4)*(emair-emleaf)*exp(-extkd*FLAIT)         !Longwave
!     Rsoilab3=(1-rhoS(3))*Rsoil3

!    Total radiation absorbed by soil
      Rsoilabs=Rsoilab1+Rsoilab2+Rsoilab3

!    thermodynamic parameters for air
      TairK=Tair+273.2
      rhocp=cpair*Patm*AirMa/(Rconst*TairK)
      H2OLv=H2oLv0-2.365e3*Tair
      slope=(esat(Tair+0.1)-esat(Tair))/0.1
      psyc=Patm*cpair*AirMa/(H2OLv*H2OMw)
      Cmolar=Patm/(Rconst*TairK)
      fw1=AMIN1(AMAX1((FILDCP-wcl(1))/(FILDCP-WILTPT),0.05),1.0)
      Rsoil=30.*exp(0.2/fw1)
      rLAI=exp(FLAIT)
!     latent heat flux into air from soil
!           Eleaf(ileaf)=1.0*
!     &     (slope*Y*Rnstar(ileaf)+rhocp*Dair/(rbH_L+raero))/    !2* Weng 0215
!     &     (slope*Y+psyc*(rswv+rbw+raero)/(rbH_L+raero))
      Esoil=(slope*(Rsoilabs-G)+rhocp*Dair/(raero+rLAI))/       &
     &      (slope+psyc*(rsoil/(raero+rLAI)+1.))
!     sensible heat flux into air from soil
      Hsoil=Rsoilabs-Esoil-G

      return
      end

!     ****************************************************************************
      subroutine goudriaan(FLAI,coszen,radabv,fbeam,reff,kpr,   &
     &                  scatt,xfang,Qabs)

!    for spheric leaf angle distribution only
!    compute within canopy radiation (PAR and near infra-red bands)
!    using two-stream approximation (Goudriaan & vanLaar 1994)
!    tauL: leaf transmittance
!    rhoL: leaf reflectance
!    rhoS: soil reflectance
!    sfang XiL function of Ross (1975) - allows for departure from spherical LAD
!         (-1 vertical, +1 horizontal leaves, 0 spherical)
!    FLAI: canopy leaf area index
!    funG: Ross' G function
!    scatB: upscatter parameter for direct beam
!    scatD: upscatter parameter for diffuse
!    albedo: single scattering albedo
!    output:
!    Qabs(nwave,type), nwave=1 for visible; =2 for NIR,
!                       type=1 for sunlit;   =2 for shaded (W/m2)

      real radabv(2)
      real Qabs(3,2),reff(3,2),kpr(3,2),scatt(2)
      xu=coszen                                         !cos zenith angle

!     Ross-Goudriaan function for G(u) (see Sellers 1985, Eq 13)
      xphi1 = 0.5 - 0.633*xfang -0.33*xfang*xfang
      xphi2 = 0.877 * (1.0 - 2.0*xphi1)
      funG=xphi1 + xphi2*xu                             !G-function: Projection of unit leaf area in direction of beam

      if(coszen.gt.0) then                                  !check if day or night
        extKb=funG/coszen                                   !beam extinction coeff - black leaves
      else
        extKb=100.
      end if

! Goudriaan theory as used in Leuning et al 1995 (Eq Nos from Goudriaan & van Laar, 1994)
      do nw=1,2
       Qd0=(1.-fbeam)*radabv(nw)                                          !diffuse incident radiation
       Qb0=fbeam*radabv(nw)                                               !beam incident radiation
       Qabs(nw,2)=Qd0*(kpr(nw,2)*(1.-reff(nw,2))*exp(-kpr(nw,2)*FLAI))+  & !absorbed radiation - shaded leaves, diffuse
     &            Qb0*(kpr(nw,1)*(1.-reff(nw,1))*exp(-kpr(nw,1)*FLAI)-   & !beam scattered
     &            extKb*(1.-scatt(nw))*exp(-extKb*FLAI))
       Qabs(nw,1)=Qabs(nw,2)+extKb*Qb0*(1.-scatt(nw))                     !absorbed radiation - sunlit leaves
      end do
      return
      end

!****************************************************************************
      subroutine Radiso(flai,flait,Qabs,extkd,Tair,eairP,cpair,Patm,    &
     &                  fbeam,airMa,Rconst,sigma,emleaf,emsoil,         &
     &                  emair,Rnstar,grdn)
!     output
!     Rnstar(type): type=1 for sunlit; =2 for shaded leaves (W/m2)
!     23 Dec 1994
!     calculates isothermal net radiation for sunlit and shaded leaves under clear skies
!     implicit real (a-z)
      real Rnstar(2)
      real Qabs(3,2)
      TairK=Tair+273.2

! thermodynamic properties of air
      rhocp=cpair*Patm*airMa/(Rconst*TairK)   !volumetric heat capacity (J/m3/K)

! apparent atmospheric emissivity for clear skies (Brutsaert, 1975)
      emsky=0.642*(eairP/Tairk)**(1./7)       !note eair in Pa

! apparent emissivity from clouds (Kimball et al 1982)
      ep8z=0.24+2.98e-12*eairP*eairP*exp(3000/TairK)
      tau8=amin1(1.0,1.0-ep8z*(1.4-0.4*ep8z))            !ensure tau8<1
      emcloud=0.36*tau8*(1.-fbeam)*(1-10./TairK)**4      !10 from Tcloud = Tair-10

! apparent emissivity from sky plus clouds
!      emair=emsky+emcloud
! 20/06/96
      emair=emsky

      if(emair.gt.1.0) emair=1.0

! net isothermal outgoing longwave radiation per unit leaf area at canopy
! top & thin layer at flai (Note Rn* = Sn + Bn is used rather than Rn* = Sn - Bn in Leuning et al 1985)
      Bn0=sigma*(TairK**4.)
      Bnxi=Bn0*extkd*(exp(-extkd*flai)*(emair-emleaf)       &
     &    + exp(-extkd*(flait-flai))*(emsoil-emleaf))
	 ! write (*,*) "in Bnxi",Bnxi,"Bn0",Bn0,"extkd",extkd,"flai",flai,"emair",emair,"emleaf",emleaf,"flait",flait,"emsoil",emsoil
!     isothermal net radiation per unit leaf area for thin layer of sunlit and
!     shaded leaves
      Rnstar(1)=Qabs(1,1)+Qabs(2,1)+Bnxi
      Rnstar(2)=Qabs(1,2)+Qabs(2,2)+Bnxi
	  ! write (*,*) "in Radiso Qabs", Qabs(1,1),Qabs(2,1),Qabs(1,2),Qabs(2,2),"Bnxi",Bnxi
!     radiation conductance (m/s) @ flai
      grdn=4.*sigma*(TairK**3.)*extkd*emleaf*               &       ! corrected by Jiang Jiang 2015/9/29
     &    (exp(-extkd*flai)+exp(-extkd*(flait-flai)))       &
     &    /rhocp
      return
      end
!     ****************************************************************************
      subroutine agsean_day(Sps,Qabs,Rnstar,grdn,windUx,Tair,Dair,      &
     &               co2ca,wleaf,raero,theta,a1,Ds0,fwsoil,idoy,hours,  &
     &               Rconst,cpair,Patm,Trefk,H2OLv0,AirMa,H2OMw,Dheat,  &
     &               gsw0,alpha,stom_n,VcmxT,                                 &
     &               Vcmxx,eJmxx,conKc0,conKo0,Ekc,Eko,o2ci,            &
     &               Eavm,Edvm,Eajm,Edjm,Entrpy,gam0,gam1,gam2,         &
     &               Aleaf,Eleaf,Hleaf,Tleaf,gbleaf,gsleaf,co2ci,gddonset) ! outputs

!    implicit real (a-z)
      integer kr1,ileaf
      real Aleaf(2),Eleaf(2),Hleaf(2),Tleaf(2),co2ci(2)
      real gbleaf(2), gsleaf(2)
      real Qabs(3,2),Rnstar(2)
      real VcmxT
!    thermodynamic parameters for air
      TairK=Tair+273.2
      rhocp=cpair*Patm*AirMa/(Rconst*TairK)
      H2OLv=H2oLv0-2.365e3*Tair
      slope=(esat(Tair+0.1)-esat(Tair))/0.1
      psyc=Patm*cpair*AirMa/(H2OLv*H2OMw)
      Cmolar=Patm/(Rconst*TairK)
      weighJ=1.0
!    boundary layer conductance for heat - single sided, forced convection
!    (Monteith 1973, P106 & notes dated 23/12/94)
      if(windUx/wleaf>=0.0)then
          gbHu=0.003*sqrt(windUx/wleaf)    !m/s
      else
          gbHu=0.003 !*sqrt(-windUx/wleaf)
      endif         ! Weng 10/31/2008
!     raero=0.0                        !aerodynamic resistance s/m
      do ileaf=1,2              ! loop over sunlit and shaded leaves
!        first estimate of leaf temperature - assume air temp
         Tleaf(ileaf)=Tair
         Tlk=Tleaf(ileaf)+273.2    !Tleaf to deg K
!        first estimate of deficit at leaf surface - assume Da
         Dleaf=Dair                !Pa
!        first estimate for co2cs
         co2cs=co2ca               !mol/mol
         Qapar = (4.6e-6)*Qabs(1,ileaf)
!    ********************************************************************
         kr1=0                     !iteration counter for LE
!        return point for evaporation iteration
         do               !iteration for leaf temperature
!          single-sided boundary layer conductance - free convection (see notes 23/12/94)
           Gras=1.595e8*ABS(Tleaf(ileaf)-Tair)*(wleaf**3.)     !Grashof
           gbHf=0.5*Dheat*(Gras**0.25)/wleaf
           gbH=gbHu+gbHf                         !m/s
           rbH=1./gbH                            !b/l resistance to heat transfer
           rbw=0.93*rbH                          !b/l resistance to water vapour
!          Y factor for leaf: stom_n = 1.0 for hypostomatous leaf;  stom_n = 2.0 for amphistomatous leaf
           rbH_L=rbH*stom_n/2.                   !final b/l resistance for heat
           rrdn=1./grdn
           Y=1./(1.+ (rbH_L+raero)/rrdn)
!          boundary layer conductance for CO2 - single side only (mol/m2/s)
           gbc=Cmolar*gbH/1.32            !mol/m2/s
           gsc0=gsw0/1.57                 !convert conductance for H2O to that for CO2
           varQc=0.0
           weighR=1.0
           call photosyn(Sps,CO2Ca,CO2Cs,Dleaf,Tlk,Qapar,Gbc,   &   !Qaparx<-Qapar,Gbcx<-Gsc0
     &         theta,a1,Ds0,fwsoil,varQc,weighR,                &
     &         gsc0,alpha,VcmxT,Vcmxx,eJmxx,weighJ,                   &
     &         conKc0,conKo0,Ekc,Eko,o2ci,Rconst,Trefk,         &
     &         Eavm,Edvm,Eajm,Edjm,Entrpy,gam0,gam1,gam2,       &
     &         Aleafx,Gscx,gddonset)  !the only outputs are Aleafx,Gscx
!          choose smaller of Ac, Aq
           Aleaf(ileaf) = Aleafx      !0.7 Weng 3/22/2006          !mol CO2/m2/s
!          calculate new values for gsc, cs (Lohammer model)
           co2cs = co2ca-Aleaf(ileaf)/gbc
           co2Ci(ileaf) = co2cs-Aleaf(ileaf)/gscx
!          scale variables
!           gsw=gscx*1.56      !gsw in mol/m2/s, original:gsw=gsc0*1.56,Weng20060215
           gsw=gscx*1.56       !gsw in mol/m2/s, original:gsw=gscx*1.56,Weng20090226
           gswv=gsw/Cmolar                           !gsw in m/s
           rswv=1./gswv
!          calculate evap'n using combination equation with current estimate of gsw
           Eleaf(ileaf)=1.0*                                    &
     &     (slope*Y*Rnstar(ileaf)+rhocp*Dair/(rbH_L+raero))/    &   !2* Weng 0215
     &     (slope*Y+psyc*(rswv+rbw+raero)/(rbH_L+raero))

!          calculate sensible heat flux
           Hleaf(ileaf)=Y*(Rnstar(ileaf)-Eleaf(ileaf))
!          calculate new leaf temperature (K)
           Tlk1=273.2+Tair+Hleaf(ileaf)*(rbH/2.+raero)/rhocp
!          calculate Dleaf use LE=(rhocp/psyc)*gsw*Ds
           Dleaf=psyc*Eleaf(ileaf)/(rhocp*gswv)
           gbleaf(ileaf)=gbc*1.32*1.075
           gsleaf(ileaf)=gsw
!          compare current and previous leaf temperatures
           if(abs(Tlk1-Tlk).le.0.1) exit ! original is 0.05 C Weng 10/31/2008
!          update leaf temperature  ! leaf temperature calculation has many problems! Weng 10/31/2008
           Tlk=Tlk1
           Tleaf(ileaf)=Tlk1-273.2
           kr1=kr1+1
           if(kr1 > 500)then
               Tlk=TairK
               exit
           endif
           if(Tlk < 200.)then
                Tlk=TairK
                exit
           endif                     ! Weng 10/31/2008
!        goto 100                          !solution not found yet
         enddo
! 10  continue
      enddo
      return
      end
!     ****************************************************************************
      subroutine agsean_ngt(Sps,Qabs,Rnstar,grdn,windUx,Tair,Dair,co2ca,    &
     &               wleaf,raero,theta,a1,Ds0,fwsoil,idoy,hours,            &
     &               Rconst,cpair,Patm,Trefk,H2OLv0,AirMa,H2OMw,Dheat,      &
     &               gsw0,alpha,stom_n,                                     &
     &               Vcmxx,eJmxx,conKc0,conKo0,Ekc,Eko,o2ci,                &
     &               Eavm,Edvm,Eajm,Edjm,Entrpy,gam0,gam1,gam2,             &
     &               Aleaf,Eleaf,Hleaf,Tleaf,gbleaf,gsleaf,co2ci)
!    implicit real (a-z)
      integer kr1,ileaf
      real Aleaf(2),Eleaf(2),Hleaf(2),Tleaf(2),co2ci(2)
      real gbleaf(2), gsleaf(2)
      real Qabs(3,2),Rnstar(2)
!    thermodynamic parameters for air
      TairK=Tair+273.2
      rhocp=cpair*Patm*AirMa/(Rconst*TairK)
      H2OLv=H2oLv0-2.365e3*Tair
      slope=(esat(Tair+0.1)-esat(Tair))/0.1
      psyc=Patm*cpair*AirMa/(H2OLv*H2OMw)
      Cmolar=Patm/(Rconst*TairK)
      weighJ=1.0

!     boundary layer conductance for heat - single sided, forced convection
!     (Monteith 1973, P106 & notes dated 23/12/94)
      gbHu=0.003*sqrt(windUx/wleaf)    !m/s
!     raero=0.0                        !aerodynamic resistance s/m

      do ileaf=1,2                  ! loop over sunlit and shaded leaves
!        first estimate of leaf temperature - assume air temp
         Tleaf(ileaf)=Tair
         Tlk=Tleaf(ileaf)+273.2    !Tleaf to deg K
!        first estimate of deficit at leaf surface - assume Da
         Dleaf=Dair                !Pa
!        first estimate for co2cs
         co2cs=co2ca               !mol/mol
         Qapar = (4.6e-6)*Qabs(1,ileaf)
!        ********************************************************************
         kr1=0                     !iteration counter for LE
         do
!100        continue !    return point for evaporation iteration
!           single-sided boundary layer conductance - free convection (see notes 23/12/94)
            Gras=1.595e8*abs(Tleaf(ileaf)-Tair)*(wleaf**3)     !Grashof
            gbHf=0.5*Dheat*(Gras**0.25)/wleaf
            gbH=gbHu+gbHf                         !m/s
            rbH=1./gbH                            !b/l resistance to heat transfer
            rbw=0.93*rbH                          !b/l resistance to water vapour
!           Y factor for leaf: stom_n = 1.0 for hypostomatous leaf;  stom_n = 2.0 for amphistomatous leaf
            rbH_L=rbH*stom_n/2.                   !final b/l resistance for heat
            rrdn=1./grdn
            Y=1./(1.+ (rbH_L+raero)/rrdn)
!           boundary layer conductance for CO2 - single side only (mol/m2/s)
            gbc=Cmolar*gbH/1.32            !mol/m2/s
            gsc0=gsw0/1.57                        !convert conductance for H2O to that for CO2
            varQc=0.0
            weighR=1.0
!           respiration
            Aleafx=-0.0089*Vcmxx*exp(0.069*(Tlk-293.2))
            gsc=gsc0
			! write (*,*) "agsean_ngt Aleafx",Aleafx,"Vcmxx",Vcmxx,"Tlk",Tlk
!           choose smaller of Ac, Aq
            Aleaf(ileaf) = Aleafx                     !mol CO2/m2/s
!           calculate new values for gsc, cs (Lohammer model)
            co2cs = co2ca-Aleaf(ileaf)/gbc
            co2Ci(ileaf) = co2cs-Aleaf(ileaf)/gsc
!           scale variables
            gsw=gsc*1.56                              !gsw in mol/m2/s
            gswv=gsw/Cmolar                           !gsw in m/s
            rswv=1./gswv
!           calculate evap'n using combination equation with current estimate of gsw
            Eleaf(ileaf)=                                       &
     &      (slope*Y*Rnstar(ileaf)+rhocp*Dair/(rbH_L+raero))/   &
     &      (slope*Y+psyc*(rswv+rbw+raero)/(rbH_L+raero))
!           calculate sensible heat flux
            Hleaf(ileaf)=Y*(Rnstar(ileaf)-Eleaf(ileaf))
			! write (*,*) "cal Hleaf(ileaf)",Hleaf(ileaf),"Y",Y,"Rnstar(ileaf)",Rnstar(ileaf),"Eleaf(ileaf)",Eleaf(ileaf)
!           calculate new leaf temperature (K)
            Tlk1=273.2+Tair+Hleaf(ileaf)*(rbH/2.+raero)/rhocp
			! write (*,*) "Tlk1",Tlk1,"Hleaf(ileaf)",Hleaf(ileaf),"rbH",rbH,"raero",raero,"rhocp",rhocp
!           calculate Dleaf use LE=(rhocp/psyc)*gsw*Ds
            Dleaf=psyc*Eleaf(ileaf)/(rhocp*gswv)
            gbleaf(ileaf)=gbc*1.32*1.075
            gsleaf(ileaf)=gsw

!          compare current and previous leaf temperatures
            if(abs(Tlk1-Tlk).le.0.1)exit
            if(kr1.gt.500)exit
!           update leaf temperature
            Tlk=Tlk1
            Tleaf(ileaf)=Tlk1-273.2
            kr1=kr1+1
         enddo                          !solution not found yet
10    continue
      enddo
      return
      end
!     ****************************************************************************
      subroutine ciandA(Gma,Bta,g0,X,Rd,co2Cs,gammas,ciquad,Aquad)
!     calculate coefficients for quadratic equation for ci
      b2 = g0+X*(Gma-Rd)
      b1 = (1.-co2cs*X)*(Gma-Rd)+g0*(Bta-co2cs)-X*(Gma*gammas+Bta*Rd)
      b0 = -(1.-co2cs*X)*(Gma*gammas+Bta*Rd)-g0*Bta*co2cs

      bx=b1*b1-4.*b2*b0
      if(bx.gt.0.0) then
!       calculate larger root of quadratic
        ciquad = (-b1+sqrt(bx))/(2.*b2)
      endif

      IF(ciquad.lt.0.or.bx.lt.0.) THEN
        Aquad = 0.0
        ciquad = 0.7 * co2Cs
      ELSE
        Aquad = Gma*(ciquad-gammas)/(ciquad+Bta)
      ENDIF
      return
      end

!****************************************************************************
      subroutine goud1(FLAIT,coszen,radabv,fbeam,               &
     &                  Tair,eairP,emair,emsoil,emleaf,sigma,   &
     &                  tauL,rhoL,rhoS,xfang,extkb,extkd,       &
     &                  reffbm,reffdf,extkbm,extkdm,Qcan)
!    use the radiation scheme developed by
!    Goudriaan (1977, Goudriaan and van Larr 1995)
!=================================================================
!    Variable      unit      defintion
!    FLAIT         m2/m2     canopy leaf area index
!    coszen                  cosine of the zenith angle of the sun
!    radabv(nW)    W/m2      incoming radiation above the canopy
!    fbeam                   beam fraction
!    fdiff                   diffuse fraction
!    funG(=0.5)              Ross's G function
!    extkb                   extinction coefficient for beam PAR
!    extkd                   extinction coefficient for diffuse PAR
!    albedo                  single scattering albedo
!    scatB                   upscattering parameter for beam
!    scatD                   upscattering parameter for diffuse
! ==================================================================
!    all intermediate variables in the calculation correspond
!    to the variables in the Appendix of of Seller (1985) with
!    a prefix of "x".
      integer nW
      real radabv(3)
      real rhocbm(3),rhocdf(3)
      real reffbm(3),reffdf(3),extkbm(3),extkdm(3)
      real tauL(3),rhoL(3),rhoS(3),scatL(3)
      real Qcan(3,2)
!
!     for PAR: using Goudriann approximation to account for scattering
      fdiff=1.0-fbeam
      xu=coszen
      xphi1 = 0.5 -0.633*xfang - 0.33*xfang*xfang
      xphi2 = 0.877 * (1.0 - 2.0*xphi1)
      funG = xphi1 + xphi2*xu
      extkb=funG/xu

!     Effective extinction coefficient for diffuse radiation Goudriaan & van Laar Eq 6.6)
      pi180=3.1416/180.
      cozen15=cos(pi180*15)
      cozen45=cos(pi180*45)
      cozen75=cos(pi180*75)
      xK15=xphi1/cozen15+xphi2
      xK45=xphi1/cozen45+xphi2
      xK75=xphi1/cozen75+xphi2
      transd=0.308*exp(-xK15*FLAIT)+0.514*exp(-xK45*FLAIT)+     &
     &       0.178*exp(-xK75*FLAIT)
      extkd=(-1./FLAIT)*alog(transd)

!     canopy reflection coefficients (Array indices: 1=VIS,  2=NIR
      do nw=1,2                                                         !nw:1=VIS, 2=NIR
         scatL(nw)=tauL(nw)+rhoL(nw)                                    !scattering coeff
         if((1.-scatL(nw))<0.0) scatL(nw)=0.9999                        !Weng 10/31/2008
         extkbm(nw)=extkb*sqrt(1.-scatL(nw))                            !modified k beam scattered (6.20)
         extkdm(nw)=extkd*sqrt(1.-scatL(nw))                            !modified k diffuse (6.20)
         rhoch=(1.-sqrt(1.-scatL(nw)))/(1.+sqrt(1.-scatL(nw)))          !canopy reflection black horizontal leaves (6.19)
         rhoc15=2.*xK15*rhoch/(xK15+extkd)                              !canopy reflection (6.21) diffuse
         rhoc45=2.*xK45*rhoch/(xK45+extkd)
         rhoc75=2.*xK75*rhoch/(xK75+extkd)

         rhocbm(nw)=2.*extkb/(extkb+extkd)*rhoch                        !canopy reflection (6.21) beam
         rhocdf(nw)=0.308*rhoc15+0.514*rhoc45+0.178*rhoc75
         reffbm(nw)=rhocbm(nw)+(rhoS(nw)-rhocbm(nw))        &               !effective canopy-soil reflection coeff - beam (6.27)
     &             *exp(-2.*extkbm(nw)*FLAIT)
         reffdf(nw)=rhocdf(nw)+(rhoS(nw)-rhocdf(nw))        &            !effective canopy-soil reflection coeff - diffuse (6.27)
     &             *exp(-2.*extkdm(nw)*FLAIT)

!        by the shaded leaves
         abshdn=fdiff*(1.0-reffdf(nw))*extkdm(nw)                       &           !absorbed NIR by shaded
     &      *(funE(extkdm(nw),FLAIT)-funE((extkb+extkdm(nw)),FLAIT))    &
     &      +fbeam*(1.0-reffbm(nw))*extkbm(nw)                          &
!    &      *(funE(extkbm(nw),FLAIT)-funE((extkb+extkdm(nw)),FLAIT))    ! error found by De Pury
     &      *(funE(extkbm(nw),FLAIT)-funE((extkb+extkbm(nw)),FLAIT))    &
     &      -fbeam*(1.0-scatL(nw))*extkb                                &
     &      *(funE(extkb,FLAIT)-funE(2.0*extkb,FLAIT))
!        by the sunlit leaves
         absltn=fdiff*(1.0-reffdf(nw))*extkdm(nw)                       &  !absorbed NIR by sunlit
     &      *funE((extkb+extkdm(nw)),FLAIT)                             &
     &      +fbeam*(1.0-reffbm(nw))*extkbm(nw)                          &
!    &      *funE((extkb+extkdm(nw)),FLAIT)                         ! error found by De Pury
     &      *funE((extkb+extkbm(nw)),FLAIT)                             &
     &      +fbeam*(1.0-scatL(nw))*extkb                                &
     &      *(funE(extkb,FLAIT)-funE(2.0*extkb,FLAIT))

!        scale to real flux
!        sunlit
          Qcan(nw,1)=absltn*radabv(nw)
!        shaded
          Qcan(nw,2)=abshdn*radabv(nw)
      enddo
!
!    calculate the absorbed (iso)thermal radiation
      TairK=Tair+273.2

!     apparent atmospheric emissivity for clear skies (Brutsaert, 1975)
      emsky=0.642*(eairP/Tairk)**(1./7)      !note eair in Pa

!     apparent emissivity from clouds (Kimball et al 1982)
      ep8z=0.24+2.98e-12*eairP*eairP*exp(3000.0/TairK)
      tau8=amin1(1.0,1-ep8z*(1.4-0.4*ep8z))                !ensure tau8<1
      emcloud=0.36*tau8*(1.-fbeam)*(1-10./TairK)**4        !10 from Tcloud = Tair-10

!     apparent emissivity from sky plus clouds
!     emair=emsky+emcloud
! 20/06/96
      emair=emsky
      if(emair.gt.1.0) emair=1.0

      Bn0=sigma*(TairK**4)
      QLW1=-extkd*emleaf*(1.0-emair)*funE((extkd+extkb),FLAIT)      &
     &     -extkd*(1.0-emsoil)*(emleaf-emair)*exp(-2.0*extkd*FLAIT) &
     &     *funE((extkb-extkd),FLAIT)
      QLW2=-extkd*emleaf*(1.0-emair)*funE(extkd,FLAIT)              &
     &     -extkd*(1.0-emsoil)*(emleaf-emair)                       &
     &     *(exp(-extkd*FLAIT)-exp(-2.0*extkd*FLAIT))/extkd         &
     &     -QLW1
      Qcan(3,1)=QLW1*Bn0
      Qcan(3,2)=QLW2*Bn0
      return
      end

!****************************************************************************
      subroutine photosyn(Sps,CO2Ca,CO2Csx,Dleafx,Tlkx,Qaparx,Gbcx, &
     &         theta,a1,Ds0,fwsoil,varQc,weighR,                    &
     &         g0,alpha,VcmxT,                                            &
     &         Vcmx1,eJmx1,weighJ,conKc0,conKo0,Ekc,Eko,o2ci,       &
     &         Rconst,Trefk,Eavm,Edvm,Eajm,Edjm,Entrpy,gam0,gam1,gam2,  &
     &         Aleafx,Gscx,gddonset)

!     calculate Vcmax, Jmax at leaf temp (Eq 9, Harley et al 1992)
!     turned on by Weng, 2012-03-13
     VcmxT = Vjmax(Tlkx,Trefk,Vcmx1,Eavm,Edvm,Rconst,Entrpy)
     eJmxT = Vjmax(Tlkx,Trefk,eJmx1,Eajm,Edjm,Rconst,Entrpy)
      CO2Csx=AMAX1(CO2Csx,0.6*CO2Ca)
!    check if it is dark - if so calculate respiration and g0 to assign conductance
      if(Qaparx.le.0.) then                            !night, umol quanta/m2/s
        Aleafx=-0.0089*Vcmx1*exp(0.069*(Tlkx-293.2))   ! original: 0.0089 Weng 3/22/2006
        Gscx=g0
      endif
	  ! write (*,*) "in photosyn Aleafx", Aleafx, "Vcmx1",Vcmx1,"Tlkx",Tlkx
!     calculate  Vcmax, Jmax at leaf temp using Reed et al (1976) function J appl Ecol 13:925
      TminV=gddonset/10.  ! original -5.        !-Jiang Jiang 2015/10/13
      TmaxV=50.           ! Chris had these three parameters
      ToptV=35.

      TminJ=TminV
      TmaxJ=TmaxV
      ToptJ=ToptV

      Tlf=Tlkx-273.2
!      VcmxT=VJtemp(Tlf,TminV,TmaxV,ToptV,Vcmx1)
!      eJmxT=VJtemp(Tlf,TminJ,TmaxJ,ToptJ,eJmx1)
!     calculate J, the asymptote for RuBP regeneration rate at given Q
      eJ = weighJ*fJQres(eJmxT,alpha,Qaparx,theta)
!     calculate Kc, Ko, Rd gamma*  & gamma at leaf temp
      conKcT = EnzK(Tlkx,Trefk,conKc0,Rconst,Ekc)
      conKoT = EnzK(Tlkx,Trefk,conKo0,Rconst,Eko)
!     following de Pury 1994, eq 7, make light respiration a fixed proportion of
!     Vcmax
      Rd = 0.0089*VcmxT*weighR                              !de Pury 1994, Eq7
      Tdiff=Tlkx-Trefk
      gammas = gam0*(1.+gam1*Tdiff+gam2*Tdiff*Tdiff)       !gamma*
!     gamma = (gammas+conKcT*(1.+O2ci/conKoT)*Rd/VcmxT)/(1.-Rd/VcmxT)
      gamma = 0.0
!     ***********************************************************************
!     Analytical solution for ci. This is the ci which satisfies supply and demand
!     functions simultaneously
!     calculate X using Lohammer model, and scale for soil moisture
      a1= 1./(1.-0.7)
      X = a1*fwsoil/((co2csx - gamma)*(1.0 + Dleafx/Ds0))
!     calculate solution for ci when Rubisco activity limits A
      Gma = VcmxT
      Bta = conKcT*(1.0+ o2ci/conKoT)
      call ciandA(Gma,Bta,g0,X,Rd,co2Csx,gammas,co2ci2,Acx)  !co2ci2,Acx are the output variables
!     calculate +ve root for ci when RuBP regeneration limits A
      Gma = eJ/4.
      Bta = 2.*gammas
!    calculate coefficients for quadratic equation for ci
      call ciandA(Gma,Bta,g0,X,Rd,co2Csx,gammas,co2ci4,Aqx)
!     choose smaller of Ac, Aq
      sps=AMAX1(0.001,sps)                  !Weng, 3/30/2006
      !print*,'Aleafx',Acx,Aqx,Rd
      Aleafx = (amin1(Acx,Aqx) - Rd) !*sps     ! Weng 4/4/2006
!      if(Aleafx.lt.0.0) Aleafx=0.0    ! by Weng 3/21/2006
!    calculate new values for gsc, cs (Lohammer model)
      CO2csx = co2ca-Aleafx/Gbcx
      Gscx=g0 + X*Aleafx  ! revised by Weng
      return
      end
!***********************************************************************
      function funeJ(alpha,eJmxT,Qaparx)
      funeJ=alpha*Qaparx*eJmxT/(alpha*Qaparx+2.1*eJmxT)
      return
      end
!****************************************************************************
      real function esat(T)
!     returns saturation vapour pressure in Pa
      esat=610.78*exp(17.27*T/(T+237.3))
      return
      end

!****************************************************************************
      real function evapor(Td,Tw,Patm)
!* returns vapour pressure in Pa from wet & dry bulb temperatures
      gamma = (64.6 + 0.0625*Td)/1.e5
      evapor = esat(Tw)- gamma*(Td-Tw)*Patm
      return
      end

!****************************************************************************
      real function Vjmax(Tk,Trefk,Vjmax0,Eactiv,Edeact,Rconst,Entrop)
      anum = Vjmax0*EXP((Eactiv/(Rconst*Trefk))*(1.-Trefk/Tk))
      aden = 1. + EXP((Entrop*Tk-Edeact)/(Rconst*Tk))
      Vjmax = anum/aden
      return
      end
!****************************************************************************
      real function funE(extkbd,FLAIT)
      funE=(1.0-exp(-extkbd*FLAIT))/extkbd
      return
      end

!     ****************************************************************************
!     Reed et al (1976, J appl Ecol 13:925) equation for temperature response
!     used for Vcmax and Jmax
      real function VJtemp(Tlf,TminVJ,TmaxVJ,ToptVJ,VJmax0)
      if(Tlf.lt.TminVJ) Tlf=TminVJ   !constrain leaf temperatures between min and max
      if(Tlf.gt.TmaxVJ) Tlf=TmaxVJ
      pwr=(TmaxVJ-ToptVJ)/(ToptVj-TminVj)
      VJtemp=VJmax0*((Tlf-TminVJ)/(ToptVJ-TminVJ))*     &
     &       ((TmaxVJ-Tlf)/(TmaxVJ-ToptVJ))**pwr
      return
      end

!     ****************************************************************************
      real function fJQres(eJmx,alpha,Q,theta)
      AX = theta                                 !a term in J fn
      BX = alpha*Q+eJmx                          !b term in J fn
      CX = alpha*Q*eJmx                          !c term in J fn
      if((BX*BX-4.*AX*CX)>=0.0)then
          fJQres = (BX-SQRT(BX*BX-4.*AX*CX))/(2*AX)
      else
          fJQres = (BX)/(2*AX)                   !Weng 10/31/2008
      endif

      return
      end

!     *************************************************************************
      real function EnzK(Tk,Trefk,EnzK0,Rconst,Eactiv)

      temp1=(Eactiv/(Rconst* Trefk))*(1.-Trefk/Tk)
!      if (temp1<50.)then
      EnzK = EnzK0*EXP((Eactiv/(Rconst* Trefk))*(1.-Trefk/Tk))
!      else
!      EnzK = EnzK0*EXP(50.)                                          ! Weng 10/31/2008
!      endif

      return
      end

!     *************************************************************************
      real function sinbet(doy,lat,pi,timeh)
      real lat
!     sin(bet), bet = elevation angle of sun
!     calculations according to Goudriaan & van Laar 1994 P30
      rad = pi/180.
!     sine and cosine of latitude
      sinlat = sin(rad*lat)
      coslat = cos(rad*lat)
!     sine of maximum declination
      sindec=-sin(23.45*rad)*cos(2.0*pi*(doy+10.0)/365.0)
      cosdec=sqrt(1.-sindec*sindec)
!     terms A & B in Eq 3.3
      A = sinlat*sindec
      B = coslat*cosdec
      sinbet = A+B*cos(pi*(timeh-12.)/12.)
      return
      end

!     *************************************************************************
      subroutine yrday(doy,hour,lat,radsol,fbeam)
      real lat
      pi=3.14159256
      pidiv=pi/180.0
      slatx=lat*pidiv
      sindec=-sin(23.4*pidiv)*cos(2.0*pi*(doy+10.0)/365.0)
      cosdec=sqrt(1.-sindec*sindec)
      a=sin(slatx)*sindec
      b=cos(slatx)*cosdec
      sinbet=a+b*cos(2*pi*(hour-12.)/24.)
      solext=1370.0*(1.0+0.033*cos(2.0*pi*(doy-10.)/365.0))*sinbet

      tmprat=radsol/solext

      tmpR=0.847-1.61*sinbet+1.04*sinbet*sinbet
      tmpK=(1.47-tmpR)/1.66
      if(tmprat.le.0.22) fdiff=1.0
      if(tmprat.gt.0.22.and.tmprat.le.0.35) then
        fdiff=1.0-6.4*(tmprat-0.22)*(tmprat-0.22)
      endif
      if(tmprat.gt.0.35.and.tmprat.le.tmpK) then
        fdiff=1.47-1.66*tmprat
      endif
      if(tmprat.ge.tmpK) then
        fdiff=tmpR
      endif
      fbeam=1.0-fdiff
      if(fbeam.lt.0.0) fbeam=0.0
      return
      end


!===============================================================================
!========================================================
! Subroutine 1. Read parameters from file
    subroutine Getparameters(lat,longi,wsmax,wsmin,           &
    &   LAIMAX,LAIMIN,rdepth,Rootmax,Stemmax,           &
    &   SapR,SapS,SLA,GLmax,GRmax,Gsmax,stom_n,         &
    &   a1,Ds0,Vcmax0,extkU,xfang,alpha,                &
    &   Tau_Leaf,Tau_Wood,Tau_Root,Tau_F,Tau_C,         &
    &   Tau_Micro,Tau_slowSOM,Tau_Passive,              &
    &   gddonset,Q10,Rl0,Rs0,Rr0,parafile,              &
    &   r_me,Q10pro,kCH4,Omax,CH4_thre,Tveg,Tpro_me,Toxi,&
    &   f,bubprob,Vmaxfraction, &       !..int added for methane module
    &   Q10rh,JV,Entrpy, &                   ! added for acclimation study Feb 19 2019
	&	etaL,etaW,etaR,f_F2M,f_C2M,f_C2S,f_M2S,f_M2P,f_S2P,f_S2M,f_P2M) ! added for Sep 2019
    implicit none
    real lat,longi,wsmax,wsmin
    real LAIMAX,LAIMIN,rdepth,Rootmax,Stemmax
    real SapR,SapS,SLA,GLmax,GRmax,Gsmax,stom_n
    real a1,Ds0,Vcmax0,extkU,xfang,alpha
    real Tau_Leaf,Tau_Wood,Tau_Root,Tau_F,Tau_C
    real Tau_Micro,Tau_slowSOM,Tau_Passive
    real gddonset, Q10,Rl0,Rs0,Rr0
    character(len=50) parafile,commts
!   *** .int  added for par in methane module
    real r_me,Q10pro,kCH4,Omax,CH4_thre,Tveg,Tpro_me,Toxi
    real f,bubprob,Vmaxfraction
    real Q10rh,JV,Entrpy
	real etaL,etaW,etaR,f_F2M,f_C2M,f_C2S,f_M2S,f_M2P,f_S2P,f_S2M,f_P2M
!    integer first_year
    parafile=TRIM(parafile)
!   open and read input file for getting climate data

    open(10,file=parafile,status='old')
    read(10,11)commts
    read(10,*)lat,longi,wsmax,wsmin
    read(10,11)commts
    read(10,*)LAIMAX,LAIMIN,rdepth,Rootmax,Stemmax
    read(10,11)commts
    read(10,*)SapR,SapS,SLA,GLmax,GRmax,Gsmax,stom_n
    read(10,11)commts
    read(10,*)a1,Ds0,Vcmax0,extkU,xfang,alpha
    read(10,11)commts
    read(10,*)Tau_Leaf,Tau_Wood,Tau_Root,Tau_F,Tau_C,Tau_Micro,Tau_slowSOM,Tau_Passive
    read(10,11)commts
    read(10,*)gddonset,Q10,Rl0,Rs0,Rr0
!   *** ..int added for pars in methane module
    read(10,11)commts
    read(10,*)r_me,Q10pro,kCH4,Omax,CH4_thre,Tveg,Tpro_me,Toxi                      !this line is for MCMEME
    read(10,11)commts
    read(10,*)f,bubprob,Vmaxfraction
    read(10,11)commts
    read(10,*)Q10rh,JV,Entrpy
    read(10,11)commts
    read(10,*)etaL,etaW,etaR,f_F2M,f_C2M,f_C2S,f_M2S,f_M2P,f_S2P,f_S2M,f_P2M
!    read(10,11)commts
!    read(10,*)first_year
!   ***
11  format(a132)
    close(10)
    return
    end

!================================================================
! Subroutine 1.1 Read estimated parameters
    subroutine Getparaest(paraestfile,paraest,seq,npara,indexstring)
    implicit none

    character(len=50) paraestfile
    integer seq,m,n,istat6
    integer npara
    real paraest(npara+2,40000)
    character(len=250) indexstring

    paraestfile=TRIM(paraestfile)
    open(25,file=paraestfile,status='old',ACTION='read',     &
    &     IOSTAT=istat6)

!    read(25,*) npara
!    read(25,'(A)') indexstring


    m=0
!   open and read input file for getting climate data
    do
    m=m+1
!    write (*,*) 'paraestfile=',paraestfile
!    read(25,*,IOSTAT=istat6)(paraest(n,m),n=1,(npara))
    read(25,*,IOSTAT=istat6)(paraest(n,m),n=1,(npara+2))
!    read(25,'(i12,","),(f12.4,","),4(f15.4,",")',IOSTAT=istat6)(isimu_equ,paraest(n,m),n=1,(npara+1))
!    write(climatefile2,"(A120,A10,I3.3,A4)") trim(forcingdir),"/EMforcing_PBOT",rep,".csv"
!    format((i7),",",(i7),",",16(f15.4,","),(f15.4))
    if(istat6<0)exit
    enddo
    seq=m-1
    close(25)
    return
    end

! ====================================================================
! Subroutine 2. Read climatic forcing from file
    subroutine Getclimate(year_seq,doy_seq,hour_seq,          &
    &   forcing_data,climatefile,lines,yr_length)

    implicit none
    integer, parameter :: ilines=150000
    integer, parameter :: iiterms=18
    integer,dimension(ilines):: year_seq,doy_seq,hour_seq
    real forcing_data(iiterms,ilines)
    character(len=150) climatefile,commts
    integer m,n,istat1,lines,yr_length

    open(11,file=climatefile,status='old',ACTION='read',     &
    &     IOSTAT=istat1)
!     skip 2 lines of input met data file
      read(11,'(a160)') commts
    m=0  ! to record the lines in a file
    yr_length=0 ! to record years of a dataset
    do    ! read forcing files
        m=m+1
        read(11,*,IOSTAT=istat1)year_seq(m),      &
        &       doy_seq(m),hour_seq(m),           &
        &       (forcing_data(n,m),n=1,iiterms)
        if(istat1<0)exit
    enddo ! end of reading the forcing file
    lines=m-1
    yr_length=(year_seq(lines)-year_seq(1))+1
    close(11)    ! close forcing file
    return
    end

!===============================================================================
! Subroutine 3. read observation data from files
    subroutine GetObsData(obs_cflux,obs_cflux_hr,obs_cpool,obs_ch4flux,obs_ch4conc,&
		&	obs_soilwater,obs_soilt,obs_snow,obs_wt,obs_td,obs_soilprofc, &
		&	std_cflux,std_cflux_hr,std_cpool,std_ch4flux,std_ch4conc,&
		&	std_soilwater,std_soilt,std_snow,std_wt,std_td, &
        &   obsfile_cflux,obsfile_cflux_hr,obsfile_cpool,obsfile_ch4flux,obsfile_ch4conc,&
		&	obsfile_sw,obsfile_st,obsfile_soilprofc,&
        &   obsfile_snow,obsfile_wt,obsfile_thawd,use_plinit,&
        &   len_cflux,len_cflux_hr,len_cpool,len_ch4flux,len_ch4conc,len_sw,len_st,len_snow,len_wt,len_td,yr_length1)
!   ***
    implicit none
    real :: obs_cflux(5,yr_length1*365),obs_cpool(10,yr_length1*5),obs_ch4flux(2,yr_length1*365),obs_ch4conc(10,yr_length1*365)
	real :: obs_cflux_hr(7,yr_length1*500),std_cflux_hr(7,yr_length1*500)	!since using sparse data instead of eddy flux, otherwise would be yr_length1*365*24
    real :: obs_soilwater(4,yr_length1*365),obs_soilt(9,yr_length1*365),obs_snow(3,yr_length1*365)
    real :: obs_wt(3,yr_length1*365),obs_td(3,yr_length1*365),obs_soilprofc(150)
    real :: std_cflux(5,yr_length1*365),std_cpool(10,yr_length1*5),std_ch4flux(2,yr_length1*365),std_ch4conc(10,yr_length1*365)
    real :: std_soilwater(4,yr_length1*365),std_soilt(9,yr_length1*365),std_snow(3,yr_length1*365)
    real :: std_wt(3,yr_length1*365),std_td(3,yr_length1*365)
    real foliage,fnpp,wood,wnpp,root,rnpp,soilc,phenology,agb
    real foliage_sd,fnpp_sd,wood_sd,wnpp_sd,root_sd,rnpp_sd
    real soilc_sd,pheno_sd
    real CH4_flux,CH4_flux_sd,c10_mn,c10_sd,c15_mn,c15_sd,c25_mn,c25_sd,c50_mn,c50_sd,c75_mn,c75_sd
    real c100_mn,c100_sd,c150_mn,c150_sd,c180_mn,c180_sd,c200_mn,c200_sd
    real gpp,nee,reco,sw1,sw2,wt,td,snow_depth
    real gpp_sd,nee_sd,reco_sd,sw1_sd,sw2_sd
    real soiltsurf,soilt5,soilt10,soilt20,soilt40,soilt80,soilt160,soilt200

    integer days,m,istat1
    integer year,sdoy,yr_length1
    integer doy,hour !this row added for hourly obs data
    logical file_exists_cflux,file_exists_cflux_hr,file_exists_cpool,file_exists_ch4flux,file_exists_ch4conc
    logical file_exists_sw,file_exists_st,file_exists_snow,file_exists_wt,file_exists_td
    logical file_exists_soilprofc
    character(len=80) commts,obsfile_cflux,obsfile_cflux_hr,obsfile_cpool,obsfile_sw,obsfile_st,obsfile_soilprofc,&
            &   obsfile_snow,obsfile_wt,obsfile_thawd,obsfile_ch4flux,obsfile_ch4conc

    integer len_cflux,len_cflux_hr,len_cpool,len_ch4flux,len_ch4conc,len_sw,len_st,len_snow,len_wt,len_td
	integer use_plinit
!   *** carbon
    INQUIRE(FILE=obsfile_cflux, EXIST=file_exists_cflux)
    if(file_exists_cflux)then
        write (*,*) 'cflux exists'
       open(121,file=obsfile_cflux,status='old')
    end if
!   *******    hourly carbon flux obs
	INQUIRE(FILE=obsfile_cflux_hr, EXIST=file_exists_cflux_hr)
    if(file_exists_cflux_hr)then
        write (*,*) 'cflux_hr exists'
       open(125,file=obsfile_cflux_hr,status='old')
    end if
!   *********************************
    INQUIRE(FILE=obsfile_cpool, EXIST=file_exists_cpool)
    if(file_exists_cpool)then
        write (*,*) 'cpool exists'
       open(122,file=obsfile_cpool,status='old')
    end if
    INQUIRE(FILE=obsfile_ch4flux, EXIST=file_exists_ch4flux)
    if(file_exists_ch4flux)then
        write (*,*) 'ch4flux exists'
       open(123,file=obsfile_ch4flux,status='old')
    end if
	INQUIRE(FILE=obsfile_ch4conc, EXIST=file_exists_ch4conc)
    if(file_exists_ch4conc)then
        write (*,*) 'ch4conc exists'
       open(124,file=obsfile_ch4conc,status='old')
    end if

!   *** temperature, water, etc.
    INQUIRE(FILE=obsfile_sw, EXIST=file_exists_sw)
    if(file_exists_sw)then
        write (*,*) 'sw exists'
       open(131,file=obsfile_sw,status='old')
    end if
    INQUIRE(FILE=obsfile_st, EXIST=file_exists_st)
    if(file_exists_st)then
        write (*,*) 'st exists'
       open(132,file=obsfile_st,status='old')
    end if
    INQUIRE(FILE=obsfile_snow, EXIST=file_exists_snow)
    if(file_exists_snow)then
        write (*,*) 'snow exists'
       open(133,file=obsfile_snow,status='old')
    end if
    INQUIRE(FILE=obsfile_wt, EXIST=file_exists_wt)
    if(file_exists_wt)then
        write (*,*) 'wt exists'
       open(134,file=obsfile_wt,status='old')
    end if
    INQUIRE(FILE=obsfile_thawd, EXIST=file_exists_td)
    if(file_exists_td)then
        write (*,*) 'thawd exists'
       open(135,file=obsfile_thawd,status='old')
    end if
    INQUIRE(FILE=obsfile_soilprofc, EXIST=file_exists_soilprofc)
    if(file_exists_soilprofc)then
        write (*,*) 'soilprofc exists'
       open(140,file=obsfile_soilprofc,status='old')
    end if



!   *****************************
!   Observed daily carbon flux data	121

    if(file_exists_cflux)then
       write(*,*)'reading carbon flux data'
       m=0
       read (121,901) commts
	   do
!          if(mod(m,2) .eq. 0)then		!if input data in half hourly,ignore the half hour data
             read (121,*,IOSTAT=istat1)sdoy,gpp,gpp_sd,nee,nee_sd,reco,reco_sd
!          end if
              if(istat1<0)exit
              m=m+1
!              if(mod(m,2) .eq. 0)then
                 obs_cflux(1,m)=real(sdoy)
                 obs_cflux(2,m)=real(sdoy)
    !             obs_cflux(3,m/2)=hour

                 if(gpp .gt. -999)then
                   ! obs_cflux(4,m/2)=sum(gpp)  ! use to sum up half hours into a hour
                    obs_cflux(3,m)=gpp  !unit hourly flux
                 else
                    obs_cflux(3,m)=-9999
                 end if
                 if(nee .gt. -999)then
                    obs_cflux(4,m)=nee!-nee  ! double check negative or not
                 else
                    obs_cflux(4,m)=-9999
                 end if
                 if(reco .gt. -999)then
                    obs_cflux(5,m)=reco
                 else
                    obs_cflux(5,m)=-9999
                 end if
!   ***
                 std_cflux(1,m)=-9999
                 std_cflux(2,m)=-9999

                 if(gpp .gt. -999)then
				std_cflux(3,m)= 0.34!0.64!1.94!0.64 !0.5! 		! option B
			!if (gpp .ne. 0.) then
                        ! 	  std_cflux(3,m)=ABS(gpp)*0.3!		! option A
			!else
			! 	  std_cflux(3,m)=5.
			!endif
		 else
                    std_cflux(3,m)=-9999
                 endif

                 if(nee .gt. -999)then
  				std_cflux(4,m)= 0.34!0.34!0.34 !0.5!0.94          ! option B
			!if (nee   .ne. 0.) then
                        !	std_cflux(4,m)=ABS(nee)*0.3!		! option A
			!else
			!       std_cflux(4,m)=5.
			!endif
                 else
                    std_cflux(4,m)=-9999
                 endif

                 if(reco .gt. -999)then
				std_cflux(5,m)= 0.34!0.34!0.34 !0.5!.94	      ! option B
			!if (reco .ne. 0.) then
                        ! 	std_cflux(5,m)=ABS(reco)*0.3!	      ! option A
			!else
			!  std_cflux(5,m)=5.
			!endif
                 else
                    std_cflux(5,m)=-9999
                 endif
!              endif
           enddo
       len_cflux=m
 !      write(*,*)'warning: C flux standard deviation data is not read in'
 !      std_cflux(1:2,:) = -9999
 !      std_cflux(3:5,:) = 1.94
    end if
!   *****************************
!   *****************************
!   Observed houry carbon flux data	125

    if(file_exists_cflux_hr)then
       write(*,*)'reading carbon flux hourly data'
       m=0
       read (125,901) commts
	   do
!          if(mod(m,2) .eq. 0)then		!if input data in half hourly,ignore the half hour data
             read (125,*,IOSTAT=istat1) year,doy,hour,gpp,gpp_sd,nee,nee_sd,reco,reco_sd,CH4_flux,CH4_flux_sd
			 ! write (*,*) 'reading 125',year,doy,hour,gpp,gpp_sd,nee,nee_sd,reco,reco_sd,CH4_flux,CH4_flux_sd
!          end if
              if(istat1<0)exit
              m=m+1
                 obs_cflux_hr(1,m)=real(year)
                 obs_cflux_hr(2,m)=real(doy)
                 obs_cflux_hr(3,m)=real(hour)
                 if(gpp .gt. -999)then
                    obs_cflux_hr(4,m)=gpp  !unit hourly flux
                 else
                    obs_cflux_hr(4,m)=-9999
                 end if
                 if(nee .gt. -999)then
                    obs_cflux_hr(5,m)=nee!-nee  ! double check negative or not
                 else
                    obs_cflux_hr(5,m)=-9999
                 end if
                 if(reco .gt. -999)then
                    obs_cflux_hr(6,m)=reco
                 else
                    obs_cflux_hr(6,m)=-9999
                 end if
                 if(CH4_flux .gt. -999)then
                    obs_cflux_hr(7,m)=CH4_flux
                 else
                    obs_cflux_hr(7,m)=-9999
                 end if
				 ! write (*,*) 'obs_cflux_hr',obs_cflux_hr(4,m),obs_cflux_hr(5,m),obs_cflux_hr(6,m),obs_cflux_hr(7,m)
				 !   ***
                 std_cflux_hr(1,m)=-9999
                 std_cflux_hr(2,m)=-9999
				 std_cflux_hr(3,m)=-9999
                 if(gpp .gt. -999)then
					 if (use_plinit .eq. 11 .or. use_plinit .eq. 12 .or. use_plinit .eq. 14) then
						std_cflux_hr(4,m)= 0.02!0.016
					 else
						std_cflux_hr(4,m)= 0.03!0.024!gpp 0.64!1.94!0.64 !0.5! 		! option B
					 endif
					!if (gpp .ne. 0.) then
                        ! 	  std_cflux_hr(4,m)=ABS(gpp)*0.3!		! option A
			!else
			! 	  std_cflux_hr(4,m)=5.
			!endif
		 else
                    std_cflux_hr(4,m)=-9999
                 endif

              if(nee .gt. -999)then
				if (use_plinit .eq. 11 .or. use_plinit .eq. 12 .or. use_plinit .eq. 16) then
					std_cflux_hr(5,m)= 0.03!0.024!nee 0.34!0.34 !0.5!0.94          ! option B
				else
					std_cflux_hr(5,m)= 0.03!0.024
				endif
              else
                    std_cflux_hr(5,m)=-9999
              endif
				 !if (nee   .ne. 0.) then
                        !	std_cflux_hr(5,m)=ABS(nee)*0.3!		! option A
			!else
			!       std_cflux_hr(5,m)=5.
			!endif
                 if(reco .gt. -999)then
					 if (use_plinit .eq. 11 .or. use_plinit .eq. 12) then
						std_cflux_hr(6,m)= 0.008!0.0064
					 else
						std_cflux_hr(6,m)= 0.01!0.008
					 endif ! reco 0.34!0.34 !0.5!.94	      ! option B
			!if (reco .ne. 0.) then
                        ! 	std_cflux_hr(6,m)=ABS(reco)*0.3!	      ! option A
			!else
			!  std_cflux_hr(6,m)=5.
			!endif
                 else
                    std_cflux_hr(6,m)=-9999
                 endif
                 if(CH4_flux .gt. -999)then
					if (use_plinit .eq. 11 .or. use_plinit .eq. 12) then
						std_cflux_hr(7,m)= 0.004!0.0032
					else
						std_cflux_hr(7,m)= 0.005!0.004! ch4 0.34!0.34 !0.5!.94	      ! option B
					endif
			!if (CH4_flux .ne. 0.) then
                        ! 	std_cflux_hr(7,m)=ABS(CH4_flux)*0.3!	      ! option A
			!else
			!  std_cflux_hr(6,m)=5.
			!endif
                 else
                    std_cflux_hr(7,m)=-9999
                 endif
!              endif
           enddo
       len_cflux_hr=m
 !      write(*,*)'warning: C flux standard deviation data is not read in'
    end if
!   *****************************
!   Observed yearly carbon pool data	122
    if(file_exists_cpool)then
    m=0
       write(*,*)'reading pool and phenology data'
       read (122,901) commts
    do
!          read (122,*,IOSTAT=istat1)sdoy,foliage,foliage_sd,fnpp,fnpp_sd,wood,wood_sd,wnpp,wnpp_sd,&
!				&	root,root_sd,rnpp,rnpp_sd,soilc,soilc_sd,phenology,pheno_sd
          read (122,*,IOSTAT=istat1)sdoy,foliage,foliage_sd,wood,wood_sd,root,root_sd,phenology

          if(istat1<0)exit
            m=m+1
          obs_cpool(1,m)=real(sdoy)
          obs_cpool(2,m)=real(sdoy)
          if(foliage .gt. -999)then
             obs_cpool(3,m)=foliage
          else
             obs_cpool(3,m)=-9999
          end if
!          if(fnpp .gt. -999)then
!             obs_cpool(4,m)=fnpp
!          else
             obs_cpool(4,m)=-9999
!          end if
          if(wood .gt. -999)then
             obs_cpool(5,m)=wood
          else
             obs_cpool(5,m)=-9999
          end if
!          if(wnpp .gt. -999)then
!             obs_cpool(6,m)=wnpp
!          else
             obs_cpool(6,m)=-9999
!          end if
         if(root .gt. -999)then
            obs_cpool(7,m)=root
         else
             obs_cpool(7,m)=-9999
         end if
!          if(rnpp .gt. -999)then
!             obs_cpool(8,m)=rnpp
!          else
             obs_cpool(8,m)=-9999
!          end if
!          if(soilc .gt. -999)then
!             obs_cpool(9,m)=soilc
!          else
             obs_cpool(9,m)=-9999
!          end if
         ! if(phenology .gt. -999)then
            ! obs_cpool(10,m)=phenology
         ! else
             obs_cpool(10,m)=-9999
         ! end if

          std_cpool(1,m)=-9999
          std_cpool(2,m)=-9999
          if(foliage .gt. -999)then
!           std_cpool(3,m)=foliage_sd
	    std_cpool(3,m)=60!15.
          else
             std_cpool(3,m)=-9999
          end if
!          if(fnpp .gt. -999)then
!             std_cpool(4,m)=fnpp_sd
!          else
             std_cpool(4,m)=-9999
!          end if
          if(wood .gt. -999)then
!             std_cpool(5,m)=wood_sd
			std_cpool(5,m)=120.
          else
             std_cpool(5,m)=-9999
          end if
!          if(wnpp .gt. -999)then
!             std_cpool(6,m)=wnpp_sd
!          else
             std_cpool(6,m)=-9999
!          end if
         if(root .gt. -999)then
            ! std_cpool(7,m)=root_sd
			std_cpool(7,m)=15.
         else
             std_cpool(7,m)=-9999
         end if
!          if(rnpp .gt. -999)then
!             std_cpool(8,m)=rnpp_sd
!          else
             std_cpool(8,m)=-9999
!          end if
!          if(soilc .gt. -999)then
!             std_cpool(9,m)=soilc_sd
!          else
             std_cpool(9,m)=-9999
!          end if
         if(phenology .gt. -999)then
            ! std_cpool(10,m)=pheno_sd
			std_cpool(10,m)=15.
         else
             std_cpool(10,m)=-9999
         end if
    enddo
	   len_cpool=m
    end if
!            write (*,*) file_exists_ch4flux
!   *****************************
!   Observed daily ch4 flux	123
    if(file_exists_ch4flux)then

    m=0
       write(*,*)'reading ch4 flux'
       read (123,901) commts		!
    do
                read (123,*,IOSTAT=istat1)sdoy,CH4_flux,CH4_flux_sd
                if(istat1<0) exit
                m=m+1
!                obs_ch4flux(1,m)=real(year)
                obs_ch4flux(1,m)=real(sdoy)
                if(CH4_flux .gt. -999)then
                    obs_ch4flux(2,m)=CH4_flux
                else
                    obs_ch4flux(2,m)=-9999
                endif
                std_ch4flux(1,m)=-9999
!                if(CH4_flux_sd .gt. -999)then
!                std_ch4flux(2,m)=CH4_flux_sd
                if(CH4_flux .gt. -999)then
            std_ch4flux(2,m)=0.1
                else
                    std_ch4flux(2,m)=-9999
                endif
    enddo
            len_ch4flux=m
    endif
!   *****************************
!   Observed daily ch4 conc	124
    if(file_exists_ch4conc)then
       m=0
       write(*,*)'reading ch4 concentration'
	read (124,901) commts		!
            do
		read (124,*,IOSTAT=istat1)sdoy,c10_mn,c10_sd,c15_mn,c15_sd,c25_mn,c25_sd,c50_mn,c50_sd,  &
			& c75_mn,c75_sd,c100_mn,c100_sd,c150_mn,c150_sd,c180_mn,c180_sd,c200_mn,c200_sd		!recble variables
		if(istat1<0) exit
                m=m+1
		obs_ch4conc(1,m)=real(sdoy)
		obs_ch4conc(2,m)=c10_mn
                obs_ch4conc(3,m)=c15_mn
                obs_ch4conc(4,m)=c25_mn
                obs_ch4conc(5,m)=c50_mn
                obs_ch4conc(6,m)=c75_mn
                obs_ch4conc(7,m)=c100_mn
                obs_ch4conc(8,m)=c150_mn
                obs_ch4conc(9,m)=c180_mn
                obs_ch4conc(10,m)=c200_mn

		std_ch4conc(1,m)=-9999
                std_ch4conc(2,m)=c10_sd
                std_ch4conc(3,m)=c15_sd
                std_ch4conc(4,m)=c25_sd
                std_ch4conc(5,m)=c50_sd
                std_ch4conc(6,m)=c75_sd
                std_ch4conc(7,m)=c100_sd
                std_ch4conc(8,m)=c150_sd
                std_ch4conc(9,m)=c180_sd
                std_ch4conc(10,m)=c200_sd
            enddo
            len_ch4conc=m
                endif
!                    write (*,*) file_exists_sw
!   *****************************
!   Observed daily soil water data	131
    if(file_exists_sw)then
    m=0
       write(*,*)'reading soil water data'
       read (131,901) commts
    do
             read (131,*,IOSTAT=istat1)year,sdoy,sw1,sw1_sd,sw2,sw2_sd
             if(istat1<0)exit
        m=m+1
        obs_soilwater(1,m)=real(year)
             obs_soilwater(2,m)=real(sdoy)
             if(sw1 .gt. -1000 .and. sw1 .lt. 1000)then
                obs_soilwater(3,m)=sw1
             else
                obs_soilwater(3,m)=-9999
             endif
             if(sw2 .gt. -1000 .and. sw2 .lt. 1000)then
                obs_soilwater(4,m)=sw2
             else
                obs_soilwater(4,m)=-9999
             endif

             std_soilwater(1,m)=-9999
             std_soilwater(2,m)=-9999
             if(sw1 .gt. -1000 .and. sw1 .lt. 1000)then
                std_soilwater(3,m)=sw1
             else
                std_soilwater(3,m)=-9999
             endif
             if(sw2 .gt. -1000 .and. sw2 .lt. 1000)then
                std_soilwater(4,m)=sw2
             else
                std_soilwater(4,m)=-9999
             endif
    enddo
       len_sw=m
	   ! use one value
       !std_soilwater(1:2,:) = -9999
       !std_soilwater(3,:)   = 0.02*2.5
       !std_soilwater(4,:)   = 0.011*2.5
    end if
!    write (*,*) file_exists_st
!   *****************************
!   Observed hourly soil temperature data	132
    if(file_exists_st)then
    m=0
       write(*,*)'reading soil temperature data'
       read (132,901) commts
    do
!          print*,'m=',m
!              if(mod(m,2) .eq. 0)then
                 read(132,*,IOSTAT=istat1)year,sdoy,hour,soilt5,soilt10,soilt20,soilt40,soilt80,soilt160,soilt200
!              end if
              if(istat1<0)exit
        m=m+1
!              if(mod(m,2) .eq. 0)then
        obs_soilt(1,m)=real(year)
                 obs_soilt(2,m)=real(sdoy)
    !             obs_soilt(3,m/2)=real(hour)
                 if(soilt5 .gt. -100 .and. soilt5 .lt. 200)then
                    obs_soilt(3,m)=soilt5
                 else
                    obs_soilt(3,m)=-9999
                 end if
                 if(soilt10 .gt. -100 .and. soilt10 .lt. 200)then
                    obs_soilt(4,m)=soilt10
                 else
                    obs_soilt(4,m)=-9999
                 end if
                 if(soilt20 .gt. -100 .and. soilt20 .lt. 200)then
                    obs_soilt(5,m)=soilt20
                 else
                    obs_soilt(5,m)=-9999
                 end if
                 if(soilt40 .gt. -100 .and. soilt40 .lt. 200)then
                    obs_soilt(6,m)=soilt40
                 else
                    obs_soilt(6,m)=-9999
                 end if
                 if(soilt80 .gt. -100 .and. soilt80 .lt. 200)then
                    obs_soilt(7,m)=soilt80
                 else
                    obs_soilt(7,m)=-9999
                 end if
                 if(soilt160 .gt. -100 .and. soilt160 .lt. 200)then
                    obs_soilt(8,m)=soilt160
                 else
                    obs_soilt(8,m)=-9999
                 end if
                 if(soilt200 .gt. -100 .and. soilt200 .lt. 200)then
                    obs_soilt(9,m)=soilt200
                 else
                    obs_soilt(9,m)=-9999
                 end if
!              end if
    enddo
       len_st=m

!   *****************************
       std_soilt(1:2,:) = -9999
       std_soilt(3,:)   = 0.5*4
       std_soilt(4,:)   = 0.36*2.5
       std_soilt(5,:)   = 0.26*2.5
       std_soilt(6:9,:) = 0.18*2.5
    end if
!    write (*,*) file_exists_snow
!   *****************************
!   Observed daily snow_depth	133
    if(file_exists_snow)then
    m=0
       write(*,*)'reading snow depth data'
       read (133,901) commts
    do
              read (133,*,IOSTAT=istat1)year,sdoy,snow_depth
              if(istat1<0)exit
        m=m+1
              obs_snow(1,m)=real(year)
              obs_snow(2,m)=real(sdoy)
              if(snow_depth .gt. -999)then
                 obs_snow(3,m)=snow_depth
              else
                 obs_snow(3,m)=-9999
              end if
    enddo
	   ! assign a empirical value for snow depth standard deviation, can replace with obs_std
	   std_snow(1:2,:) = -9999
           std_snow(3,:)   = 2.
           len_snow=m
    end if
!    write (*,*) file_exists_wt
!   *****************************
!   Observed daily water table	134
    if(file_exists_wt)then
    m=0
       write(*,*)'reading water table depth data'  !double check: unit mm, belowground negative value
       read (134,901) commts
    do
              read (134,*,IOSTAT=istat1)year,sdoy,wt
              if(istat1<0)exit
        m=m+1
              obs_wt(1,m)=real(year)
              obs_wt(2,m)=real(sdoy)
              if(wt .gt. -9000)then
                 obs_wt(3,m)=wt
              else
                 obs_wt(3,m)=-9999
              end if
    enddo
       len_wt=m
       std_wt(1:2,:)=-9999
       std_wt(3,:)=50
    end if
!   *****************************
!   Observed daily thaw depth    135
    if(file_exists_td)then
       m=0
       write(*,*)'reading thaw depth data'
       read (135,901) commts
	   do
              read (135,*,IOSTAT=istat1)year,sdoy,td
              if(istat1<0)exit
              m=m+1
              obs_td(1,m)=real(year)
              obs_td(2,m)=real(sdoy)
              if(td .gt. -999)then
                 obs_td(3,m)=td
              else
                 obs_td(3,m)=-9999
              end if
       enddo
       len_td=m
       std_td(1:2,:)=-9999
       std_td(3,:)=10
    end if
!   *****************************
!   Observed soil carbon profile
  write (*,*) 'file_exists_soilprofc',file_exists_soilprofc
    if(file_exists_soilprofc)then
        write(*,*)'reading soilprofile c data'
       read (140,*,IOSTAT=istat1) (obs_soilprofc(m),m=1,150)
    end if

!    write (*,*) 'before closing the file',file_exists_cflux,obsfile_cflux
!   *** carbon

    if(file_exists_cflux)then
!        write (*,*) '121 cflux closed'
       close(121)
    end if

    if(file_exists_cpool)then
!        write (*,*) '122 cpool closed'
       close(122)
    end if

    if(file_exists_ch4flux)then
!        write (*,*) '123 ch4flux closed'
       close(123)
    end if

    if(file_exists_ch4conc)then
!        write (*,*) '124 ch4conc closed'
       close(124)
    end if

    if(file_exists_cflux_hr)then
!        write (*,*) '125 cflux_hr closed'
       close(125)
    end if
!   *** temperature, water, etc.

    if(file_exists_sw)then
!        write (*,*) '131 sw closed'
       close(131)
    end if

    if(file_exists_st)then
!        write (*,*) '132 st closed'
       close(132)
    end if

    if(file_exists_snow)then
!        write (*,*) '133 snow closed'
    close(133)
    end if

    if(file_exists_wt)then
!        write (*,*) '134 wt closed'
    close(134)
    end if

    if(file_exists_td)then
!        write (*,*) '135 thawd closed'
    close(135)
    end if

    if(file_exists_soilprofc)then
!        write (*,*) '140 soilprofc closed'
       close(140)
    end if

    901 format(a80)

!    close(121)
!    close(122)
!    close(123)
!    close(124)
!    close(131)
!    close(132)
!    close(133)
!    close(134)
!    close(135)
!    close(140)
!    write (*,*) 'after closing the file'
    return
    end

! *******************************************************
!   *** ..int
! add subroutines for CWE int

  !Subroutine  Read water table from file   Yuanyuan
    subroutine Getwatertable(year_seq,doy_seq,hour_seq,          &
    &   water_table,watertablefile,lines,yr_length)

    implicit none
    integer, parameter :: ilines=90000
    integer,dimension(ilines):: year_seq,doy_seq,hour_seq
    real water_table(ilines)
    character(len=50) watertablefile,commts
    integer m,n,istat1,lines,yr_length
    real water_table_read
    integer year,doy,hour,istat111

    open(111,file=watertablefile,status='old',ACTION='read',     &
    &     IOSTAT=istat1)
!     skip 2 lines of input met data file
    read(111,'(a160)') commts
    m=0  ! to record the lines in a file

    do
        m=m+1
        read (111,*,IOSTAT=istat111)year,doy,hour,water_table_read
        if(istat111<0)exit
        water_table(m)=water_table_read

    enddo


    close(111)    ! close watertable file
    return
    end


    subroutine getteco_output(output_data)

    implicit none
    integer, parameter :: ilines=150000
    integer, parameter :: miterms=29
    real output_data(miterms,ilines)
    character(len=50) commts,outdir,outfile
    integer m,n,istat5

!    integer, parameter :: npools=5
!    integer, parameter :: nlayers=10
!    real Rh_pools(npools,ilines),wsc(nlayers,ilines)
!    real,dimension(ilines):: zwt,Tsoil
!!
!    outdir = 'output'
!    write(outfile,"(A120,A16)") trim(outdir),"/TECO_output.csv"
!    outfile = trim(outfile)
!    outfile = adjustl(outfile)

    open(83,file='TECO_output.csv',status='old',ACTION='read',     &
    &     IOSTAT=istat5)

!    open(83,file='TECO_output.csv',status='old',ACTION='read',     &
!    &     IOSTAT=istat5)

    read(83,803) commts
    m=0   ! to record the lines in a file		same as counting the lines
    do    ! read teco_output data file
        m=m+1
        read(83,*,IOSTAT=istat5)(output_data(n,m),n=1,miterms)
!        write (*,*) output_data(1,m)
        if(istat5<0)exit
    enddo ! end of reading the teco_output data file

803     format(a80)
    close(83)    ! close teco_output data file
    return
    end


 !Subroutine  Read snow_depth from file   Yuanyuan
    subroutine Getsnowdepth(year_seq,doy_seq,hour_seq,          &
    &   snow_in,snowdepthfile,lines,yr_length)

    implicit none
    integer, parameter :: ilines=90000
    integer,dimension(ilines):: year_seq,doy_seq,hour_seq
    real snow_in(ilines)
    character(len=50) snowdepthfile,commts
    integer m,n,istat1,lines,yr_length
    real snow_depth_read
    integer year,doy,hour,istat111

    open(1111,file=snowdepthfile,status='old',ACTION='read',     &
    &     IOSTAT=istat1)
!     skip 2 lines of input met data file
    read(1111,'(a160)') commts
    m=0  ! to record the lines in a file

    do
        !write(*,*)'snow_inaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
        m=m+1
        !write(*,*)'mmm',m
        read (1111,*,IOSTAT=istat111)year,doy,hour,snow_depth_read
        if(istat111<0)exit
        snow_in(m)=snow_depth_read

    enddo


    close(1111)    ! close snow depth file
    return
    end


! *******************************************************
!   ***
!========================================================
! Subroutine: Read Data assimilation check box file
    subroutine GetDAcheckbox(DApar,parmin,parmax,DAparfile,partotal)

    implicit none
    integer,intent(in)::partotal
    integer,dimension(partotal):: DApar
    real,dimension(partotal):: parmin,parmax
    character(len=50) DAparfile,commts

    DAparfile=TRIM(DAparfile)
    DAparfile = adjustl(DAparfile)
    print*,'DAparfile=',DAparfile,partotal

    open(15,file=DAparfile,status='old')
    read(15,11)commts
    read(15,*)DApar(1),DApar(2),DApar(3),DApar(4)
    read(15,11)commts
    read(15,*)DApar(5),DApar(6),DApar(7),DApar(8),DApar(9)
    read(15,11)commts
    read(15,*)DApar(10),DApar(11),DApar(12),DApar(13),DApar(14),DApar(15),DApar(16)
    read(15,11)commts
    read(15,*)DApar(17),DApar(18),DApar(19),DApar(20),DApar(21),DApar(22)
    read(15,11)commts
    read(15,*)DApar(23),DApar(24),DApar(25),DApar(26),DApar(27),DApar(28),DApar(29),DApar(30)
    read(15,11)commts
    read(15,*)DApar(31),DApar(32),DApar(33),DApar(34),DApar(35)
    read(15,11)commts
    read(15,*)DApar(36),DApar(37),DApar(38),DApar(39),DApar(40),DApar(41),DApar(42),DApar(43)
    read(15,11)commts
    read(15,*)DApar(44),DApar(45),DApar(46)
    read(15,11)commts
    read(15,*)DApar(47),DApar(48),DApar(49)
    read(15,11)commts
    read(15,*)DApar(50),DApar(51),DApar(52),DApar(53),DApar(54),DApar(55),DApar(56), &
	& DApar(57),DApar(58),DApar(59),DApar(60)

    read(15,11)commts
    read(15,*)parmin(1),parmin(2),parmin(3),parmin(4)
    read(15,11)commts
    read(15,*)parmin(5),parmin(6),parmin(7),parmin(8),parmin(9)
    read(15,11)commts
    read(15,*)parmin(10),parmin(11),parmin(12),parmin(13),parmin(14),parmin(15),parmin(16)
    read(15,11)commts
    read(15,*)parmin(17),parmin(18),parmin(19),parmin(20),parmin(21),parmin(22)
    read(15,11)commts
    read(15,*)parmin(23),parmin(24),parmin(25),parmin(26),parmin(27),parmin(28),parmin(29),parmin(30)
    read(15,11)commts
    read(15,*)parmin(31),parmin(32),parmin(33),parmin(34),parmin(35)
    read(15,11)commts
    read(15,*)parmin(36),parmin(37),parmin(38),parmin(39),parmin(40),parmin(41),parmin(42),parmin(43)
    read(15,11)commts
    read(15,*)parmin(44),parmin(45),parmin(46)
    read(15,11)commts
    read(15,*)parmin(47),parmin(48),parmin(49)
    read(15,11)commts
    read(15,*)parmin(50),parmin(51),parmin(52),parmin(53),parmin(54),parmin(55),parmin(56), &
	&	parmin(57),parmin(58),parmin(59),parmin(60)

    read(15,11)commts
    read(15,*)parmax(1),parmax(2),parmax(3),parmax(4)
    read(15,11)commts
    read(15,*)parmax(5),parmax(6),parmax(7),parmax(8),parmax(9)
    read(15,11)commts
    read(15,*)parmax(10),parmax(11),parmax(12),parmax(13),parmax(14),parmax(15),parmax(16)
    read(15,11)commts
    read(15,*)parmax(17),parmax(18),parmax(19),parmax(20),parmax(21),parmax(22)
    read(15,11)commts
    read(15,*)parmax(23),parmax(24),parmax(25),parmax(26),parmax(27),parmax(28),parmax(29),parmax(30)
    read(15,11)commts
    read(15,*)parmax(31),parmax(32),parmax(33),parmax(34),parmax(35)
    read(15,11)commts
    read(15,*)parmax(36),parmax(37),parmax(38),parmax(39),parmax(40),parmax(41),parmax(42),parmax(43)
    read(15,11)commts
    read(15,*)parmax(44),parmax(45),parmax(46)
    read(15,11)commts
    read(15,*)parmax(47),parmax(48),parmax(49)
    read(15,11)commts
    read(15,*)parmax(50),parmax(51),parmax(52),parmax(53),parmax(54),parmax(55),parmax(56), &
	&	parmax(57),parmax(58),parmax(59),parmax(60)

11  format(a132)
    close(15)
    return
    end



! **********************************************************
    subroutine getCov(gamma,covfile,npara)
    implicit none
    integer npara,i,k
    real gamma(npara,npara)
    character(len=80) covfile

    open(14,file=covfile,status='old')

    do i=1,npara
        read (14,*)(gamma(i,k),k=1,npara)
    enddo
    return
    end



!========================================================================
!    	cost function for observed data

    subroutine costFObsNee(Simu_dailyflux,Simu_hrflux,Simu_soilwater,Simu_soiltemp,Simu_dailysoilt, &
		 & Simu_dailywatertable,Simu_dailywater,Simu_snowdepth,Simu_TD,Simu_dailyCH4, &
                 & obs_cflux,obs_cflux_hr,obs_cpool,obs_ch4flux,obs_ch4conc, &
		 & obs_soilwater,obs_soilt,obs_snow,obs_wt,obs_td,obs_soilprofc, &
                 & std_cflux,std_cflux_hr,std_cpool,std_ch4flux,std_ch4conc, &
		 & std_soilwater,std_soilt,std_snow,std_wt,std_td, &
                 & len_cflux,len_cflux_hr,len_cpool,len_ch4flux,len_ch4conc,len_sw,len_st,len_snow,len_wt,len_td,yr_length1, &
		 & J_last,upgraded,isimu,JNAN, &
                 & do_soilt_da,do_snow_da,do_watertable_da,do_methane_da,do_co2_da,do_soilwater_da, &
                 & use_cflux_ob,use_cflux_hr_ob,use_cpool_ob,use_ch4flux_ob,use_ch4conc_ob, &
		 & use_soilwater_ob,use_soilt_ob,use_snow_ob,use_watertable_ob,use_td_ob,use_plinit)

    implicit none
    integer yr_length1
    real Simu_dailyflux(15,yr_length1*365),Simu_soilwater(30,yr_length1*365),Simu_soiltemp(11,yr_length1*365)
	real Simu_hrflux(4,yr_length1*500)
    real Simu_dailywatertable(1,yr_length1*365),Simu_dailyCH4(17,yr_length1*365),Simu_snowdepth(1,yr_length1*365),&
         Simu_TD(1,yr_length1*365),Simu_dailysoilt(11,yr_length1*365),Simu_dailywater(31,yr_length1*365)
    real :: obs_cflux(5,yr_length1*365),obs_cpool(10,yr_length1*5),obs_ch4flux(2,yr_length1*365),obs_ch4conc(10,yr_length1*365)
	real :: obs_cflux_hr(7,yr_length1*500),std_cflux_hr(7,yr_length1*500)
    real :: obs_soilwater(4,yr_length1*365),obs_soilt(9,yr_length1*365),obs_snow(3,yr_length1*365)
    real :: obs_wt(3,yr_length1*365),obs_td(3,yr_length1*365),obs_soilprofc(150)
	real :: std_cflux(5,yr_length1*365),std_cpool(10,yr_length1*5),std_ch4flux(2,yr_length1*365),std_ch4conc(10,yr_length1*365)
    real :: std_soilwater(4,yr_length1*365),std_soilt(9,yr_length1*365),std_snow(3,yr_length1*365)
    real :: std_wt(3,yr_length1*365),std_td(3,yr_length1*365)

    integer day,year,isimu,JNAN

    real J_new,J_last,delta_J,acrate,stdm,stdmc
    real J_gpp,J_nee,J_reco,J_foliage,J_fnpp,J_wood,J_wnpp,J_root,J_rnpp,J_soilc,J_pheno
	real J_gpp_hr,J_nee_hr,J_reco_hr,J_CH4flux_hr
    real J_sw1,J_sw2,J_snow,J_ThawD,J_dwatertable
    real J_dsoilt1,J_dsoilt2,J_dsoilt3,J_dsoilt4,J_dsoilt5,J_dsoilt6!,J_dsoilt7
    real J_CH4flux,J_CH4conc1,J_CH4conc2,J_CH4conc3,J_CH4conc4,J_CH4conc5,J_CH4conc6,J_CH4conc7
    integer j1,j2,j3,j4,j5,j6,j7,j8,j9,j10,j11,j_sn1,j_td1
	integer j1_hr,j2_hr,j3_hr,jch4_hr
    integer j_dwt1,j_dwtdaily
    integer j_ds1,j_ds2,j_ds3,j_ds4,j_ds5,j_ds6!,j_ds7
    integer jch4,jch4c1,jch4c2,jch4c3,jch4c4,jch4c5,jch4c6,jch4c7
!    real Simu_maxgpp,Simu_maxnee,Simu_maxreco,Simu_anngpp,Simu_annnee,Simu_annreco,obs_anngpp,obs_annnee,obs_annreco
    real dObsSim,random_harvest,obs_maxtd
    integer i,upgraded,len1,len2,l,m
    integer len_cflux,len_cpool,len_ch4flux,len_ch4conc,len_sw,len_st,len_snow,len_wt,len_td
    integer len_cflux_hr


    integer use_cflux_ob,use_cflux_hr_ob,use_cpool_ob,use_ch4flux_ob,use_ch4flux_hr_ob,use_ch4conc_ob
    integer use_soilwater_ob,use_soilt_ob,use_snow_ob,use_watertable_ob,use_td_ob,use_plinit
    real r_num

    logical do_soilt_da, do_snow_da, do_watertable_da,do_methane_da,do_co2_da,do_soilwater_da,file_exists,use_nodata
!    logical,save:: data_exist_gpp=.false.,data_exist_nee=.false.,data_exist_reco=.false.,data_exist_soilc=.false.,&
 !                  data_exist_sw1=.false.,data_exist_sw2=.false.,data_exist_soilt1=.false.,data_exist_soilt2=.false.,&
 !                  data_exist_soilt3=.false.,data_exist_soilt4=.false.,data_exist_dwatertable=.false.,data_exist_agb=.false.,&
!                   data_exist_snow=.false.,data_exist_ThawD=.false.,data_exist_gppmax=.false.,data_exist_neemax=.false.,&
 !                  data_exist_recomax=.false.  !!! doublecheck I dont think they are useful
!    compute J_obs
!   print*,'begin of costF',do_watertable_da
   use_nodata=(use_soilt_ob+use_snow_ob+use_watertable_ob+use_cflux_ob+use_cflux_hr_ob+use_cpool_ob+use_soilwater_ob+ &
			& 	use_td_ob+use_ch4flux_ob+use_ch4conc_ob .eq. 0)
   J_new = 0

   if (isimu .eq. 1) then
       JNAN=0.
   endif


 !     INQUIRE(file='fort.1104',exist=file_exists)
 !     if(.not. file_exists)then
 !        open(1104,file='fort.1104')
 !     end if
    if (do_co2_da) then
			J_gpp=0.0
			  !J_gppann=0.0
			J_nee=0.0
			  !J_neeann=0.0
			  J_reco=0.0
			  !J_recoann=0.0
			J_foliage=0.0
			J_fnpp=0.0
			J_wood=0.0
			J_wnpp=0.0
			J_root=0.0
			J_rnpp=0.0
			J_soilc=0.0
			  !J_agb=0.0 if is_grass then foliage
			J_pheno=0.0
			j1=0
			j2=0
			j3=0
			j4=0
			j5=0
			j6=0
			j7=0
			j8=0
			j9=0
			j10=0
			j11=0
		if (use_cflux_ob .eq. 1) then
			do i=1,len_cflux
              day=int(obs_cflux(2,i))
			  if (day .gt. 1460) then  ! use data from 2015-2018 for acclimation effect study
             ! if (use_cflux_ob .eq. 1 .and. day .gt. 1095) then  ! use data from 2014-2018 for acclimation effect study
!              if (use_cflux_ob .eq. 1 .and. day .lt. 1096) then  ! use data from 2011-2014 for acclimation effect study
                   if(obs_cflux(3,i).gt.-999)then
                       j1 = j1 + 1
                       dObsSim=Simu_dailyflux(1,day)-obs_cflux(3,i)
                       J_gpp=J_gpp+(dObsSim*dObsSim)/(2*std_cflux(3,i)*std_cflux(3,i))
!                       print*,'day',day,'Simu_dailyflux(1,day)',Simu_dailyflux(1,day),'obs_cflux(3,i)',obs_cflux(3,i)
!                    write (*,*) 'gpp dObsSim',dObsSim,'std_cflux(3,i)',std_cflux(3,i)
                   endif

                   if(obs_cflux(4,i).gt.-999)then
            j2=j2+1
                       dObsSim=Simu_dailyflux(2,day)-obs_cflux(4,i)
                       J_nee=J_nee+(dObsSim*dObsSim)/(2*std_cflux(4,i)*std_cflux(4,i))

!       		   print*,'day',day,'Simu_dailyflux(2,day)',Simu_dailyflux(2,day),'obs_cflux(4,i)',obs_cflux(4,i)
! 		   write (*,*) 'nee dObsSim',dObsSim,'std_cflux(4,i)',std_cflux(4,i)
                   endif

                   if(obs_cflux(5,i).gt.-999)then
            j3=j3+1
                       dObsSim=Simu_dailyflux(3,day)-obs_cflux(5,i)
                       J_reco=J_reco+(dObsSim*dObsSim)/(2*std_cflux(5,i)*std_cflux(5,i))
!				print*,'day',day,'Simu_dailyflux(3,day)',Simu_dailyflux(3,day),'obs_cflux(5,i)',obs_cflux(5,i)
!		       write (*,*) 'reco dObsSim',dObsSim,'std_cflux(5,i)',std_cflux(5,i)
                   endif

              endif
			enddo
		endif
!   ******** cost function for hourly carbon flux *****************
			J_gpp_hr=0.0
			J_nee_hr=0.0
			J_reco_hr=0.0
			J_CH4flux_hr=0.0
			j1_hr=0
			j2_hr=0
			j3_hr=0
			jch4_hr=0
		if (use_cflux_hr_ob .eq. 1) then
		! write (*,*) 'len_cflux_hr',len_cflux_hr,obs_cflux_hr
			do i=1,len_cflux_hr
              day=int(obs_cflux_hr(2,i))
			  ! if (day .gt. 1460) then  ! use data from 2015-2018 for acclimation effect study
             ! if (use_cflux_ob .eq. 1 .and. day .gt. 1095) then  ! use data from 2014-2018 for acclimation effect study
!              if (use_cflux_ob .eq. 1 .and. day .lt. 1096) then  ! use data from 2011-2014 for acclimation effect study
                   if(obs_cflux_hr(4,i).gt.-999)then
                       j1_hr=j1_hr+1
                       dObsSim=Simu_hrflux(1,i)-obs_cflux_hr(4,i)
                       J_gpp_hr=J_gpp_hr+(dObsSim*dObsSim)/(2*std_cflux_hr(4,i)*std_cflux_hr(4,i))
                      ! print*,'day',day,'Simu_hrflux(1,i)',Simu_hrflux(1,i),'obs_cflux_hr(4,i)',obs_cflux_hr(4,i)
                   ! write (*,*) 'gpp dObsSim',dObsSim,'std_cflux_hr(4,i)',std_cflux_hr(4,i)
                   endif

                   if(obs_cflux_hr(5,i).gt.-999)then
            j2_hr=j2_hr+1
                       dObsSim=Simu_hrflux(2,i)-obs_cflux_hr(5,i)
                       J_nee_hr=J_nee_hr+(dObsSim*dObsSim)/(2*std_cflux_hr(5,i)*std_cflux_hr(5,i))

      		   ! print*,'day',day,'Simu_hrflux(2,i)',Simu_hrflux(2,i),'obs_cflux_hr(5,i)',obs_cflux_hr(5,i)
		   ! write (*,*) 'nee dObsSim',dObsSim,'std_cflux_hr(5,i)',std_cflux_hr(5,i)
                   endif

                   if(obs_cflux_hr(6,i).gt.-999)then
            j3_hr=j3_hr+1
                       dObsSim=Simu_hrflux(3,i)-obs_cflux_hr(6,i)
                       J_reco_hr=J_reco_hr+(dObsSim*dObsSim)/(2*std_cflux_hr(6,i)*std_cflux_hr(6,i))
				! print*,'day',day,'Simu_hrflux(3,i)',Simu_hrflux(3,i),'obs_cflux_hr(6,i)',obs_cflux_hr(6,i)
		       ! write (*,*) 'reco dObsSim',dObsSim,'std_cflux_hr(6,i)',std_cflux_hr(6,i)
                   endif

                   if(obs_cflux_hr(7,i).gt.-999)then
            jch4_hr=jch4_hr+1
                       dObsSim=Simu_hrflux(4,i)-obs_cflux_hr(7,i)
                       J_CH4flux_hr=J_CH4flux_hr+(dObsSim*dObsSim)/(2*std_cflux_hr(7,i)*std_cflux_hr(7,i))
				! print*,'day',day,'Simu_hrflux(4,i)',Simu_hrflux(4,i),'obs_cflux_hr(7,i)',obs_cflux_hr(7,i)
		       ! write (*,*) 'ch4 dObsSim',dObsSim,'std_cflux_hr(7,i)',std_cflux_hr(7,i)
                   endif
              ! endif !end of if 1460
			enddo
				J_gpp_hr=J_gpp_hr/real(j1_hr)
				J_nee_hr=J_nee_hr/real(j2_hr)
				J_reco_hr=J_reco_hr/real(j3_hr)
				J_CH4flux_hr=J_CH4flux_hr/real(jch4_hr)
					  if(.not. isnan(J_gpp_hr))then
				!         data_exist_gpp = .true.
						 J_new = J_new + J_gpp_hr
						 print*,'J_gpp_hr',J_gpp_hr,j1_hr
				!      else
				!!         if(data_exist_gpp)then
				!            J_new = J_new + 99999.
				!            print*,'J_gpp',99999.
				!!         end if
					  end if

					  if(.not. isnan(J_nee_hr))then
				!         data_exist_nee = .true.
						 J_new = J_new + J_nee_hr
						 print*,'J_nee_hr',J_nee_hr,j2_hr
					  end if

					  if(.not. isnan(J_reco_hr))then
				!         data_exist_reco = .true.
						 J_new = J_new + J_reco_hr
						 print*,'J_reco_hr',J_reco_hr,j3_hr
					  end if

	  				  if(.not. isnan(J_CH4flux_hr))then
				!         data_exist_reco = .true.
						 J_new = J_new + J_CH4flux_hr
						 print*,'J_CH4flux_hr',J_CH4flux_hr,jch4_hr
					  end if
		endif
!   ******** end of cost function for hourly carbon flux *****************

	if (use_cpool_ob .eq. 1) then
        do i=1,len_cpool
             day=int(obs_cpool(2,i))
			 if (day .gt. 1460) then  ! use data from 2015-2018 for acclimation effect study
             ! if (use_cpool_ob .eq. 1 .and. day .gt. 1095) then  ! use data from 2014-2018 for acclimation effect study
!	     if (use_cpool_ob .eq. 1 .and. day .lt. 1096) then  ! use data from 2011-2014 for acclimation effect study
                 if(obs_cpool(3,i).gt.-999)then
                        j4=j4+1

                        dObsSim=Simu_dailyflux(4,day)-obs_cpool(3,i)
                        J_foliage=J_foliage+(dObsSim*dObsSim)/(2*std_cpool(3,i)*std_cpool(3,i))
			! write (*,*) 'leaf dObsSim',dObsSim,'std_cpool(3,i)',std_cpool(3,i)
                 endif

                 if(obs_cpool(4,i).gt.-999)then
                     j5=j5+1

                        dObsSim=Simu_dailyflux(5,day)-obs_cpool(4,i)
                        J_fnpp=J_fnpp+(dObsSim*dObsSim)/(2*std_cpool(4,i)*std_cpool(4,i))
                 endif

                 if(obs_cpool(5,i).gt.-999)then
                        j6=j6+1

                        dObsSim=Simu_dailyflux(6,day)-obs_cpool(5,i)
                        J_wood=J_wood+(dObsSim*dObsSim)/(2*std_cpool(5,i)*std_cpool(5,i))
			 ! write (*,*) 'wood dObsSim',dObsSim,'std_cpool(5,i)',std_cpool(5,i)
                 endif

                 if(obs_cpool(6,i).gt.-999)then
                        j7=j7+1

                        dObsSim=Simu_dailyflux(7,day)-obs_cpool(6,i)
                        J_wnpp=J_wnpp+(dObsSim*dObsSim)/(2*std_cpool(6,i)*std_cpool(6,i))
                 endif

                if(obs_cpool(7,i).gt.-999)then
                        j8=j8+1

                        dObsSim=Simu_dailyflux(8,day)-obs_cpool(7,i)
                        J_root=J_root+(dObsSim*dObsSim)/(2*std_cpool(7,i)*std_cpool(7,i))
			 ! write (*,*) 'root dObsSim',dObsSim,'std_cpool(7,i)',std_cpool(7,i)
                 endif

                 if(obs_cpool(8,i).gt.-999)then
                        j9=j9+1

                        dObsSim=Simu_dailyflux(9,day)-obs_cpool(8,i)
                        J_rnpp=J_rnpp+(dObsSim*dObsSim)/(2*std_cpool(8,i)*std_cpool(8,i))
                 endif

                 if(obs_cpool(9,i).gt.-999)then
                        j10=j10+1

                        dObsSim=Simu_dailyflux(10,day)-obs_cpool(9,i)
                        J_soilc=J_soilc+(dObsSim*dObsSim)/(2*std_cpool(9,i)*std_cpool(9,i))
                 endif

                 if(obs_cpool(10,i).gt.-999)then
                        j11=j11+1
                        dObsSim=Simu_dailyflux(11,day)-obs_cpool(10,i)
                        J_pheno=J_pheno+(dObsSim*dObsSim)/(2*std_cpool(10,i)*std_cpool(10,i))
                 endif

             endif
        enddo
			J_foliage=J_foliage/real(j4)
			J_fnpp=J_fnpp/real(j5)
			J_wood=J_wood/real(j6)
			J_wnpp=J_wnpp/real(j7)
			J_root=J_root/real(j8)
			J_rnpp=J_rnpp/real(j9)
			J_soilc=J_soilc/real(j10)
			J_pheno=J_pheno/real(j11)

			  if(.not. isnan(J_foliage))then
		!         data_exist_foliage = .true.
				 J_new = J_new + J_foliage
				 print*,'J_foliage',J_foliage,j4
			  end if

			  if(.not. isnan(J_fnpp))then
		!         data_exist_fnpp = .true.
				 J_new = J_new + J_fnpp
				 print*,'J_fnpp',J_fnpp,j5
			  end if

			  if(.not. isnan(J_wood))then
		!         data_exist_wood = .true.
				 J_new = J_new + J_wood
				 print*,'J_wood',J_wood,j6
			  end if

			  if(.not. isnan(J_wnpp))then
		!         data_exist_wnpp = .true.
				 J_new = J_new + J_wnpp
				 print*,'J_wnpp',J_wnpp,j7
			  end if

			  if(.not. isnan(J_root))then
		!         data_exist_root = .true.
				 J_new = J_new + J_root
				 print*,'J_root',J_root,j8
			  end if

			  if(.not. isnan(J_rnpp))then
		!         data_exist_rnpp = .true.
				 J_new = J_new + J_rnpp
				 print*,'J_rnpp',J_rnpp,j9
			  end if

			  if(.not. isnan(J_soilc))then
		!         data_exist_soilc = .true.
				 J_new = J_new + J_soilc
				 print*,'J_soilc',J_soilc,j10
			  end if

			  ! if(.not. isnan(J_pheno))then
		        ! data_exist_pheno = .true.
				 ! J_new = J_new + J_pheno
				 ! print*,'J_pheno',J_pheno,j11
			  ! end if
	endif

			J_CH4flux=0.0
			jch4=0
	if (use_ch4flux_ob .eq. 1) then

			do i=1,len_ch4flux			!len1=m undefined here      m is the length of simu_dailyflux
				day=int(obs_ch4flux(1,i))        !index for simudailyCH4 data  QUESTION int()  real()
				if (day .gt. 1460) then  ! use data from 2015-2018 for acclimation effect study
				! if (day .gt. 1095) then  ! use data from 2014-2018 for acclimation effect study
	!            if (day .lt. 1096) then  ! use data from 2011-2014 for acclimation effect study
					   jch4=jch4+1
					   dObsSim=Simu_dailyCH4(1,day)-obs_ch4flux(2,i)			!need to be modified here Simu_dailyCH4
					   J_CH4flux=J_CH4flux+(dObsSim*dObsSim)/(2*std_ch4flux(2,i)*std_ch4flux(2,i))
				!       write (*,*) 'Simu_dailyCH4(1,day)',Simu_dailyCH4(1,day),'obs_ch4flux(2,i)',obs_ch4flux(2,i)
				!       write (*,*) 'CH4flux dObsSim',dObsSim,'std_ch4flux(2,i)',std_ch4flux(2,i)
				endif
			enddo
				J_CH4flux=J_CH4flux/real(jch4)
				 if(.not. isnan(J_CH4flux))then
			!         data_exist_ch4flux = .true.	!
					J_new=J_new+J_CH4flux
				   print*,'J_CH4flux',J_CH4flux,jch4
				 endif
	 endif



        J_CH4conc1=0.
        J_CH4conc2=0.
        J_CH4conc3=0.
        J_CH4conc4=0.
        J_CH4conc5=0.
        J_CH4conc6=0.
        J_CH4conc7=0.
        jch4c1=0
        jch4c2=0
        jch4c3=0
        jch4c4=0
        jch4c5=0
        jch4c6=0
        jch4c7=0

!       stdm=0.01

		if (use_plinit .eq. 11 .or. use_plinit .eq. 12) then
        stdm=2!1.6!stdm shallow layer conc std
		stdmc=stdm!1.6!stdmc deep layer conc std
		elseif (use_plinit .eq. 14) then
		stdm=2.5!2.
		stdmc=stdm!2.
		else
		stdm=3!2.4
		stdmc=stdm
		endif

		! write (*,*) 'use_plinit',use_plinit, 'stdmc',stdmc
    if (use_ch4conc_ob .eq. 1) then
        do i=1,len_ch4conc			!len5=m undefined here      m is the length of simu_dailyflux
                day=int(obs_ch4conc(1,i))        !index for simudailyCH4 data  QUESTION int()  real()
            if (day .gt. 1095) then
                if (obs_ch4conc(2,i) .gt. -999) then		! 10cm
                jch4c1=jch4c1+1
                dObsSim=Simu_dailyCH4(7,day)-obs_ch4conc(2,i)			!conc layer 1
        !        J_CH4conc1=J_CH4conc1+(dObsSim*dObsSim)/(2*std_CH4(2,i)*std_CH4(2,i))
                J_CH4conc1=J_CH4conc1+(dObsSim*dObsSim)/(2*stdm*stdm)
                endif
                if (obs_ch4conc(3,i) .gt. -999) then 		! 15cm
                jch4c2=jch4c2+1
                dObsSim=(Simu_dailyCH4(7,day)*0.5+Simu_dailyCH4(8,day)*0.5) -obs_ch4conc(3,i)		!
        !        J_CH4conc2=J_CH4conc2+(dObsSim*dObsSim)/(2*std_CH4(3,i)*std_CH4(3,i))
                J_CH4conc2=J_CH4conc2+(dObsSim*dObsSim)/(2*stdm*stdm)
                endif
                if (obs_ch4conc(4,i) .gt. -999) then		! 25cm
                jch4c3=jch4c3+1
                dObsSim=(Simu_dailyCH4(8,day)*0.5+Simu_dailyCH4(9,day)*0.5) -obs_ch4conc(4,i)		!
        !        J_CH4conc3=J_CH4conc3+(dObsSim*dObsSim)/(2*std_CH4(4,i)*std_CH4(4,i))
                J_CH4conc3=J_CH4conc3+(dObsSim*dObsSim)/(2*stdm*stdm)
                endif
                if (obs_ch4conc(5,i) .gt. -999) then		! 50cm
                jch4c4=jch4c4+1
                dObsSim=Simu_dailyCH4(11,day)-obs_ch4conc(5,i)		!
        !        J_CH4conc4=J_CH4conc4+(dObsSim*dObsSim)/(2*std_CH4(5,i)*std_CH4(5,i))
                J_CH4conc4=J_CH4conc4+(dObsSim*dObsSim)/(2*stdmc*stdmc)
                endif
                if (obs_ch4conc(6,i) .gt. -999) then		! 75cm
                jch4c5=jch4c5+1
                dObsSim=(Simu_dailyCH4(12,day)*0.75+Simu_dailyCH4(13,day)*0.25) -obs_ch4conc(6,i)		!
        !        J_CH4conc5=J_CH4conc5+(dObsSim*dObsSim)/(2*std_CH4(6,i)*std_CH4(6,i))
                J_CH4conc5=J_CH4conc5+(dObsSim*dObsSim)/(2*stdmc*stdmc)
                endif
                if (obs_ch4conc(7,i) .gt. -999) then		! 100cm
                jch4c6=jch4c6+1
                dObsSim=(Simu_dailyCH4(13,day)*0.5+Simu_dailyCH4(14,day)*0.5) -obs_ch4conc(7,i)		!
        !        J_CH4conc6=J_CH4conc6+(dObsSim*dObsSim)/(2*std_CH4(7,i)*std_CH4(7,i))
                J_CH4conc6=J_CH4conc6+(dObsSim*dObsSim)/(2*stdmc*stdmc)
                endif
                if (obs_ch4conc(8,i) .gt. -999) then		! 150cm
                jch4c7=jch4c7+1
                dObsSim= Simu_dailyCH4(16,day)-obs_ch4conc(8,i)		!
    !            J_CH4conc7=J_CH4conc7+(dObsSim*dObsSim)/(2*std_CH4(8,i)*std_CH4(8,i))
                J_CH4conc7=J_CH4conc7+(dObsSim*dObsSim)/(2*stdmc*stdmc)
                endif
            endif
        enddo
    J_CH4conc1=J_CH4conc1/real(jch4c1)
    ! J_CH4conc2=J_CH4conc2/real(jch4c2)
    J_CH4conc3=J_CH4conc3/real(jch4c3)
    J_CH4conc4=J_CH4conc4/real(jch4c4)
    J_CH4conc5=J_CH4conc5/real(jch4c5)
    J_CH4conc6=J_CH4conc6/real(jch4c6)
    J_CH4conc7=J_CH4conc7/real(jch4c7)

    endif

      if(.not. isnan(J_CH4conc1))then
!         data_exist_ch4flux = .true.	!
       J_new=J_new+J_CH4conc1
      print*,'J_CH4conc1',J_CH4conc1,jch4c1
     endif
     if(.not. isnan(J_CH4conc2))then
!         data_exist_ch4flux = .true.	!
       ! J_new=J_new+J_CH4conc2
      ! print*,'J_CH4conc2',J_CH4conc2,jch4c2
     endif
     if(.not. isnan(J_CH4conc3))then
!         data_exist_ch4flux = .true.	!
       J_new=J_new+J_CH4conc3
      print*,'J_CH4conc3',J_CH4conc3,jch4c3
     endif
     if(.not. isnan(J_CH4conc4))then
!         data_exist_ch4flux = .true.	!
       J_new=J_new+J_CH4conc4
      print*,'J_CH4conc4',J_CH4conc4,jch4c4
     endif
     if(.not. isnan(J_CH4conc5))then
!         data_exist_ch4flux = .true.	!
       J_new=J_new+J_CH4conc5
      print*,'J_CH4conc5',J_CH4conc5,jch4c5
     endif
     if(.not. isnan(J_CH4conc6))then
!         data_exist_ch4flux = .true.	!
       J_new=J_new+J_CH4conc6
      print*,'J_CH4conc6',J_CH4conc6,jch4c6
     endif
     if(.not. isnan(J_CH4conc7))then
!         data_exist_ch4flux = .true.	!
      J_new=J_new+J_CH4conc7
      print*,'J_CH4conc7',J_CH4conc7,jch4c7
     endif

!    if (isnan(J_gpp) .or. isnan(J_nee) .or. isnan(J_reco) .or. isnan(J_foliage) .or. isnan(J_wood) &
!    &   .or. isnan(J_CH4flux) .or. isnan(J_CH4conc1).or. isnan(J_CH4conc2).or. isnan(J_CH4conc3).or. isnan(J_CH4conc4) &
!    &   .or. isnan(J_CH4conc5).or. isnan(J_CH4conc6).or. isnan(J_CH4conc7)) then
!        JNAN=JNAN+1
!    endif
    ! if (isnan(J_gpp_hr) .or. isnan(J_nee_hr) .or. isnan(J_reco_hr) .or. isnan(J_foliage) .or. isnan(J_wood) &
    ! &   .or. isnan(J_CH4flux_hr)) then
    if (isnan(J_gpp_hr) .or. isnan(J_nee_hr) .or. isnan(J_reco_hr) .or. isnan(J_foliage) .or. isnan(J_wood) &
    &   .or. isnan(J_root) .or.  isnan(J_CH4flux_hr).or. isnan(J_CH4conc1).or. isnan(J_CH4conc3) &
   &   .or. isnan(J_CH4conc4) .or. isnan(J_CH4conc5).or. isnan(J_CH4conc6).or. isnan(J_CH4conc7)) then
    ! if (isnan(J_gpp) .or. isnan(J_nee) .or. isnan(J_reco) .or. isnan(J_foliage) .or. isnan(J_wood) &
    ! &   .or. isnan(J_CH4flux)) then
        JNAN=JNAN+1
    endif

    print*,'JNAN',JNAN



   endif !end of do_CO2_da
!
!************************************************
 ! soilwater cost fun
 !print*,'soil water da'
     if (do_soilwater_da) then  !soil water data
         J_sw1=0.0
         J_sw2=0.0
         j1=0
         j2=0
        ! INQUIRE(file='fort.1105',exist=file_exists)
!       !  print*,'file_exists1105',file_exists,len_st
        ! if(.not. file_exists)then
        !    open(1105,file='fort.1105')
        ! end if
         do i=1,len_sw
             if (use_soilwater_ob .eq. 1) then
                 day=int(obs_soilwater(2,i))
                 if(obs_soilwater(3,i).gt.-999) then
                        j1=j1+1
                        dObsSim=Simu_soilwater(1,day)-obs_soilwater(3,i)
                        J_sw1=J_sw1+(dObsSim*dObsSim)/(2*std_soilwater(3,i)*std_soilwater(3,i))
                 endif

                 if(obs_soilwater(4,i).gt.-999) then
                        j2=j2+1
                        dObsSim=Simu_soilwater(2,day)-obs_soilwater(4,i)
                        J_sw2=J_sw2+(dObsSim*dObsSim)/(2*std_soilwater(4,i)*std_soilwater(4,i))
                 endif
             endif


          !  if(.not. file_exists)then
          !     write(1105,'(4F15.6)'),sum(Simu_soilwater(11,i*24-23:i*24))/0.1/24,&
          !                            sum(Simu_soilwater(11:12,i*24-23:i*24))/0.2/24,&
          !                            sum(obs_soilwater (4,i*24-23:i*24))/24,&
          !                            sum(obs_soilwater (5,i*24-23:i*24))/24
          !  end if
            !print*,'costF Jsw',i,j1,J_sw1,sum(Simu_soilwater(11,i*24-23:i*24))/0.1/24,&
      !                   sum(obs_soilwater (4 ,i*24-23:i*24))/24,std_cpool_cflux_soilwater(4,i*24)

         enddo

         !close(1105)
         J_sw1 = J_sw1 / real(j1)  ! average of 2 layer's contribution
         J_sw2 = J_sw2 / real(j2)
!         print*,'isnan sim soilwater',Simu_soilwater(11:12,:)

         if(.not. isnan(J_sw1))then
!            data_exist_sw1 = .true.
            J_new = J_new + J_sw1
            print*,'J_sw1',J_sw1,j1
         end if
         if(.not. isnan(J_sw2))then
!            data_exist_sw2 = .true.
            J_new = J_new + J_sw2
            print*,'J_sw2',J_sw2,j2
         end if
     endif !end of do_soilwater_da
 !print*,'soil t da'
!  !! soil temp cost fun
  if (do_soilt_da) then !soil t data
    J_dsoilt1=0.0
    J_dsoilt2=0.0
    J_dsoilt3=0.0
    J_dsoilt4=0.0
    J_dsoilt5=0.0
    J_dsoilt6=0.0
   ! J_dsoilt7=0.0
    j_ds1=0
    j_ds2=0
    j_ds3=0
    j_ds4=0
    j_ds5=0
    j_ds6=0		!doublecheck the /0 issue when there is no obs data at that layer
   ! j_ds7=0

   ! INQUIRE(file='fort.426',exist=file_exists)
!  !  print*,'file_exists426',file_exists,len_st
   ! if(.not. file_exists)then
   !    open(426,file='fort.426')
   ! end if
    do i=1,len_st
	if(use_soilt_ob .eq. 1)then		!soilt5	soilt10	soilt20	soilt40	soilt80	soilt160	soilt200
   	    day=int(obs_soilt(2,i))
		if(obs_soilt(3,i).gt.-999.)then
           j_ds1=j_ds1+1
                   dObsSim=Simu_dailysoilt(1,day)-obs_soilt(3,i)		!Simu_dailysoilt(1), surface
           J_dsoilt1=J_dsoilt1+(dObsSim*dObsSim)/(2*1.94*1.94)
            endif


            if(obs_soilt(4,i).gt.-999.)then
           j_ds2=j_ds2+1
               dObsSim=Simu_dailysoilt(2,day)-obs_soilt(4,i)		!Simu_dailysoilt(2,i),10cm
           J_dsoilt2=J_dsoilt2+(dObsSim*dObsSim)/(2*1.94*1.94)
            endif

            if(obs_soilt(5,i).gt.-999.)then
           j_ds3=j_ds3+1
               dObsSim=Simu_dailysoilt(3,day)-obs_soilt(5,i)
               J_dsoilt3=J_dsoilt3+(dObsSim*dObsSim)/(2*1.94*1.94) !Simu_dailysoilt(3,i),20cm
            endif

            if(obs_soilt(6,i).gt.-999.)then
           j_ds4=j_ds4+1
               dObsSim=Simu_dailysoilt(5,day)-obs_soilt(6,i)
               J_dsoilt4=J_dsoilt4+(dObsSim*dObsSim)/(2*1.94*1.94)!Simu_dailysoilt(5,i),40cm
            endif

            if(obs_soilt(7,i).gt.-999.)then
            j_ds5=j_ds5+1
               dObsSim=(Simu_dailysoilt(7,day)+Simu_dailysoilt(8,day))/2-obs_soilt(7,i)
               J_dsoilt5=J_dsoilt5+(dObsSim*dObsSim)/(2*1.94*1.94)!Simu_dailysoilt(7,i),70cm
            endif												  !Simu_dailysoilt(8,i),90cm
            if(obs_soilt(8,i).gt.-999.)then					  !Simu_dailysoilt(11,i),150cm
            j_ds6=j_ds6+1
               dObsSim=Simu_dailysoilt(11,day)-obs_soilt(8,i)
           J_dsoilt6=J_dsoilt6+(dObsSim*dObsSim)/(2*1.94*1.94)
            endif

        endif
    enddo
    !close(426)
    J_dsoilt1=J_dsoilt1/real(j_ds1) ! average of 4 layers' contribution
    J_dsoilt2=J_dsoilt2/real(j_ds2)
    J_dsoilt3=J_dsoilt3/real(j_ds3)
    J_dsoilt4=J_dsoilt4/real(j_ds4)
    J_dsoilt5=J_dsoilt5/real(j_ds5)
    J_dsoilt6=J_dsoilt6/real(j_ds6)
!    print*,'isnan J & obs soiltemp1',(obs_soilt(4,:))
!    print*,'isnan J & obs soiltemp2',(obs_soilt(5,:))
!    print*,'isnan J & obs soiltemp3',(obs_soilt(6,:))
!    print*,'isnan J & obs soiltemp4',(obs_soilt(7,:))
!    print*,'isnan sim soiltemp1',(Simu_soiltemp(1,:))
!    print*,'isnan sim soiltemp2',(Simu_soiltemp(2,:))
!    print*,'isnan sim soiltemp3',(Simu_soiltemp(3,:))
!    print*,'isnan sim soiltemp4',(Simu_soiltemp(4,:))
!    J_soilt7=J_soilt7/real(js7)
    if(.not. isnan(J_dsoilt1))then
!       data_exist_soilt1 = .true.
       J_new=J_new+J_dsoilt1
       print*,'J_dsoilt1',J_dsoilt1,j_ds1
    end if
    if(.not. isnan(J_dsoilt2))then
!       data_exist_soilt2 = .true.
       J_new=J_new+J_dsoilt2
       print*,'J_dsoilt2',J_dsoilt2,j_ds2
    end if
    if(.not. isnan(J_dsoilt3))then
!       data_exist_soilt3 = .true.
       J_new=J_new+J_dsoilt3
       print*,'J_dsoilt3',J_dsoilt3,j_ds3
    end if
    if(.not. isnan(J_dsoilt4))then
!       data_exist_soilt4 = .true.
       J_new=J_new+J_dsoilt4!+J_dsoilt5+J_dsoilt6+J_dsoilt7
       print*,'J_dsoilt4',J_dsoilt4,j_ds4
    end if
    if(.not. isnan(J_dsoilt5))then
!       data_exist_soilt5 = .true.
       J_new=J_new+J_dsoilt5!+J_dsoilt5+J_dsoilt6+J_dsoilt7
       print*,'J_dsoilt5',J_dsoilt5,j_ds5
    end if
    if(.not. isnan(J_dsoilt6))then
!       data_exist_soilt6 = .true.
       J_new=J_new+J_dsoilt6!+J_dsoilt5+J_dsoilt6+J_dsoilt7
       print*,'J_dsoilt6',J_dsoilt6,j_ds6
    end if
  end if !end of do_soilt_da
!print*,'before water table cost f',do_watertable_da
!!!!! daily water table  cost function
  if (do_watertable_da) then	!water table data
     J_dwatertable = 0.
     j_dwtdaily = 0.
     j_dwt1 = 0.
     dObsSim = 0
  !   INQUIRE(file='fort.1106',exist=file_exists)
! !        print*,'file_exists1105',file_exists,len_st
   !  if(.not. file_exists)then
   !     open(1106,file='fort.1106')
  !   end if

   !  !print*,'len_wt',len_wt
     do i=1,len_wt
   !     if(.not. file_exists)then
   !        write(1106,'(2F15.6)'),Simu_dailywatertable(1,i),obs_wt(3,i)
   !     end if

!        print*,'Jwatertable',i,j_dwt1,Simu_dailywatertable(1,i),obs_wt(3,i),std_cpool_cflux_wt(3,i),J_dwatertable
         if(use_watertable_ob .eq. 1 ) then
             if(obs_wt(3,i).gt.-999.)then
               day=int(obs_wt(2,i))
                       j_dwtdaily=j_dwtdaily+1
               dObsSim=dObsSim+Simu_dailywatertable(1,day)-obs_wt(3,i)
               J_dwatertable=(dObsSim*dObsSim)/(2*std_wt(3,i)*std_wt(3,i))
!               write(*,*)'obs_wt(3,i)',obs_wt(3,i),'Simu_dailywatertable(1,i)',Simu_dailywatertable(1,i),'dObsSim',dObsSim
!               write(*,*)'std',std_wt(3,i),'j_dwtdaily',j_dwtdaily
             endif

         endif
    enddo
     J_dwatertable=J_dwatertable/real(j_dwtdaily)
     if(.not. isnan(J_dwatertable))then
!        data_exist_dwatertable = .true.
        J_new=J_new+J_dwatertable
        print*,'J_dwatertable',J_dwatertable,j_dwtdaily
     end if
  end if	!!end of do_watertable_da
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!print*,'before snowdepth cost f'
!!!!! daily snow depth  cost function
  if (do_snow_da) then	!snow depth data
     J_snow = 0.
     j_sn1 = 0.
    ! INQUIRE(file='fort.1107',exist=file_exists)
!   !      print*,'file_exists1105',file_exists,len_st
    ! if(.not. file_exists)then
    !    open(1107,file='fort.1107')
    ! end if

     !print*,'len_snow',len_snow
     do i=1,len_snow
      !  if(.not. file_exists)then
       !    write(1107,'(2F15.6)'),Simu_snowdepth(1,i),obs_snow(3,i)
       ! end if
         if(use_snow_ob .eq. 1) then

            if(obs_snow(3,i).gt.-999. )then
               day=int(obs_snow(2,i))
               j_sn1=j_sn1+1
               dObsSim=Simu_snowdepth(1,day)-obs_snow(3,i)
               J_snow=J_snow+(dObsSim*dObsSim)/(2*std_snow(3,i)*std_snow(3,i))
            end if
         endif
!        print*,'j_dsnow',i,j_sn1,Simu_snowdepth(1,i),obs_snow(3,i),std_cpool_cflux_snow(3,i),J_snow
    enddo
     !print*,'j_dsnow',J_snow,real(j_sn1)
     J_snow=J_snow/real(j_sn1)
     if(.not. isnan(J_snow))then
!        data_exist_snow = .true.
        J_new=J_new+J_snow
        print*,'J_snow',J_snow,j_sn1
     endif
  endif!end of do_snow_da
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!print*,'before thawd cost f'
!!!!! daily thaw depth  cost function
  if (do_soilt_da) then    ! thawdepth data
     J_ThawD = 0.
     j_td1 = 0.
     obs_maxtd = 0
   !  INQUIRE(file='fort.1108',exist=file_exists)
!  !       print*,'file_exists1105',file_exists,len_st
   !  if(.not. file_exists)then
   !     open(1108,file='fort.1108')
   !  end if
     do i=1,len_td		!obs data have to be in standard timestamp
        if(obs_td(3,i).gt.-999.)then
           if(obs_maxtd .lt. obs_td(3,i)) obs_maxtd = obs_td(3,i)
		if(mod(i,365) .eq. 0  .and. use_td_ob .eq. 1) then
		   j_td1=j_td1+1
                   dObsSim=maxval(Simu_TD(1,i:i+364))-obs_maxtd
                   J_ThawD=J_ThawD+(dObsSim*dObsSim)/(2*std_td(3,i)*std_td(3,i))
                   obs_maxtd = 0
                endif
        !   if(.not. file_exists)then
        !      write(1108,'(2F15.6)'),maxval(Simu_TD(1,i-364:i)),obs_maxtd
        !   end if
        end if
     end do
     J_ThawD=J_ThawD/real(j_td1)
     if(.not. isnan(J_ThawD))then
!        data_exist_ThawD = .true.	!doublecheck why assign value here
        J_new=J_new+J_ThawD
        print*,'J_ThawD',J_ThawD,j_td1
     end if
  end if
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!!!!!!!!!!!!!! Methane flux cost function !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   if (do_methane_da) then  !ch4 flux data
    J_CH4flux=0.0
        jch4=0
        do i=1,len_ch4flux			!len1=m undefined here      m is the length of simu_dailyflux
            if (use_ch4flux_ob .eq. 1) then
               if(obs_ch4flux(2,i).gt.-999.)then
                   day=int(obs_ch4flux(1,i))        !index for simudailyCH4 data  QUESTION int()  real()
                   jch4=jch4+1
                   dObsSim=Simu_dailyCH4(1,day)-obs_ch4flux(2,i)			!need to be modified here Simu_dailyCH4
                   J_CH4flux=J_CH4flux+(dObsSim*dObsSim)/(2*std_ch4flux(2,i)*std_ch4flux(2,i))
               endif
            endif
        enddo
        J_CH4flux=J_CH4flux/real(jch4)
         if(.not. isnan(J_CH4flux))then
!                data_exist_ch4flux = .true.	!doublecheck why assign value here
            J_new=J_new+J_CH4flux
           print*,'J_CH4flux',J_CH4flux,jch4
         endif
   endif
   if (do_methane_da) then	!ch4 conc data
    J_CH4conc1=0.
    J_CH4conc2=0.
    J_CH4conc3=0.
    J_CH4conc4=0.
    J_CH4conc5=0.
    J_CH4conc6=0.
    J_CH4conc7=0.
    jch4c1=0
    jch4c2=0
    jch4c3=0
    jch4c4=0
    jch4c5=0
    jch4c6=0
    jch4c7=0

    stdm=0.01
    stdmc=0.5

    do i=1,len_ch4conc			!len5=m undefined here      m is the length of simu_dailyflux
        if (use_ch4conc_ob .eq. 1) then
            day=int(obs_ch4conc(1,i))        !index for simudailyCH4 data  QUESTION int()  real()

            if (obs_ch4conc(2,i) .gt. -999) then
            jch4c1=jch4c1+1
                dObsSim=Simu_dailyCH4(7,day)-obs_ch4conc(2,i)			!conc layer 1
    !            J_CH4conc1=J_CH4conc1+(dObsSim*dObsSim)/(2*std_CH4(2,i)*std_CH4(2,i))
            J_CH4conc1=J_CH4conc1+(dObsSim*dObsSim)/(2*stdmc*stdmc)
            endif

            if (obs_ch4conc(3,i) .gt. -999) then
            jch4c2=jch4c2+1
                dObsSim=(Simu_dailyCH4(7,day)*0.5+Simu_dailyCH4(8,day)*0.5) -obs_ch4conc(3,i)		!
    !            J_CH4conc2=J_CH4conc2+(dObsSim*dObsSim)/(2*std_CH4(3,i)*std_CH4(3,i))
            J_CH4conc2=J_CH4conc2+(dObsSim*dObsSim)/(2*stdmc*stdmc)
            endif

            if (obs_ch4conc(4,i) .gt. -999) then
            jch4c3=jch4c3+1
                dObsSim=(Simu_dailyCH4(8,day)*0.5+Simu_dailyCH4(9,day)*0.5) -obs_ch4conc(4,i)		!
    !            J_CH4conc3=J_CH4conc3+(dObsSim*dObsSim)/(2*std_CH4(4,i)*std_CH4(4,i))
            J_CH4conc3=J_CH4conc3+(dObsSim*dObsSim)/(2*stdmc*stdmc)
            endif

            if (obs_ch4conc(5,i) .gt. -999) then
            jch4c4=jch4c4+1
                dObsSim=Simu_dailyCH4(11,day)-obs_ch4conc(5,i)		!
    !            J_CH4conc4=J_CH4conc4+(dObsSim*dObsSim)/(2*std_CH4(5,i)*std_CH4(5,i))
            J_CH4conc4=J_CH4conc4+(dObsSim*dObsSim)/(2*stdmc*stdmc)
            endif

            if (obs_ch4conc(6,i) .gt. -999) then
            jch4c5=jch4c5+1
                dObsSim=(Simu_dailyCH4(12,day)*0.75+Simu_dailyCH4(13,day)*0.25) -obs_ch4conc(6,i)		!
    !            J_CH4conc5=J_CH4conc5+(dObsSim*dObsSim)/(2*std_CH4(6,i)*std_CH4(6,i))
            J_CH4conc5=J_CH4conc5+(dObsSim*dObsSim)/(2*stdmc*stdmc)
            endif

            if (obs_ch4conc(7,i) .gt. -999) then
            jch4c6=jch4c6+1
                dObsSim=(Simu_dailyCH4(13,day)*0.5+Simu_dailyCH4(14,day)*0.5) -obs_ch4conc(7,i)		!
    !            J_CH4conc6=J_CH4conc6+(dObsSim*dObsSim)/(2*std_CH4(7,i)*std_CH4(7,i))
            J_CH4conc6=J_CH4conc6+(dObsSim*dObsSim)/(2*stdmc*stdmc)
            endif

            if (obs_ch4conc(8,i) .gt. -999) then
            jch4c7=jch4c7+1
                dObsSim= Simu_dailyCH4(16,day)-obs_ch4conc(8,i)		!
    !            J_CH4conc7=J_CH4conc7+(dObsSim*dObsSim)/(2*std_CH4(8,i)*std_CH4(8,i))
            J_CH4conc7=J_CH4conc7+(dObsSim*dObsSim)/(2*stdmc*stdmc)
            endif

        endif
    enddo
   endif
!   ***  end of cost functions for METHANE flux and conc

    if(ISNAN(J_new) .and. .not. use_nodata)then
        write(*,*)'NaN return, upgraded', upgraded
        return
    endif


    if(.not. use_nodata)then
        delta_J=J_new-J_last           !    delta_J=(J_new-J_last)/J_last
    else                               !    update delta_J

        delta_J=-0.1 !accept all samples, No data
    end if
    write(*,*) 'delta_J',delta_J,'J_new',J_new,'J_last',J_last
    CALL random_number(r_num)

!     delta_J=-1     !accept all samples, No data
    if(AMIN1(1.0,exp(-delta_J)).gt.r_num)then   ! go through the criteria
        if (isnan(J_gpp_hr) .or. isnan(J_nee_hr) .or. isnan(J_reco_hr) .or. isnan(J_foliage) &
		&	.or. isnan(J_wood) .or. isnan(J_root) .or.  isnan(J_CH4flux_hr) &
		&	.or. isnan(J_CH4conc1).or. isnan(J_CH4conc3) .or. isnan(J_CH4conc4) &
		&   .or. isnan(J_CH4conc5).or. isnan(J_CH4conc6).or. isnan(J_CH4conc7)) then
            write(*,*) "isnan(J_gpp_hr)",isnan(J_gpp_hr),"isnan(J_nee_hr)",isnan(J_nee_hr), &
			&"isnan(J_reco_hr) ",isnan(J_reco_hr),"isnan(J_foliage)", &
            & isnan(J_foliage),"isnan(J_wood)", isnan(J_wood),"isnan(J_root)", isnan(J_root), &
			&"isnan(J_CH4flux_hr)",isnan(J_CH4flux_hr)
	! if (isnan(J_gpp) .or. isnan(J_nee) .or. isnan(J_reco) .or. isnan(J_foliage) .or. isnan(J_wood) .or. isnan(J_CH4flux)) then
            ! write(*,*) "isnan(J_gpp)",isnan(J_gpp),"isnan(J_nee)",isnan(J_nee),"isnan(J_reco) ",isnan(J_reco),"isnan(J_foliage)", &
            ! & isnan(J_foliage),"isnan(J_wood)", isnan(J_wood),"isnan(J_CH4flux)",isnan(J_CH4flux)
        else
        upgraded=upgraded+1
        J_last=J_new
        endif
    endif
            acrate = real(upgraded)/real(isimu)

!   write(*,*) 'upgraded',upgraded,'delta_J',delta_J,'J_new',J_new,'J_last',J_last,'real(jch4c1)',real(jch4c1), &
!            &'exp(-delta_J)',exp(-delta_J),'r_num',r_num,'J_CH4conc1',J_CH4conc1
       write(*,*) 'acc',acrate,'isi',isimu,'upg',upgraded,'delta_J',delta_J,'J_new',J_new,'r_num',r_num
    return
    end


!******************************************************
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! Square root of a matrix							  !!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

subroutine racine_mat(M, Mrac,npara)

    integer npara,i
    real M(npara,npara),Mrac(npara,npara)
    real valpr(npara),vectpr(npara,npara)
    Mrac=0.
    call jacobi(M,npara,npara,valpr,vectpr,nrot)
    do i=1,npara
	if(valpr(i).ge.0.) then
            Mrac(i,i)=sqrt(valpr(i))
	else
            print*, 'WARNING!!! Square root of the matrix is undefined.'
            print*, ' A negative eigenvalue has been set to zero - results may be wrong'
            Mrac=M
            return
	endif
    enddo
    Mrac=matmul(matmul(vectpr, Mrac),transpose(vectpr))

end subroutine racine_mat


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! Extraction of the eigenvalues and the eigenvectors !!
!! of a matrix (Numerical Recipes)					  !!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

SUBROUTINE jacobi(a,n,np,d,v,nrot)
INTEGER :: n,np,nrot
REAL :: a(np,np),d(np),v(np,np)
INTEGER, PARAMETER :: NMAX=500
INTEGER :: i,ip,iq,j
REAL :: c,g,h,s,sm,t,tau,theta,tresh,b(NMAX),z(NMAX)

do ip=1,n
	do iq=1,n
		v(ip,iq)=0.
	end do
	v(ip,ip)=1.
end do

do ip=1,n
	b(ip)=a(ip,ip)
	d(ip)=b(ip)
	z(ip)=0.
end do

nrot=0
do i=1,50
	sm=0.
	do ip=1,n-1
		do iq=ip+1,n
			sm=sm+abs(a(ip,iq))
		end do
	end do
	if(sm.eq.0.)return
	if(i.lt.4)then
		tresh=0.2*sm/n**2
	else
		tresh=0.
	endif
	do ip=1,n-1
		do iq=ip+1,n
			g=100.*abs(a(ip,iq))
			if((i.gt.4).and.(abs(d(ip))+g.eq.abs(d(ip))).and.(abs(d(iq))+g.eq.abs(d(iq))))then
				a(ip,iq)=0.
			else if(abs(a(ip,iq)).gt.tresh)then
				h=d(iq)-d(ip)
				if(abs(h)+g.eq.abs(h))then
					t=a(ip,iq)/h
				else
					theta=0.5*h/a(ip,iq)
					t=1./(abs(theta)+sqrt(1.+theta**2))
					if(theta.lt.0.) then
						t=-t
					endif
				endif
				c=1./sqrt(1+t**2)
				s=t*c
				tau=s/(1.+c)
				h=t*a(ip,iq)
				z(ip)=z(ip)-h
				z(iq)=z(iq)+h
				d(ip)=d(ip)-h
				d(iq)=d(iq)+h
				a(ip,iq)=0.
				do j=1,ip-1
					g=a(j,ip)
					h=a(j,iq)
					a(j,ip)=g-s*(h+g*tau)
					a(j,iq)=h+s*(g-h*tau)
				end do
				do j=ip+1,iq-1
					g=a(ip,j)
					h=a(j,iq)
					a(ip,j)=g-s*(h+g*tau)
					a(j,iq)=h+s*(g-h*tau)
				end do
				do j=iq+1,n
					g=a(ip,j)
					h=a(iq,j)
					a(ip,j)=g-s*(h+g*tau)
					a(iq,j)=h+s*(g-h*tau)
				end do
				do j=1,n
					g=v(j,ip)
					h=v(j,iq)
					v(j,ip)=g-s*(h+g*tau)
					v(j,iq)=h+s*(g-h*tau)
				end do
				nrot=nrot+1
			endif
		end do
	end do
	do ip=1,n
		b(ip)=b(ip)+z(ip)
		d(ip)=b(ip)
		z(ip)=0.
	end do
end do
print*, 'too many iterations in jacobi'
return
END subroutine jacobi


!===================================================
!       generate new coefficents
        subroutine coefgenerate(coefac,coefmax,coefmin,coef,search_length,npara)

        integer npara
        real coefac(npara),coefmax(npara),coefmin(npara),coef(npara)
        real r,coefmid,random_harvest
        integer i
        real search_length
        do i=1,npara
999         continue
            CALL random_number(random_harvest)
            r=random_harvest-0.5
            coef(i)=coefac(i)+r*(coefmax(i)-coefmin(i))*search_length
            if(coef(i).gt.coefmax(i).or.coef(i).lt.coefmin(i))goto 999
        enddo
        return
        end
!============

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! Generation of a random vector from a multivariate  !!
!! normal distribution with mean zero and covariance  !!
!! matrix gamma.									  !!
!! Beware!!! In order to improve the speed of the	  !!
!! algorithms, the subroutine use the Square root	  !!
!! matrix of gamma									  !!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

subroutine gengaussvect(gamma_racine,xold,xnew,npara)

integer npara
real gamma_racine(npara,npara)
real x(npara),xold(npara),xnew(npara)

do i=1,npara
    x(i)=rangauss(25)
enddo

x = matmul(gamma_racine, x)
xnew = xold + x
end subroutine gengaussvect

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! Generation of a random number from a standard	  !!
!! normal distribution. (Numerical Recipes)           !!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

function rangauss(idum)


integer idum
real v1, v2, r, fac, gset
real r_num

data iset/0/
if(iset==0) then
1	CALL random_number(r_num)
        v1=2.*r_num-1
        CALL random_number(r_num)
	v2=2.*r_num-1
	r=(v1)**2+(v2)**2
	if(r>=1) go to 1
	fac=sqrt(-2.*log(r)/r)
	gset=v1*fac
	rangauss=v2*fac
	iset=1
else
	rangauss=gset
	iset=0
end if

return
end function

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! variance matrix of a matrix of data				  !!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

subroutine varcov(tab,varcovar,npara,ncov)

integer npara,ncov
real tab(ncov,npara),tab2(ncov,npara)
real varcovar(npara,npara)

call centre(tab,tab2,npara,ncov)

varcovar = matmul(transpose(tab2), tab2)*(1./real(ncov))

end subroutine varcov

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! Compute the centered matrix, ie. the matrix minus  !!
!! the column means									  !!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

subroutine centre(mat,mat_out,npara,ncov)

    integer npara,ncov
    real mat(ncov,npara),mat_out(ncov,npara)
    real mean

do i=1,npara
    mat_out(:,i) = mat(:,i) - mean(mat(:,i),ncov)
enddo

end subroutine centre

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! mean of a vector									  !!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

Function mean(tab,ncov)
    integer ncov
real tab(ncov)
real mean,mean_tt
mean_tt=0.
do i=1,ncov
mean_tt=mean_tt+tab(i)/real(ncov)
enddo
mean=mean_tt
End Function

! *****************************************************************************
! functions
! ******************************************************************
  ! methane diffusion coefficient for medium consisting of xx% peat,
  ! yy% water, depending on temperature
  pure elemental function methane_D_water(temperature) result(Dw)
!  ! Fraction of the diffusion rate in air-filled peat divided by the diffusion rate in free air
!	real(dp), parameter :: peat_coeff_a = 0.37_dp
  ! Fraction of the diffusion rate in water-filled peat divided by the diffusion rate in free water
    real, parameter :: peat_coeff_w = 0.9

    real, intent(in)  :: temperature ! [K]
    real              :: Dw
    real, parameter   :: Dw_298 = 1.5e-9 ! [m2 s-1]

    ! Arah and Stephen (1998), Eq. 11
    Dw = peat_coeff_w * Dw_298 * (temperature/298.)
    ! if (temperature < 273.15) Dw = 0
  end function methane_D_water
