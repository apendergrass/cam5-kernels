load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin
;;;;;;;;;;; CALL
;ncl calcdp_plev.ncl

;;;;;;;;;;;;; Inputs                                                                                                                                                                                                                                                                             
inFile="/path/to/basefields.plev.nc" ; This file should contain variables Q and temp                                                                                                                                                                                                            
;;;;;;;;;;;;;      
ps_file="kernels/PS.nc"
pf    = addfile(ps_file, "r")


plev_hPa=(/1000, 925, 850, 700, 600, 500, 400, 300, 250,  200, 150, 100, 70, 50, 30, 20, 10/)  ;; CMIP5 troposphere / stratosphere levels                 
plev:=plev_hPa*100 ; convert to Pa                                                                                                                          

vinfofile="kernels/t.kernel.nc" ; We are using information about the coordinate system stored in this file. 

outFile="dp_plev.nc"
NCFILE = outFile
;;;;;;;;;;;;; 

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

f    = addfile(vinfofile, "r")
lat = f->lat
lon = f->lon
time = f->time

;; Hybrid-sigma coordinate coefficients for midpoint pressure                                                                                                 
hyam = f->hyam
hybm = f->hybm
;; Hybrid-sigma coordinate coefficients for interface pressure                                                                                                
hyai = f->hyai
hybi = f->hybi

;; Define global attributes for output file                                                                                                                   
globeAtt              = 1
globeAtt@title        = "Change in pressure on pressure levels"
globeAtt@source_file  = vinfofile
globeAtt@creation_date= systemfunc ("date" )

;; Define dimensions                                                                                                                                          
dim_names = (/"time","plev","lat","lon"/)
dim_sizes = (/12,ds_p,192,288/)
dim_unlimited = (/True,False,False,False/)

;; Open the output netcdf file and provide attributes                                                                                                         
system ("/bin/rm -f " +  outFile)    ; remove any pre-existing file                                                                                           
ncdf   = addfile(outFile,"c")
fileattdef( ncdf, globeAtt )        ; create file attributes                                                                                                  

;; Write coordinate variables                                                                                                                                 
ncdf->time = time
ncdf->plev = plev
ncdf->lat = lat
ncdf->lon = lon
;; Area weight                                                                                                                                                
ncdf->gw = f->gw


;; Calculate pressure thicknesses on pressure grid
ptop=min(plev)
dp=dpres_plevel(plev,PS,ptop,0)

dp!0 = "time" 
dp!1 = "plev" 
dp!2 = "lat" 
dp!3 = "lon" 
dp&time=f->time 
dp&plev=plev
dp&lat=f->lat
dp&lon=f->lon

dp@units="Pa"
dp@positive="down"
dp@axis="Z"
dp@longname="pressure difference"
dp@standard_name="pressure difference"


; Write the data out
system ("/bin/rm -f " +  NCFILE)    ; Remove any pre-existing file
ncdf   = addfile(NCFILE,"c")

globeAtt              = 1
globeAtt@title        = "Change in pressure on pressure coordinate"
globeAtt@source_file  = ps_file
globeAtt@creation_date= systemfunc ("date" )

fileattdef( ncdf, globeAtt )        ; Create the global [file] attributes

ncdf->dp = dp  ; Pa

end