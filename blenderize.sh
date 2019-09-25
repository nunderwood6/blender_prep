###Prepare DEM(s) for Blender###
##Requirements##
# GDAL/OGR

###parameters
target_projection="+proj=laea +lat_0=15.271832308917661 +lon_0=-90.615234375" #proj4 or epsg
bounding_box=box.geojson #in WGS84

##############################
#Clear out previous work
if [ -d "./blenderize_temp" ]; then
	rm -r blenderize_temp
fi
#Create temporary directory
mkdir blenderize_temp

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
ogr2ogr blenderize_temp/box_proj.shp -t_srs "$target_projection" $bounding_box

#test if multiple raster inputs, mosaic if so
if [ ! -z "$2" ]
then
	echo "Merging rasters..."
	gdal_merge.py -o blenderize_temp/a1_merged.tif "$@"
else
	cp $1 blenderize_temp/a1_merged.tif
fi

#reproject and clip to bounding box full raster
echo "Reprojecting raster..."
gdalwarp -t_srs "$target_projection" \
-s_srs "EPSG:4326" \
-r bilinear \
-of Gtiff \
blenderize_temp/a1_merged.tif blenderize_temp/a2_projected.tif

#crop raster
echo "Cropping raster..."
gdal_translate -projwin $(ogr_extent blenderize_temp/box_proj.shp) \
-of Gtiff \
-ot UInt16 \
blenderize_temp/a2_projected.tif blenderize_temp/a3_cropped.tif

#get min/max values
min=`gdalinfo -mm blenderize_temp/a3_cropped.tif | sed -ne 's/.*Computed Min\/Max=//p'| tr -d ' ' | cut -d "," -f 1 | cut -d . -f 1`
max=`gdalinfo -mm blenderize_temp/a3_cropped.tif | sed -ne 's/.*Computed Min\/Max=//p'| tr -d ' ' | cut -d "," -f 2 | cut -d . -f 1`

#rescale and output as 16 bit unsigned TIF
echo "Rescaling raster values..."
gdal_translate -scale $min $max 0 65535 \
-of Gtiff \
-ot UInt16 \
 blenderize_temp/a3_cropped.tif blenderize_temp/a4_stretched.tif

#final output
cp blenderize_temp/a4_stretched.tif dem_blender.tif

 #get rid of temporary files
 rm -r blenderize_temp


