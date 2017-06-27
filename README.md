# cam5-kernels
Demos and tools for radiative feedback kernels from CESM-CAM5 

----

## Citation
Data citation for the data associated with these scripts:
Angeline G. Pendergrass, 2017, [DOI:10.5065/D6F47MT6](http://dx.doi.org/10.5065/D6F47MT6)

Scientific reference for the data associated with these scripts: Forthcoming (stay tuned)

---- 

## Quick Start

1. Download the kernels, forcing, and demo data here: https://www.earthsystemgrid.org/workspace/user/summaryRequest.html
2. Unzip them. You'll also need NCL and Matlab.
3. Clone the github repo into the cam5-kernels directory (so `tools/` sits alongside `kernels/`, `forcing/`, and `demodata/`; `scripts/` will be replaced).
3. Then you are ready for a test run! Try the things below - they use the included demo data. Expected results are included; if you get a different result, something might have gone wrong with your installation.
4. After the test run, you can go through and replace everything from demodata/ with your own (real) data.


## Basic package
Calculate the necessary components and calculate the temperature, water vapor, and surface albedo feedbacks on CESM hybrid sigma-pressure levels.  
`ncl scripts/calcp.ncl`  
`ncl scripts/calcdq1k.ncl`  
`matlab -nosplash -nodesktop -r "addpath ./scripts; kernel_demo"`  

Expected result:  
> `Temperature feedback: -3.7261 W m^-2 K^-1  `  
> `Surface albedo feedback: 0.53264 W m^-2 K^-1  `  
> `Water vapor feedback: 2.0881 W m^-2 K^-1  `  


## Conversion from hybrid sigma-pressure to standard pressure vertical coordinate
Standard CMIP tropospheric pressure levels are the script's default. Stratospheric extension is also included.   
`ncl scripts/calcp.ncl`  
`ncl tools/convert_base_to_plevs.ncl`  
`ncl tools/calcdq1k_plevs.ncl`  
`ncl tools/convert_change_to_plevs.ncl`  
`ncl tools/t_kernel_to_plev.ncl`  
`ncl tools/q_kernel_to_plev.ncl`  
`matlab -nosplash -nodesktop -r "addpath ./tools; kernel_demo_pressure"`  

Expected result:  
> `Temperature feedback: -3.7182 W m^-2 K^-1`  
> `Surface albedo feedback: 0.53264 W m^-2 K^-1`  
> `Water vapor feedback: 1.9939 W m^-2 K^-1`  

## Logarithmic moisture 
For the water vapor kernel, use the logarithm of mositure instead of moisture itself as the independent variable. This is more accurate because the radiative effects of water vapor scale with its logarithm.   

`ncl scripts/calcp.ncl`  
`ncl scripts/calcdq1k.ncl`  
`matlab -nosplash -nodesktop -r "addpath ./tools; logq_demo"`

Expected result:  
>`Water vapor feedback: 2.0881 W m^-2 K^-1`  

## Planck and lapse rate feedback decomposition
Calculate the Planck and lapse rate feedbacks   
`matlab -nosplash -nodesktop -r "addpath ./tools; planck_lapserate_demo"`  

Expected result:    
>`Planck feedback: -3.1844 W m^-2 K^-1`  
>`Lapse rate feedback: -0.54166 W m^-2 K^-1`  
>`Temperature feedback: -3.7261 W m^-2 K^-1`  
>`Planck+lapse rate components: -3.7261 W m^-2 K^-1`  

## Cloud feedback 
Calculate LW and SW cloud feedbacks  
`matlab -nosplash -nodesktop -r "addpath ./tools; cloud_feedback_demo"` 

Expected result:  
> `LW Cloud Feedback: -0.44253 W m^-2 K^-1`  
> `SW Cloud Feedback: 0.67713 W m^-2 K^-1`  

---

## Acknowledgements  
Andrew Conley and Francis Vitt (NCAR): help setting up the PORT calculation to make the kernels.  
Ryan Kramer (University of Miami) and William Frey (University of Colorado): valuable feedback and help testing the code

-----

Questions/comments? Please post in the issues tab.  
Other info: apgrass at ucar dot edu

