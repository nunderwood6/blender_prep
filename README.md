# Presented at NACIS 2019 Tacoma
## Slides: https://docs.google.com/presentation/d/1NsMC0njfmOL_zAwykQmDOSz9UOq0T5XuugGsa9jki64/edit?usp=sharing

Script to expedite preparing DEM's for Blender.

As described in Daniel Huffman's [Creating Shaded Relief in Blender](https://somethingaboutmaps.wordpress.com/2017/11/16/creating-shaded-relief-in-blender/), significant work is necessary to find and prepare elevation data prior to rendering it in Blender. This work often includes mosaicing, reprojecting, clipping, resampling, rescaling, and translating DEM's(digital elevation models). While some of these steps require decisions specific to the project, many are repetitive. This repo contains a bash script which utilizes open source command line tools to expedite this work.

# How to Use
1) Clone/download the repo.
2) Make sure [GDAL/OGR](https://gdal.org/) is installed. (gdalinfo --version)
3) Create a vector specifying your area of interest and add to the project folder. Default points to "box.geojson"- to update, open "blenderize.sh" with your text editor of choice and update the "bounding_box" variable.
4) Find and download DEM(s) which cover at least your area of interest. Err on the side of including more than you think you might need. Add your DEM's to the project folder.
5) Specify your target projection by updating the "target_projection" variable in "blenderize.sh". EPSG codes or proj4 strings are acceptable.
6) Open a command line window, navigate to the project folder, and run:
 sh blenderize.sh [space-separated list of DEM's]
 For example:
 sh blenderize.sh my_dem.tif //just one DEM
 sh blenderize.sh *.tif //all DEM's in project folder

#Notes
By default, the script will mosaic(if there are multiple dems), reproject to your target projection, clip to your bounding box, and output a TIF with 16-bit unsigned integer values, scaled from 0 to 65,535. The script *does not* resample the DEM, instead retaining the full resolution of the input data. If I want to quickly resample my elevation data, I just pull the output into photoshop and make sure to resize with resampling set to cubic or bilinear. Here's a couple good resources for more on generalizing elevation data for hillshading:
https://cartographicperspectives.org/index.php/journal/article/view/cp67-leonowicz-et-al/pdf
http://shadedrelief.com/tutorials.html
https://somethingaboutmaps.wordpress.com/2011/10/18/on-generalization-blending-for-shaded-relief/
