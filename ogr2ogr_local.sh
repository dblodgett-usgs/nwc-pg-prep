username=$1
password=$2

# For failures about ecoding...
export PGCLIENTENCODING=LATIN1

/usr/local/Cellar/gdal/1.11.1_3/bin/ogr2ogr -overwrite -progress -f "PostGreSQL" PG:"host=localhost user=$username password=$password dbname=nwcGeoserver" -nln "huc12_SE_Basins_v2" -nlt PROMOTE_TO_MULTI -lco "GEOMETRY_NAME=the_geom" -a_srs huc12_SE_Basins_v2/huc12_SE_Basins_v4.prj huc12_SE_Basins_v2/huc12_SE_Basins_v4.shp

/usr/local/Cellar/gdal/1.11.1_3/bin/ogr2ogr -overwrite -progress -f "PostGreSQL" PG:"host=localhost user=$username password=$password dbname=nwcGeoserver" -nln "huc12_SE_Basins_v2_local" -nlt PROMOTE_TO_MULTI -lco "GEOMETRY_NAME=the_geom" -a_srs huc12_SE_Basins_v2_local/huc12_SE_Basins_v4_local.prj huc12_SE_Basins_v2_local/huc12_SE_Basins_v4_local.shp

/usr/local/Cellar/gdal/1.11.1_3/bin/ogr2ogr -overwrite -progress -f "PostGreSQL" PG:"host=localhost user=$username password=$password dbname=nwcGeoserver" -nln "US_Historical_Counties" -nlt PROMOTE_TO_MULTI -lco "GEOMETRY_NAME=the_geom" -a_srs US_Historical_Counties/US_Historical_Counties.prj US_Historical_Counties/US_Historical_Counties.shp

/usr/local/Cellar/gdal/1.11.1_3/bin/ogr2ogr -overwrite -progress -f "PostGreSQL" PG:"host=localhost user=$username password=$password dbname=nwcGeoserver" -nln "HUC08" -nlt PROMOTE_TO_MULTI -lco "GEOMETRY_NAME=the_geom" -lco "PRECISION=NO" -a_srs  HUC08_30June2015/WBDHU8_clip.prj  HUC08_30June2015/WBDHU8_clip.shp

/usr/local/Cellar/gdal/1.11.1_3/bin/ogr2ogr -overwrite -progress -f "PostGreSQL" PG:"host=localhost user=$username password=$password dbname=nwcGeoserver" -nln "HUC12All" -nlt PROMOTE_TO_MULTI -lco "GEOMETRY_NAME=the_geom" -lco "PRECISION=NO" -a_srs  HUC12_30June2015/WBDHU12.prj  HUC12_30June2015/WBDHU12.shp

/usr/local/Cellar/gdal/1.11.1_3/bin/ogr2ogr -overwrite -progress -f "PostGreSQL" PG:"host=localhost user=$username password=$password dbname=nwcGeoserver" -nln "HUC12" -nlt PROMOTE_TO_MULTI -lco "GEOMETRY_NAME=the_geom" -lco "PRECISION=NO" -a_srs  HUC12_30June2015/WBDHU12_clip.prj  HUC12_30June2015/WBDHU12_clip.shp

/usr/local/Cellar/gdal/1.11.1_3/bin/ogr2ogr -overwrite -progress -f "PostGreSQL" PG:"host=localhost user=$username password=$password dbname=nwcGeoserver" -nln "HUC12Agg" -nlt PROMOTE_TO_MULTI -lco "GEOMETRY_NAME=the_geom" -lco "PRECISION=NO" -a_srs  EPSG:4269 -s_srs EPSG:4269 -t_srs EPSG:5070 HUC12_30June2015Agg/1.shp

for i in {1..100}; do /usr/local/Cellar/gdal/1.11.1_3/bin/ogr2ogr -append -progress -f "PostGreSQL" PG:"host=localhost user=$username password=$password dbname=nwcGeoserver" -nln "HUC12Agg" -nlt PROMOTE_TO_MULTI -lco "GEOMETRY_NAME=the_geom" -lco "PRECISION=NO" -a_srs  EPSG:4269 -s_srs EPSG:4269 -t_srs EPSG:5070 HUC12_30June2015Agg/"$i"001.shp; done 

/usr/local/Cellar/gdal/1.11.1_3/bin/ogr2ogr -overwrite -progress -f "PostGreSQL" PG:"host=localhost user=$username password=$password dbname=nwcGeoserver" -nln "gagesii_basins" -nlt PROMOTE_TO_MULTI -lco "GEOMETRY_NAME=the_geom" -lco "PRECISION=NO" -a_srs EPSG:5070 -t_srs EPSG:4326 gagesii_boundaries/bas_ref_all.shp

for i in gagesii_boundaries/nonref/*.shp; do /usr/local/Cellar/gdal/1.11.1_3/bin/ogr2ogr -append -progress -f "PostGreSQL" PG:"host=localhost user=$username password=$password dbname=nwcGeoserver" -nln "gagesii_basins" -nlt PROMOTE_TO_MULTI -lco "GEOMETRY_NAME=the_geom" -lco "PRECISION=NO" -a_srs EPSG:5070 -t_srs EPSG:4326 $i; done 

/usr/local/Cellar/gdal/1.11.1_3/bin/ogr2ogr -overwrite -progress -f "PostGreSQL" PG:"host=localhost user=$username password=$password dbname=nwcGeoserver" -nln "epa_basins" -nlt PROMOTE_TO_MULTI -lco "GEOMETRY_NAME=the_geom" -lco "PRECISION=NO" -a_srs EPSG:5070 -t_srs EPSG:4326 basins_all/basins_all.shp

pg_dump -t huc12_SE_Basins_v2 postgresql://$username:$password@localhost/nwcGeoserver -O --file="dumps/huc12_SE_Basins_v2.pgdump"

pg_dump -t huc12_SE_Basins_v2_local postgresql://$username:$password@localhost/nwcGeoserver -O --file="dumps/huc12_SE_Basins_v2_local.pgdump"

pg_dump -t US_Historical_Counties postgresql://$username:$password@localhost/nwcGeoserver -O --file="dumps/US_Historical_Counties.pgdump"

pg_dump -t HUC08 postgresql://$username:$password@localhost/nwcGeoserver -O --file="dumps/HUC08.pgdump"

pg_dump -t HUC12All postgresql://$username:$password@localhost/nwcGeoserver -O --file="dumps/HUC12All.pgdump"

pg_dump -t HUC12 postgresql://$username:$password@localhost/nwcGeoserver -O --file="dumps/HUC12.pgdump"

pg_dump -t HUC12Agg postgresql://$username:$password@localhost/nwcGeoserver -O --file="dumps/HUC12Agg.pgdump"

pg_dump -t gagesii_basins postgresql://$username:$password@localhost/nwcGeoserver -O --file="dumps/gagesii_basins.pgdump"

pg_dump -t epa_basins postgresql://$username:$password@localhost/nwcGeoserver -O --file="dumps/epa_basins.pgdump"

