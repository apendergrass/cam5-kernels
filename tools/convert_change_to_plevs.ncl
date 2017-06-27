load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

;ncl  convert_to_pressure.ncl 

;;;;;;; INPUTS ;;;;;;;;;;;;;;;;;;;;;
;; Output pressure levels [hPa] 
;; CMIP5 troposphere / stratosphere levels
plev_hPa=(/1000, 925, 850, 700, 600, 500, 400, 300, 250,  200, 150, 100, 70, 50, 30, 20, 10/) 
;; Upper stratosphere / mesosphere
;, 7, 5, 3, 2,  1, .40, .20, .10/)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

plev=plev_hPa*100 ; convert to Pa

inFile="demodata/changefields.nc"
outFile="changefields.plev.nc"
ps_file="kernels/PS.nc"

k_file="kernels/t.kernel.nc"

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

kf    = addfile(k_file, "r")
;; Hybrid-sigma coordinate coefficients for midpoint pressure
hyam = kf->hyam
hybm = kf->hybm
;; Hybrid-sigma coordinate coefficients for interface pressure
hyai = kf->hyai
hybi = kf->hybi

;; Reference pressure
P0 = kf->P0
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
ncdf->gw = kf->gw

pdiff_plev = vinth2p(pdiff(:,0:29,:,:),hyam,hybm,plev_hPa,PS,1,P0hPa,1,False)
copy_VarAtts(pdiff,pdiff_plev)
printVarSummary(pdiff_plev)
ncdf->pdiff=pdiff_plev

;; Vertically interpolate each variable, and write it to the output file
function interp_var(variable:string)
begin
	y=1
        x:=f->$variable$(:,0:29,:,:)
        ;; Vertical interpolation
	x_p = vinth2p(x(:,0:29,:,:),hyam,hybm,plev_hPa,PS,1,P0hPa,1,False)
	copy_VarAtts(f->$variable$,x_p)
	printVarSummary(x_p)
        ;; Write the variable to file
	ncdf->$variable$=x_p
return(y)
end

y=interp_var("Q") ; Longwave Surface all-sky
y=interp_var("temp"); Longwave Surface Clear-sky

end

