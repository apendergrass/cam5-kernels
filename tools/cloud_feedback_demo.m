%%%%%%% CESM-CAM5 Radiative Kernel Demo: %%%%%%%%%%%%
%%    Cloud feedback. 
% This script will show you how to calculate 
% the Cloud Feedback at the Top-Of-Atmosphere 
% using the CESM-CAM5 radiative kernels. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% File with the changes in climate: (ts, temp) (TS,T,Q)
changefile='demodata/changefields.nc';

% You'll also need to generate the change in moisture for 1 K
% warming at constant RH. You can do this by running ncl scripts/calcdq1k.ncl

% File with initial surface SW downwelling and net radiative fields (for calculating
% albedo). 
basefile='demodata/basefields.nc';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% STEP 1. Calculate total-sky and clear-sky feedbacks

% Read in coordinate info
lat=ncread('kernels/PS.nc','lat');
lon=ncread('kernels/PS.nc','lon');
gw=ncread('kernels/t.kernel.nc','gw'); %% Gaussian weights for the CESM grid
lev=ncread('kernels/t.kernel.nc','lev');

% Read midpoint pressure for each grid cell (lat,lon,level,month), [Pa]
p=ncread('p_sigma.nc','pmid')/100; %[hPa] 

% Crude tropopause estimate: 100 hPa in the tropics, lowering with
% cosine to 300 hPa at the poles.
x=cosd(lat);
p_tropopause_zonalmean=300-200*x;
p_tropopause=repmat(permute(repmat(permute(repmat(p_tropopause_zonalmean',[length(lon) 1]),[1 2 3]),[1 1 length(lev)]),[1 2 3 4]),[1 1 1 12]);

% Make an area weighting matrix
weight=repmat(gw(:)',[length(lon) 1]); 
weight=weight./nansum(nansum(weight));


%%% Temperature feedback 

% Read surface temperature change
dts=ncread(changefile,'ts');

% Calculate the change in global mean surface temperature
dts_globalmean=nansum(nansum(nanmean(dts,3).*weight,2),1);

% Read TOA Longwave surface temperature kernel
ts_kernel=ncread('kernels/ts.kernel.nc','FLNT');
ts_kernel_clearsky=ncread('kernels/ts.kernel.nc','FLNTC');

% Multiply monthly mean TS change by the TS kernels (function of lat, lon, month) (units W/m2)
dLW_ts=ts_kernel.*dts;  
dLW_ts_cs=ts_kernel_clearsky.*dts;  

% Read air temperature change [lon,lat,level,month]
dta=ncread(changefile,'temp');

% Set the temperature change to zero in the stratosphere (mask out stratosphere)
dta=dta.*(p>=p_tropopause); 

% Read air temperature kernel
ta_kernel=ncread('kernels/t.kernel.nc','FLNT'); 
ta_kernel_clearsky=ncread('kernels/t.kernel.nc','FLNTC'); 

% Convolve air temperature kernel with air temperature change
dLW_ta=squeeze(sum(ta_kernel.*dta,3));
dLW_ta_cs=squeeze(sum(ta_kernel_clearsky.*dta,3));

% Add the surface and air temperature response; Take the annual average and global area average 
%dLW_t_globalmean=nansum(nansum(nanmean(-dLW_ta-dLW_ts,3).*weight,2),1);    

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
alb_kernel_clearsky=ncread('kernels/alb.kernel.nc','FSNTC');

dSW_alb=alb_kernel.*dalb;
dSW_alb_cs=alb_kernel_clearsky.*dalb;

%dSW_alb_globalmean=nansum(nansum(nanmean(dSW_alb,3).*weight,2), ...
%                        1);

%%%%%%% Water vapor feedback

% Read change in mixing ratio for 1 K warming at constant RH
dq1k=ncread('dq1k.nc','dq1k');

% Read q kernels
q_LW_kernel=ncread('kernels/q.kernel.nc','FLNT');
q_SW_kernel=ncread('kernels/q.kernel.nc','FSNT');
q_LW_kernel_clearsky=ncread('kernels/q.kernel.nc','FLNTC');
q_SW_kernel_clearsky=ncread('kernels/q.kernel.nc','FSNTC');

% Normalize kernels by the change in moisture for 1 K warming at
% constant RH (linear)
q_LW_kernel=q_LW_kernel./dq1k;
q_SW_kernel=q_SW_kernel./dq1k;
q_LW_kernel_clearsky=q_LW_kernel_clearsky./dq1k;
q_SW_kernel_clearsky=q_SW_kernel_clearsky./dq1k;

% Read the change in moisture
dq=ncread(changefile,'Q');

% Mask out the stratosphere
dq=dq.*(p>=p_tropopause);

% Convolve moisture kernel with change in moisture
dLW_q=squeeze(sum(q_LW_kernel.*dq,3));
dSW_q=squeeze(sum(q_SW_kernel.*dq,3));
dLW_q_cs=squeeze(sum(q_LW_kernel_clearsky.*dq,3));
dSW_q_cs=squeeze(sum(q_SW_kernel_clearsky.*dq,3));

% Add the LW and SW responses. Note the sign convention difference
% between LW and SW!
%dR_q_globalmean=nansum(nansum(nanmean(-dLW_q+dSW_q,3).*weight,2), ...
%                        1);

%%%%% Change in Cloud Radiative Effect (CRE) 
d_sw=ncread(changefile,'FSNT');
d_sw_cs=ncread(changefile,'FSNTC');
d_lw=ncread(changefile,'FLNT');
d_lw_cs=ncread(changefile,'FLNTC');

d_cre_sw=d_sw_cs-d_sw;
d_cre_lw=d_lw_cs-d_lw;


%%%% Cloud masking of radiative forcing
ghgfile='forcing/ghg.forcing.nc';
sw=ncread(ghgfile,'FSNT');
sw_cs=ncread(ghgfile,'FSNTC');
lw=ncread(ghgfile,'FLNT');
lw_cs=ncread(ghgfile,'FLNTC');
ghg_sw=sw_cs-sw;
ghg_lw=lw_cs-lw;

aerosolfile='forcing/aerosol.forcing.nc';
sw=ncread(aerosolfile,'FSNT');
sw_cs=ncread(aerosolfile,'FSNTC');
lw=ncread(aerosolfile,'FLNT');
lw_cs=ncread(aerosolfile,'FLNTC');
aerosol_sw=sw_cs-sw;
aerosol_lw=lw_cs-lw;

cloud_masking_of_forcing_sw=aerosol_sw+ghg_sw;
cloud_masking_of_forcing_lw=aerosol_lw+ghg_lw;

%%%%%% Cloud feedback. 
%%% CRE + cloud masking of radiative forcing + corrections for each feedback

dLW_cloud=-d_cre_lw+cloud_masking_of_forcing_lw+(dLW_q_cs-dLW_q)+(dLW_ta_cs-dLW_ta)+(dLW_ts_cs-dLW_ts);
dSW_cloud=-d_cre_sw+cloud_masking_of_forcing_sw+(dSW_q_cs-dSW_q)+(dSW_alb_cs-dSW_alb);

%Take global and annual averages
dLW_cloud_globalmean=nansum(nansum(nanmean(-dLW_cloud,3).*weight,2),1);
dSW_cloud_globalmean=nansum(nansum(nanmean(dSW_cloud,3).*weight,2),1);

%Divide by global, annual mean temperature change to get W/m2/K
lw_cloud_feedback=dLW_cloud_globalmean./dts_globalmean;
sw_cloud_feedback=dSW_cloud_globalmean./dts_globalmean;

disp(['LW Cloud Feedback: ' num2str(lw_cloud_feedback) ' W m^-2 K^-1'])
disp(['SW Cloud Feedback: ' num2str(sw_cloud_feedback) ' W m^-2 K^-1'])
