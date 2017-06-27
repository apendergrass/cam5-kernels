# cam5-kernels
Demos and tools for radiative feedback kernels from CESM-CAM5 

Data citation for the data associated with these scripts:
Angeline G. Pendergrass, 2017, DOI:10.5065/D6F47MT6

Scientific reference for the data associated with these scripts: forthcoming (stay tuned)


QUICK START

Download the kernels, forcing, and demo data here: https://www.earthsystemgrid.org/workspace/user/summaryRequest.html

Unzip them. You'll need NCL and Matlab.

Clone the github repo into the cam5-kernels directory (so tools/ sits alongside scripts/).

Then you are ready for a test run! Try the things below - they use the included demo data. Expected results are included; if you get a different result, something might have gone wr\
ong with your installation.

After the test run, you can go through and replace everything from demodata/ with your own (real) data.


*Basic package
ncl scripts/calcp.ncl
ncl scripts/calcdq1k.ncl
matlab -nosplash -nodesktop -r "addpath ./scripts; kernel_demo"

Temperature feedback: -3.7261 W m^-2 K^-1
Surface albedo feedback: 0.53264 W m^-2 K^-1
Water vapor feedback: 2.0881 W m^-2 K^-1


*Conversion to pressure + Demo
ncl scripts/calcp.ncl
ncl tools/convert_base_to_plevs.ncl
ncl tools/calcdq1k_plevs.ncl
ncl tools/convert_change_to_plevs.ncl
ncl tools/t_kernel_to_plev.ncl
ncl tools/q_kernel_to_plev.ncl
matlab -nosplash -nodesktop -r "addpath ./tools; kernel_demo_pressure"

Temperature feedback: -3.7182 W m^-2 K^-1
Surface albedo feedback: 0.53264 W m^-2 K^-1
Water vapor feedback: 1.9939 W m^-2 K^-1

*Logq demo
ncl scripts/calcp.ncl
ncl scripts/calcdq1k.ncl
matlab -nosplash -nodesktop -r "addpath ./tools; logq_demo"

Water vapor feedback: 2.0881 W m^-2 K^-1

*Planck and lapse rate demo
matlab -nosplash -nodesktop -r "addpath ./tools; planck_lapserate_demo"

Planck feedback: -3.1844 W m^-2 K^-1
Lapse rate feedback: -0.54166 W m^-2 K^-1

Temperature feedback: -3.7261 W m^-2 K^-1
Planck+lapse rate components: -3.7261 W m^-2 K^-1

*Cloud feedback demo
matlab -nosplash -nodesktop -r "addpath ./tools; cloud_feedback_demo"

LW Cloud Feedback: -0.44253 W m^-2 K^-1
SW Cloud Feedback: 0.67713 W m^-2 K^-1

----

ACKNOWLEDGEMENTS
Andrew Conley and Francis Vitt (NCAR), for their help setting up the PORT calculation to make the kernels.
Ryan Kramer (University of Miami) and William Frey (University of Colorado), for their feedback and help testing the code

-----

Questions/comments? Please post in the issues tab. Other info: apgrass at ucar dot edu

