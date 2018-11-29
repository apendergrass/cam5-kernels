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

basefile='demodata/basefields.nc'; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

lat=ncread('kernels/PS.nc','lat');
lon=ncread('kernels/PS.nc','lon');
gw=ncread('kernels/t.kernel.nc','gw'); %% Gaussian weights for the CESM grid
lev=ncread('kernels/t.kernel.nc','lev');

% Area weight 
weight=repmat(gw(:)',[length(lon) 1]); 
weight=weight./nansum(nansum(weight));

% Read surface temperature change
dts=ncread(changefile,'ts');

% Calculate the change in global mean surface temperature
dts_globalmean=nansum(nansum(nanmean(dts,3).*weight,2),1);


% Midpoint pressure for each grid cell (lat,lon,level,month), [Pa]
p=ncread('p_sigma.nc','pmid')/100; %[hPa] 

% Crude tropopause; 
% Must have the same
% size as the pressure array
x=cosd(lat);
p_tropopause_zonalmean=300-200*x;
p_tropopause=repmat(permute(repmat(permute(repmat(p_tropopause_zonalmean',[length(lon) 1]),[1 2 3]),[1 1 length(lev)]),[1 2 3 4]),[1 1 1 12]);

%%%%%%% Water vapor feedback : using logarithmic q 

% Calculate the change in moisture per degree warming at constant relative humidity. 
% Run the accompanying NCL script with your input files, or
% implement here.                                                                                               
                           
% Read initial moisture
q0=ncread(basefile,'Q'); % kg/kg

t1=ncread(basefile,'temp');
dta=ncread(changefile,'temp');
addpath scripts/
qs1 = calcsatspechum(t1,p); % g/kg
qs2 = calcsatspechum(t1+dta,p); % g/kg
dqsdt = (qs2 - qs1)./dta;
rh = 1000*q0./qs1;
dqdt = rh.*dqsdt;

dlogqdt=dqdt./(1000*q0);


% Read kernels
q_LW_kernel=ncread('kernels/q.kernel.nc','FLNT');
q_SW_kernel=ncread('kernels/q.kernel.nc','FSNT');



% Normalize kernels by the change in moisture for 1 K warming at
% constant RH (log-q kernel)
logq_LW_kernel=q_LW_kernel./dlogqdt;
logq_SW_kernel=q_SW_kernel./dlogqdt;

% Read the change in moisture
dq=ncread(changefile,'Q');


% Mask out the stratosphere
dq=dq.*(p>=p_tropopause);

dlogq=dq./q0; 

% Convolve moisture kernel with change in moisture
dLW_logq=squeeze(nansum(logq_LW_kernel.*dlogq,3));
dSW_logq=squeeze(nansum(logq_SW_kernel.*dlogq,3));

% Add the LW and SW responses. Note the sign convention difference
% between LW and SW!
dR_logq_globalmean=nansum(nansum(nanmean(-dLW_logq+dSW_logq,3).*weight,2),1);

% Divide by the global annual mean surface warming (units: W/m2/K)
q_feedback=dR_logq_globalmean./dts_globalmean;

disp(['Water vapor feedback: ' num2str(q_feedback) ' W m^-2 K^-1'])


