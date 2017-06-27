load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

begin
;;;;;;;;;;; CALL
;ncl calcp.ncl

;;;;;;;;;;;;; Inputs 
psfile="kernels/PS.nc" ; Monthly mean surface pressure from 1 year of running CESM. 
vinfofile="kernels/t.kernel.nc" ; We are using information about the coordinate system stored in this file. 
;;;;;;;;;;;;; 

; Read in surface pressure
outFile="p_sigma.nc"
NCFILE = outFile
f = addfile(psfile, "r")
ps = f->PS    ; Surface pressure

; Read in coordinate info
f2 = addfile(vinfofile, "r")
hyam = f2->hyam    
hybm = f2->hybm    
hyai = f2->hyai    
hybi = f2->hybi    
p0 = f2->P0

; Use NCL functions to calculate pressure fields
pmid=pres_hybrid_ccm(ps,p0,hyam,hybm)
pdiff=dpres_hybrid_ccm(ps,p0,hyai,hybi)

; Add coordinate variables
pmid!0 = "time" 
pmid!1 = "lev" ; Hybrid sigma-pressure level
pmid!2 = "lat" 
pmid!3 = "lon" 
pmid&time=f->time 
pmid&lev=f2->lev
pmid&lat=f->lat
pmid&lon=f->lon

pdiff!0 = "time" 
pdiff!1 = "lev" 
pdiff!2 = "lat" 
pdiff!3 = "lon" 
pdiff&time=f->time 
pdiff&lev=f2->lev
pdiff&lat=f->lat
pdiff&lon=f->lon

; Write the data out
system ("/bin/rm -f " +  NCFILE)    ; Remove any pre-existing file
ncdf   = addfile(NCFILE,"c")

globeAtt              = 1
globeAtt@title        = "Change in pressure on hybrid sigma coordinate"
globeAtt@source_file  = psfile
globeAtt@creation_date= systemfunc ("date" )

fileattdef( ncdf, globeAtt )        ; Create the global [file] attributes

ncdf->pmid = pmid  ; Pa
ncdf->pdiff = pdiff ; Pa

end
