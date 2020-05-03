%%%%%%% CESM-CAM5 Radiative Kernel Demo: %%%%%%%%%%%%
%%       Hybrid sigma-pressure vertical coordinate %%
% This script will show you how to calculate 
% Top-Of-Atmosphere, clear-sky radiative feedbacks
% using the CESM-CAM5 radiative kernels. 
% In addition to the kernels and their accompanying 
% data, you'll need a set of T, q, and albedo changes
% on the CESM 0.9 degree grid for each month of the year. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% File with the changes in climate: (ts, temp) (TS,T,Q)
changefile='demodata/changefields.nc';

% File with initial surface SW downwelling and net radiative fields (for calculating
% albedo). 
basefile='demodata/basefields.nc';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Read in coordinate info
lat=ncread('kernels/PS.nc','lat');
lon=ncread('kernels/PS.nc','lon');
gw=ncread('kernels/t.kernel.nc','gw'); %% Gaussian weights for the CESM grid
lev=ncread('kernels/t.kernel.nc','lev');

% Make an area weighting matrix
weight=repmat(gw(:)',[length(lon) 1]); 
weight=weight./nansum(nansum(weight));

% Read surface temperature change
dts=ncread(changefile,'ts');

% Calculate the change in global mean surface temperature
dts_globalmean=nansum(nansum(nanmean(dts,3).*weight,2),1);


%%% Temperature feedback calculation 
%%% (see https://github.com/apendergrass/cam5-kernels 
%%% for Planck / lapse rate decomposition)

% Read TOA Longwave surface temperature kernel
ts_kernel=ncread('kernels/ts.kernel.nc','FLNT');

% Multiply monthly mean TS change by the TS kernels (function of lat, lon, month) (units W/m2)
dLW_ts=ts_kernel.*dts;  

% Read air temperature change [lon,lat,level,month]
dta=ncread(changefile,'temp');

% Read midpoint pressure for each grid cell (lat,lon,level,month), [Pa]
p=ncread('p_sigma.nc','pmid')/100; %[hPa] 

% Crude tropopause estimate: 100 hPa in the tropics, lowering with
% cosine to 300 hPa at the poles.
x=cosd(lat);
p_tropopause_zonalmean=300-200*x;
p_tropopause=repmat(permute(repmat(permute(repmat(p_tropopause_zonalmean',[length(lon) 1]),[1 2 3]),[1 1 length(lev)]),[1 2 3 4]),[1 1 1 12]);

% Set the temperature change to zero in the stratosphere (mask out stratosphere)
dta=dta.*(p>=p_tropopause); 

% Read air temperature kernel
ta_kernel=ncread('kernels/t.kernel.nc','FLNT'); 

% Convolve air temperature kernel with air temperature change
dLW_ta=squeeze(nansum(ta_kernel.*dta,3));

% Add the surface and air temperature response; Take the annual average and global area average 
dLW_t_globalmean=nansum(nansum(nanmean(-dLW_ta-dLW_ts,3).*weight,2),1);    

% Divide by the global annual mean surface warming (units: W/m2/K)
t_feedback=dLW_t_globalmean./dts_globalmean;  

disp(['Temperature feedback: ' num2str(t_feedback) ' W m^-2 K^-1'])


%%%%% Albedo feedback

% Collect surface shortwave radiation fields for calculating albedo change
SW_sfc_net_1=ncread(basefile,'FSNS');
SW_sfc_down_1=ncread(basefile,'FSDS');
SW_sfc_net_2=ncread(changefile,'FSNS')+SW_sfc_net_1;
SW_sfc_down_2=ncread(changefile,'FSDS')+SW_sfc_down_1;

alb1=squeeze(1-SW_sfc_net_1./SW_sfc_down_1);
alb1(isnan(alb1))=0;

alb2=squeeze(1-SW_sfc_net_2./SW_sfc_down_2);
alb2(isnan(alb2))=0;

dalb=(alb2-alb1)*100;

% Read TOA albedo kernel
alb_kernel=ncread('kernels/alb.kernel.nc','FSNT');

dSW_alb=alb_kernel.*dalb;

dSW_alb_globalmean=nansum(nansum(nanmean(dSW_alb,3).*weight,2), ...
                        1);

alb_feedback=dSW_alb_globalmean./dts_globalmean;

disp(['Surface albedo feedback: ' num2str(alb_feedback) ' W m^-2 K^-1'])


%%%%%%% Water vapor feedback

% Calculate the change in moisture for 1 K warming at constant relative humidity. 
% Run the accompanying NCL script with your input files, or
% implement here.                                                                                               

% This uses a linear change in q. An alternative that is more
% accurate  better uses log-q kernels. See demo at: 
% https://github.com/apendergrass/cam5-kernels 
                           
% Read change in mixing ratio for 1 K warming at constant RH
dq1k=ncread('dq1k.nc','dq1k');

% Read q kernels
q_LW_kernel=ncread('kernels/q.kernel.nc','FLNT');
q_SW_kernel=ncread('kernels/q.kernel.nc','FSNT');

% Normalize kernels by the change in moisture for 1 K warming at
% constant RH (linear)
q_LW_kernel=q_LW_kernel./dq1k;
q_SW_kernel=q_SW_kernel./dq1k;

% Read the change in moisture
dq=ncread(changefile,'Q');

% Mask out the stratosphere
dq=dq.*(p>=p_tropopause);

% Convolve moisture kernel with change in moisture
dLW_q=squeeze(nansum(q_LW_kernel.*dq,3));
dSW_q=squeeze(nansum(q_SW_kernel.*dq,3));

% Add the LW and SW responses. Note the sign convention difference
% between LW and SW!
dR_q_globalmean=nansum(nansum(nanmean(-dLW_q+dSW_q,3).*weight,2), ...
                        1);

% Divide by the global annual mean surface warming (units: W/m2/K)
q_feedback=dR_q_globalmean./dts_globalmean;

disp(['Water vapor feedback: ' num2str(q_feedback) ' W m^-2 K^-1'])
