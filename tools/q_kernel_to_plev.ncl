load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

;ncl  convert_to_pressure.ncl 

;;;;;;; INPUTS ;;;;;;;;;;;;;;;;;;;;;
;; Pressure levels [hPa] 
plev_hPa=(/1000, 925, 850, 700, 600, 500, 400, 300, 250,  200, 150, 100, 70, 50, 30, 20, 10/)  ;; CMIP5 troposphere / stratosphere levels
;; plev_hPa=(/7, 5, 3, 2,  1, .40, .20, .10/) ;; Upper stratosphere / mesosphere
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

plev=plev_hPa*100 ; convert to Pa

kernel="q"

inFile="kernels/"+kernel+".kernel.nc"
outFile=kernel+".kernel.plev.nc"
ps_file="kernels/PS.nc"

pf    = addfile(ps_file, "r")

PS=pf->PS
PShPa=PS*0.01  ; convert surface pressure to hPa from Pa

;; Number of pressure levels to interpolate to
ds_p = dimsizes(plev)
print(ds_p+" pressure levels")
;; Pressure attributes
plev@units="Pa"
plev@positive="down"
plev@axis="Z"
plev@longname="pressure"
plev@standard_name="air_pressure"

f    = addfile(inFile, "r")
lat = f->lat
lon = f->lon
time = f->time

;; Hybrid-sigma coordinate coefficients for midpoint pressure
hyam = f->hyam
hybm = f->hybm
;; Hybrid-sigma coordinate coefficients for interface pressure
hyai = f->hyai
hybi = f->hybi

;; Reference pressure
P0 = f->P0
P0hPa=P0*0.01 ; convert to hPa

;; Calculate the thickness of each layer
pdiff=dpres_hybrid_ccm(PS,P0,hyai,hybi)

;; Define global attributes for output file 
globeAtt              = 1
globeAtt@title        = "Differences in radiative fields calculated with PORT"
globeAtt@source_file  = inFile
globeAtt@creation_date= systemfunc ("date" )

;; Open the output netcdf file and provide attributes
system ("/bin/rm -f " +  outFile)    ; remove any pre-existing file
ncdf   = addfile(outFile,"c")
fileattdef( ncdf, globeAtt )        ; create file attributes

;; Define dimensions
dim_names = (/"time","plev","lat","lon"/)
dim_sizes = (/12,ds_p,192,288/)
dim_unlimited = (/True,False,False,False/)

;; Write coordinate variables
ncdf->time = f->time
ncdf->plev = plev
ncdf->lat = f->lat
ncdf->lon = f->lon
;; Area weight
ncdf->gw = f->gw

pdiff_plev = vinth2p(pdiff(:,0:29,:,:),hyam,hybm,plev_hPa,PS,1,P0hPa,1,False)
pdiff_plev@units="Pa"
pdiff_plev@positive="down"
pdiff_plev@axis="Z"
pdiff_plev@longname="pressure difference"
pdiff_plev@standard_name="pressure difference"
ncdf->pdiff=pdiff_plev

;; Vertically interpolate each variable, and write it to the output file
function interp_var(variable:string)
begin
	y=1
        dR_sigma:=f->$variable$(:,0:29,:,:)
	printVarSummary(dR_sigma)
        dR_pweight=dR_sigma/(pdiff/100) ; convert to W m^-2 hPa^-1
        ;; Vertical interpolation
	dR_p = vinth2p(dR_pweight(:,0:29,:,:),hyam,hybm,plev_hPa,PS,1,P0hPa,1,False)
	copy_VarAtts(f->$variable$,dR_p)
        dR_p!0 = "time"
        dR_p!1 = "plev"
        dR_p!2 = "lat"
        dR_p!3 = "lon"
        dR_p&time=time
        dR_p&plev=plev
        dR_p&lat=lat
        dR_p&lon=lon
	printVarSummary(dR_p)
        ;; Write the variable to file
	ncdf->$variable$=dR_p
return(y)
end

y=interp_var("FLNS") ; Longwave Surface all-sky
y=interp_var("FLNSC"); Longwave Surface Clear-sky
y=interp_var("FLNT") ; Longwave Top-of-atmosphere all-sky
y=interp_var("FLNTC"); Longwave Top-of-atmosphere Clear-sky
y=interp_var("FSNS") ; Shortwave Surface all-sky
y=interp_var("FSNSC"); Shortwave Surface Clear-sky
y=interp_var("FSNT") ; Shortwave Top-of-atmosphere all-sky
y=interp_var("FSNTC"); Shortwave Top-of-atmosphere Clear-sky

end

