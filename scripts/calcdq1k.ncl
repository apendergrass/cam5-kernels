load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

begin
;;;;;;;;;;; CALL
;ncl calcdq1k.ncl

;;;;;;;;;;;;; Inputs 
inFile="demodata/basefields.nc" ; This file should contain variables Q and temp 
pFile="p_sigma.nc" ; Generate this file from calcp.ncl and PS.nc. It contains the 3-d pressure field. 
;;;;;;;;;;;;; 

outFile="dq1k.nc"
NCFILE = outFile

; Read in base state moisture and temperature
f = addfile(inFile, "r")
q = f->Q       ; Mixing ratio
t = f->temp    ; Temperature

; Read pressure at midpoint of layers
f2 = addfile(pFile, "r")
p = f2->pmid    ; Pressure. You can generate this from PS on sigma coordinates with "calcp.ncl" 

; Calculate the moisture change in response to 1 K warming at constant relative humidity
qs0 = mixhum_ptd (p, t, 1)      ; Initial saturation mixing ratio
rh=q/qs0                        ; Relative humidity
qs1k = mixhum_ptd (p, t+1.0, 1) ; Saturation mixing ratio for +1 K state
q1k = rh*qs1k                   ; New mixing ratio

q1k:=where(q1k.lt.q,q,q1k)      ; Prevent negative values of moisture and its change

dq1k=q1k-q                      ; Mixing ratio response for 1 K warming

; Add coordinate variables
dq1k!0 = "time" 
dq1k!1 = "lev" ; This is the CESM hybrid-sigma level
dq1k!2 = "lat" 
dq1k!3 = "lon" 
dq1k&time=f->time 
dq1k&lev=f->lev
dq1k&lat=f->lat
dq1k&lon=f->lon

printVarSummary(dq1k)

; Write the data out
system ("/bin/rm -f " +  NCFILE)    ; Remove any pre-existing file
ncdf   = addfile(NCFILE,"c")

globeAtt              = 1
globeAtt@title        = "Change in mixing ratio for 1 K warming at constant RH"
globeAtt@source_file  = inFile
globeAtt@creation_date= systemfunc ("date" )

fileattdef( ncdf, globeAtt )        ; Create the global [file] attributes

ncdf->dq1k = dq1k  ; units: kg/kg

end
