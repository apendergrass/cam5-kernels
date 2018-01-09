# cam5-kernels
Demos and tools for radiative feedback kernels from CESM-CAM5 

----

## Citation
Download (and cite) the data associated with these scripts:
Angeline G. Pendergrass (2017) [![DOI](https://zenodo.org/badge/DOI/10.5065/D6F47MT6.svg)](https://zenodo.org/record/997902), and 
this software [![DOI](https://zenodo.org/badge/95038532.svg)](https://zenodo.org/badge/latestdoi/95038532)

Scientific reference for the data associated with these scripts: 

Pendergrass, A.G., Andrew Conley and Francis Vitt: Surface and top-of-atmosphere radiative feedback kernels for CESM-CAM5. In discussion/review at <i>Earth System Science Data</i>. <a href="https://doi.org/10.5194/essd-2017-108">doi:10.5194/essd-2017-108</a>.


---- 

## Quick Start
You'll need to have [NCL](https://www.ncl.ucar.edu/) and Matlab.
1. Download the kernels, forcing, and demo data here: https://www.earthsystemgrid.org/dataset/ucar.cgd.ccsm4.cam5-kernels.html  
2. Unzip them.  
`tar -xvf cam5-kernels.tar`  
3. Get the code here into the `cam5-kernels` directory.   
  a. Download the latest [release](https://github.com/apendergrass/cam5-kernels/releases) as a `.tar.gz` and then:  
`tar -xvvzf cam5-kernels-0.0.tar.gz -C cam5-kernels/ --strip-components=1`  
  b. An alternative if you have `git` installed:  
`cd cam5-kernels/`  
`rm -fr scripts/`  
`git init`  
`git remote add origin https://github.com/apendergrass/cam5-kernels.git`  
`git pull origin master`  
Either way, you should have `tools/` sitting alongside `kernels/`, `forcing/`, and `demodata/`; and `scripts/` will be replaced with the up-to-date version.  
4. Then you are ready for a test run! Try the things below - they use the included demo data. Expected results are included; if you get a different result, something might have gone wrong with your installation.
5. After the test run, you can go through and replace everything from `demodata/` with your own data.


## Basic package
Calculate the necessary components and calculate the temperature, water vapor, and surface albedo feedbacks on CESM hybrid sigma-pressure levels.  
`ncl scripts/calcp.ncl`  
`matlab -nosplash -nodesktop -r "addpath ./scripts; kernel_demo"`  

Expected result:  
> `Temperature feedback: -3.7261 W m^-2 K^-1  `  
> `Surface albedo feedback: 0.53264 W m^-2 K^-1  `  
> `Water vapor feedback: Water vapor feedback: 1.6158 W m^-2 K^-1  `  


## Conversion from hybrid sigma-pressure to standard pressure vertical coordinate
Standard CMIP tropospheric pressure levels are the script's default. Stratospheric extension is also included.   
`ncl scripts/calcp.ncl`  
`ncl tools/convert_base_to_plevs.ncl`  
`ncl tools/calcdp_plev.ncl`  
`ncl tools/convert_change_to_plevs.ncl`  
`ncl tools/t_kernel_to_plev.ncl`  
`ncl tools/q_kernel_to_plev.ncl`  
`matlab -nosplash -nodesktop -r "addpath ./tools; kernel_demo_pressure"`  

Expected result:  
> `Temperature feedback: -3.7424 W m^-2 K^-1`  
> `Surface albedo feedback: 0.53264 W m^-2 K^-1`  
> `Water vapor feedback: 1.5897 W m^-2 K^-1`  

## Logarithmic moisture 
For the water vapor kernel, use the logarithm of mositure instead of moisture itself as the independent variable. This is more accurate because the radiative effects of water vapor scale with its logarithm.   

`ncl scripts/calcp.ncl`  
`matlab -nosplash -nodesktop -r "addpath ./tools; logq_demo"`

Expected result:  
>`Water vapor feedback: 1.6158 W m^-2 K^-1`  

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
> `LW Cloud Feedback: -0.055163 W m^-2 K^-1`  
> `SW Cloud Feedback: 0.57637 W m^-2 K^-1`  

---

## Acknowledgements  
Andrew Conley and Francis Vitt (NCAR): help setting up the PORT calculation to make the kernels.  
Ryan Kramer (University of Miami) and William Frey (University of Colorado): valuable feedback and help testing the code. Paulo Ceppi (University of Reading): valuable testing and bug identification in the code. 

-----

Questions/comments? Post in the issues tab, or email me at apgrass at ucar dot edu

