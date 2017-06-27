load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

begin
;;;;;;;;;;; CALL
;ncl calcdq1k.ncl

;;;;;;;;;;;;; Inputs 
inFile="basefields.plev.nc" ; This file should contain variables Q and temp 
;;;;;;;;;;;;; 

outFile="dq1k.plev.nc"
NCFILE = outFile
f = addfile(inFile, "r")
q = f->Q       ; Mixing ratio
t = f->temp    ; Temperature
p = f->plev

printVarSummary(q)
printVarSummary(p)
p:=conform(q,p,1)

qs0 = mixhum_ptd (p, t, 1) 
rh=q/qs0
qs1k = mixhum_ptd (p, t+1.0, 1)
q1k = rh*qs1k

q1k:=where(q1k.lt.q,q,q1k)  ; Prevents negative values of moisture and its change

dq1k=q1k-q

dq1k!0 = "time" 
dq1k!1 = "plev" ; Pressure levels
dq1k!2 = "lat" 
dq1k!3 = "lon" 
dq1k&time=f->time 
dq1k&plev=f->plev
dq1k&lat=f->lat
dq1k&lon=f->lon

printVarSummary(dq1k)


system ("/bin/rm -f " +  NCFILE)    ; Remove any pre-existing file
ncdf   = addfile(NCFILE,"c")

globeAtt              = 1
globeAtt@title        = "Change in mixing ratio for 1 K warming at constant RH"
globeAtt@source_file  = inFile
globeAtt@creation_date= systemfunc ("date" )

fileattdef( ncdf, globeAtt )        ; Create the global [file] attributes

ncdf->dq1k = dq1k  ; units: kg/kg

end
