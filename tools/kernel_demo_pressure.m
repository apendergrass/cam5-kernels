%%%%%%% CESM-CAM5 Radiative Kernel Demo: %%%%%%%%%%%%
%%       Hybrid sigma-pressure vertical coordinate %%
% This script will show you how to calculate 
% Top-Of-Atmosphere, clear-sky radiative feedbacks
% using the CESM-CAM5 radiative kernels. 
% In addition to the kernels and their accompanying 
% data, you'll need a set of T, q, and albedo changes
% on the CESM 0.9 degree grid for each month of the year. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% File with the changes in climate on pressure levels: temp, Q
changefile3d='changefields.plev.nc';

% File with the 2-d changes in climate: (ts,TS,T,)
changefile='demodata/changefields.nc';

% You'll need to generate the file of pressure differences. You 
% can do this by running calcdp_plev.ncl.

% You'll also need to generate the change in moisture for 1 K
% warming at constant RH. You can do this by running calcdq1k.ncl
% (you'll have to supply it with temperature and moisture fields
% and their pressure grid - you can get the CESM pressure grid by
% running calcp.ncl).

% File with initial surface SW downwelling and net radiative fields (for calculating
% albedo). 
basefile='demodata/basefields.nc';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


p_Pa=ncread('t.kernel.plev.nc','plev');
p_hPa=double(ncread('t.kernel.plev.nc','lev_p')); 

pdiff=ncread('dp_plev.nc','dp')/100;

p=repmat(permute(repmat(p_hPa,[1 12]),[3 4 1 2]),[288 192 1 1]);

filename='kernels/PS.nc';
lat=ncread(filename,'lat');
lon=ncread(filename,'lon');
gw=ncread('kernels/t.kernel.nc','gw'); %% Gaussian weights for the CESM grid
                                      

% Area weight 
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

% Air temperature change [lon,lat,level,month]
dta=ncread(changefile3d,'temp');

% Crude tropopause; 
% Must have the same
% size as the pressure array
x=cosd(lat);
p_tropopause_zonalmean=300-200*x;
p_tropopause=repmat(permute(repmat(permute(repmat(p_tropopause_zonalmean',[length(lon) 1]),[1 2 3]),[1 1 length(p_hPa)]),[1 2 3 4]),[1 1 1 12]);

% Set the temperature change to zero in the stratosphere
dta=dta.*(p>=p_tropopause); 

% Air temperature kernel
ta_kernel=ncread('t.kernel.plev.nc','FLNT'); 

% Convolve air temperature kernel with air temperature change
dLW_ta=squeeze(nansum(ta_kernel.*dta.*pdiff,3));

% Add the surface and air temperature response; Take the annual average and global area average 
dLW_t_globalmean=nansum(nansum(nanmean(-dLW_ta-dLW_ts,3).*weight,2),1);    

% Divide by the global annual mean surface warming (units: W/m2/K)
t_feedback=dLW_t_globalmean./dts_globalmean;  

disp(['Temperature feedback: ' num2str(t_feedback) ' W m^-2 K^-1'])

%%%%% Albedo feedback

% Collect surface shortwave radiation fields to calculate albedo.
% Alternatively, you might already have the change in albedo - that
% would work too.
SW_sfc_net_1=ncread(basefile,'FSNS');
SW_sfc_down_1=ncread(basefile,'FSDS');
SW_sfc_net_2=ncread(changefile,'FSNS')+SW_sfc_net_1;
SW_sfc_down_2=ncread(changefile,'FSDS')+SW_sfc_down_1;

alb1=squeeze(1-SW_sfc_net_1./SW_sfc_down_1);
alb1(isnan(alb1))=0;

alb2=squeeze(1-SW_sfc_net_2./SW_sfc_down_2);
alb2(isnan(alb2))=0;

dalb=(alb2-alb1)*100;

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
dq1k=ncread('dq1k.plev.nc','dq1k');

% Read kernels
q_LW_kernel=ncread('q.kernel.plev.nc','FLNT');
q_SW_kernel=ncread('q.kernel.plev.nc','FSNT');

% Normalize kernels by the change in moisture for 1 K warming at
% constant RH
q_LW_kernel=q_LW_kernel./dq1k;
q_SW_kernel=q_SW_kernel./dq1k;

% Read the change in moisture
dq=ncread(changefile3d,'Q');

% Mask out the stratosphere
dq=dq.*(p>=p_tropopause);

% Convolve moisture kernel with change in moisture
dLW_q=squeeze(nansum(q_LW_kernel.*dq.*pdiff,3));
dSW_q=squeeze(nansum(q_SW_kernel.*dq.*pdiff,3));

% Add the LW and SW responses. Note the sign convention difference
% between LW and SW!
dR_q_globalmean=nansum(nansum(nanmean(-dLW_q+dSW_q,3).*weight,2), ...
                        1);

% Divide by the global annual mean surface warming (units: W/m2/K)
q_feedback=dR_q_globalmean./dts_globalmean;

disp(['Water vapor feedback: ' num2str(q_feedback) ' W m^-2 K^-1'])

