###Prepare DEM(s) for Blender###
##Requirements##
# GDAL/OGR

###parameters
# #target_resolution = 1000 #consider also kicking out full res version?
target_projection="EPSG:32015" #proj4 or epsg
bounding_box=box.geojson #in WGS84

##############################
#Clear out previous work
if [ -d "./int" ]; then
	rm -r int
fi
#Create temporary directory
mkdir int

#from Derek Watkins cheatsheet
function ogr_extent() {
	if [ -z "$1" ]; then 
		echo "Missing arguments. Syntax:"
		echo "  ogr_extent <input_vector>"
    	return
	fi
	EXTENT=$(ogrinfo -al -so $1 |\
		grep Extent |\
		sed 's/Extent: //g' |\
		sed 's/(//g' |\
		sed 's/)//g' |\
		sed 's/ - /, /g')
	EXTENT=`echo $EXTENT | awk -F ',' '{print $1 " " $4 " " $3 " " $2}'`
	echo "$EXTENT"
}

##get bounding box in target projection(won't be rectangle any more)
ogr2ogr int/box_proj.shp -t_srs "$target_projection" $bounding_box

#test if multiple raster inputs, mosaic if so
if [ ! -z "$2" ]
then
	echo "Merging rasters..."
	gdal_merge.py -o int/a1_merged.tif "$@"
else
	cp $1 int/a1_merged.tif
fi

#reproject and clip to bounding box full raster
echo "Reprojecting raster..."
gdalwarp -t_srs "$target_projection" \
-r bilinear \
int/a1_merged.tif int/a2_projected.tif

#crop raster
echo "Cropping raster..."
gdal_translate -projwin $(ogr_extent int/box_proj.shp) \
-ot UInt16 \
int/a2_projected.tif int/a3_cropped.tif

#get min/max values
zMin=`gdalinfo -mm int/a3_cropped.tif | sed -ne 's/.*Computed Min\/Max=//p'| tr -d ' ' | cut -d "," -f 1 | cut -d . -f 1`
zMax=`gdalinfo -mm int/a3_cropped.tif | sed -ne 's/.*Computed Min\/Max=//p'| tr -d ' ' | cut -d "," -f 2 | cut -d . -f 1`

echo $zMin
echo $zMax
# #resample if necessary
# echo $(gdalinfo -mm int/a3_cropped.tif | grep Min/Max)
# #rescale and output as 16 bit unsigned TIF
 gdal_translate -scale $zMin $zMax 0 65535 \
 int/a3_cropped.tif a4_stretched.tif
