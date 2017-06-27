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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            

% Read in coordinate info
lat=ncread('kernels/PS.nc','lat');
lon=ncread('kernels/PS.nc','lon');
gw=ncread('kernels/t.kernel.nc','gw'); %% Gaussian weights for the
                                       %% CESM grid
lev=ncread('kernels/t.kernel.nc','lev');

% Make an area weighting matrix
weight=repmat(gw(:)',[length(lon) 1]);
weight=weight./nansum(nansum(weight));

% Read surface temperature change
dts=ncread(changefile,'ts');

% Calculate the change in global mean surface temperature
dts_globalmean=nansum(nansum(nanmean(dts,3).*weight,2),1);


%%% Temperature feedback calculation                                                                                                                                                  
% Read TOA Longwave surface temperature kernel
ts_kernel=ncread('kernels/ts.kernel.nc','FLNT');

% Multiply monthly mean TS change by the TS kernels (function of
% lat, lon, month) (units W/m2)
dLW_ts=ts_kernel.*dts;

% Read air temperature change [lon,lat,level,month]
dta=ncread(changefile,'temp');

% Read midpoint pressure for each grid cell (lat,lon,level,month),
% [Pa]
p=ncread('p_sigma.nc','pmid')/100; %[hPa] 

% Crude tropopause estimate: 100 hPa in the tropics, lowering with
% cosine to 300 hPa at the poles.
x=cosd(lat);
p_tropopause_zonalmean=300-200*x;
p_tropopause= ...
    repmat(permute(repmat(permute(repmat(p_tropopause_zonalmean', ...
                                         [length(lon) 1]),[1 2 3]),[1 ...
                    1 length(lev)]),[1 2 3 4]),[1 1 1 12]);

% Set the temperature change to zero in the stratosphere (mask out
% stratosphere)
dta=dta.*(p>=p_tropopause);

% Read air temperature kernel
ta_kernel=ncread('kernels/t.kernel.nc','FLNT');

% Convolve air temperature kernel with air temperature change
dLW_ta=squeeze(sum(ta_kernel.*dta,3));

% Add the surface and air temperature response; Take the annual
% average and global area average 
dLW_t_globalmean=nansum(nansum(nanmean(-dLW_ta-dLW_ts,3).*weight, ...
                               2),1);

% Divide by the global annual mean surface warming (units: W/m2/K)
t_feedback=dLW_t_globalmean./dts_globalmean;

%disp(['Temperature feedback: ' num2str(t_feedback) ' W m^-2 K^-1'])




%%%%% Planck feedback: vertically uniform temperature change.                                                                                                                            
% Project surface temperature change into height 
dts3d=repmat(permute(dts,[1 2 4 3]),[1 1 30 1]);

% Mask stratosphere
dt_planck=dts3d.*(p>=p_tropopause);

% Convolve air temperature kernel with 3-d surface air temp change
dLW_planck=squeeze(sum(ta_kernel.*dt_planck,3));

% Take the annual average and global area average; incorporate the
% part due to surface temperature change itself 
dLW_planck_globalmean=nansum(nansum(nanmean(-dLW_planck-dLW_ts,3).*weight,2),1);

% Divide by the global annual mean surface warming (units: W/m2/K)
planck_feedback=dLW_planck_globalmean./dts_globalmean;



%%%% Lapse rate feedback                                                                                                                                                                 
% Calculate the departure of temperature change from the surface
% temperature change
dt_lapserate=(dta-dt_planck).*(p>=p_tropopause);;

% Convolve air temperature kernel with 3-d surface air temp change
dLW_lapserate=squeeze(sum(ta_kernel.*dt_lapserate,3));

% Take the annual average and global area average 
dLW_lapserate_globalmean=nansum(nansum(nanmean(-dLW_lapserate,3).*weight, ...
                                    2),1);

% Divide by the global annual mean surface warming (units: W/m2/K)
lapserate_feedback=dLW_lapserate_globalmean./dts_globalmean;

disp(['Planck feedback: ' num2str(planck_feedback) ' W m^-2 K^-1'])
disp(['Lapse rate feedback: ' num2str(lapserate_feedback) ' W m^-2 K^-1'])
disp(' ')


%%% SANITY CHECK: Do the Planck and lapse-rate feedbacks add up to
%%% the total temperature feedback? (They should)

% Planck + lapse rate feedback
total_t_feedback=planck_feedback+lapserate_feedback;

disp(['Temperature feedback: ' num2str(t_feedback) ' W m^-2 K^-1'])
disp(['Planck+lapse rate components: ' num2str(total_t_feedback) ' W m^-2 K^-1'])

