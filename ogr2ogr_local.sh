username=$1
password=$2
check=$3

if [ -z "$username" ]; then
     echo "You must pass in two variables, admin username, password."
     exit
fi

if [ -n "$check" ]; then
    echo "You must pass in two variables, admin username, password."
    exit
fi

# For failures about ecoding...
export PGCLIENTENCODING=LATIN1

# # Create new database role for tables
# psql -c "CREATE ROLE $username LOGIN PASSWORD '$password' NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;" postgresql://$username:$password@localhost:5432/
# 
# # Create database nwcGeoserver
# psql -c "CREATE DATABASE \"nwcGeoserver\" WITH OWNER = \"$username\";" postgresql://$username:$password@localhost:5432/
# 
# Install postgis extension
psql -c "CREATE EXTENSION postgis; CREATE EXTENSION postgis_topology;" postgresql://$username:$password@localhost:5432/nwcGeoserver
# 
# /usr/local/Cellar/gdal/1.11.1_3/bin/ogr2ogr -overwrite -progress -f "PostGreSQL" PG:"host=localhost user=$username password=$password dbname=nwcGeoserver" -nln "huc12_SE_Basins_v2" -nlt PROMOTE_TO_MULTI -lco "GEOMETRY_NAME=the_geom" -a_srs huc12_SE_Basins_v2/huc12_SE_Basins_v4.prj huc12_SE_Basins_v2/huc12_SE_Basins_v4.shp
# 
# /usr/local/Cellar/gdal/1.11.1_3/bin/ogr2ogr -overwrite -progress -f "PostGreSQL" PG:"host=localhost user=$username password=$password dbname=nwcGeoserver" -nln "huc12_SE_Basins_v2_local" -nlt PROMOTE_TO_MULTI -lco "GEOMETRY_NAME=the_geom" -a_srs huc12_SE_Basins_v2_local/huc12_SE_Basins_v4_local.prj huc12_SE_Basins_v2_local/huc12_SE_Basins_v4_local.shp
# 
# /usr/local/Cellar/gdal/1.11.1_3/bin/ogr2ogr -overwrite -progress -f "PostGreSQL" PG:"host=localhost user=$username password=$password dbname=nwcGeoserver" -nln "US_Historical_Counties" -nlt PROMOTE_TO_MULTI -lco "GEOMETRY_NAME=the_geom" -a_srs US_Historical_Counties/US_Historical_Counties.prj US_Historical_Counties/US_Historical_Counties.shp
# 
# /usr/local/Cellar/gdal/1.11.1_3/bin/ogr2ogr -overwrite -progress -f "PostGreSQL" PG:"host=localhost user=$username password=$password dbname=nwcGeoserver" -nln "HUC08" -nlt PROMOTE_TO_MULTI -lco "GEOMETRY_NAME=the_geom" -lco "PRECISION=NO" -a_srs  HUC08_30June2015/WBDHU8_clip.prj  HUC08_30June2015/WBDHU8_clip.shp
# 
# /usr/local/Cellar/gdal/1.11.1_3/bin/ogr2ogr -overwrite -progress -f "PostGreSQL" PG:"host=localhost user=$username password=$password dbname=nwcGeoserver" -nln "HUC12All" -nlt PROMOTE_TO_MULTI -lco "GEOMETRY_NAME=the_geom" -lco "PRECISION=NO" -a_srs  HUC12_30June2015/data/WBDHU12.prj  HUC12_30June2015/data/WBDHU12.shp
# 
# /usr/local/Cellar/gdal/1.11.1_3/bin/ogr2ogr -overwrite -progress -f "PostGreSQL" PG:"host=localhost user=$username password=$password dbname=nwcGeoserver" -nln "HUC12" -nlt PROMOTE_TO_MULTI -lco "GEOMETRY_NAME=the_geom" -lco "PRECISION=NO" -a_srs  HUC12_30June2015/data/WBDHU12_clip.prj  HUC12_30June2015/data/WBDHU12_clip.shp

# NOTE: These data are not checked in and can be recreated with the R script included in the HUC12 directory. 
/usr/local/Cellar/gdal/1.11.1_3/bin/ogr2ogr -overwrite -progress -f "PostGreSQL" PG:"host=localhost user=$username password=$password dbname=nwcGeoserver" -nln "HUC12Agg" -nlt PROMOTE_TO_MULTI -lco "GEOMETRY_NAME=the_geom" -lco "PRECISION=NO" -a_srs  EPSG:4269 HUC12_30June2015/HUC12_30June2015Agg/data/1.shp

for i in {1..100}; do /usr/local/Cellar/gdal/1.11.1_3/bin/ogr2ogr -append -progress -f "PostGreSQL" PG:"host=localhost user=$username password=$password dbname=nwcGeoserver" -nln "HUC12Agg" -nlt PROMOTE_TO_MULTI -lco "GEOMETRY_NAME=the_geom" -lco "PRECISION=NO" -a_srs  EPSG:4269 HUC12_30June2015/HUC12_30June2015Agg/data/"$i"001.shp; done 

# /usr/local/Cellar/gdal/1.11.1_3/bin/ogr2ogr -overwrite -progress -f "PostGreSQL" PG:"host=localhost user=$username password=$password dbname=nwcGeoserver" -nln "gagesii_basins" -nlt PROMOTE_TO_MULTI -lco "GEOMETRY_NAME=the_geom" -lco "PRECISION=NO" -a_srs EPSG:5070 -t_srs EPSG:4326 gagesii_boundaries/bas_ref_all.shp
# 
# for i in gagesii_boundaries/nonref/*.shp; do /usr/local/Cellar/gdal/1.11.1_3/bin/ogr2ogr -append -progress -f "PostGreSQL" PG:"host=localhost user=$username password=$password dbname=nwcGeoserver" -nln "gagesii_basins" -nlt PROMOTE_TO_MULTI -lco "GEOMETRY_NAME=the_geom" -lco "PRECISION=NO" -a_srs EPSG:5070 -t_srs EPSG:4326 $i; done 
# 
# /usr/local/Cellar/gdal/1.11.1_3/bin/ogr2ogr -overwrite -progress -f "PostGreSQL" PG:"host=localhost user=$username password=$password dbname=nwcGeoserver" -nln "epa_basins" -nlt PROMOTE_TO_MULTI -lco "GEOMETRY_NAME=the_geom" -lco "PRECISION=NO" -a_srs EPSG:5070 -t_srs EPSG:4326 basins_all/basins_all.shp
# 
# pg_dump -t huc12_SE_Basins_v2 postgresql://$username:$password@localhost/nwcGeoserver -O --file="dumps/huc12_se_basins_v2.pgdump"
# 
# pg_dump -t huc12_SE_Basins_v2_local postgresql://$username:$password@localhost/nwcGeoserver -O --file="dumps/huc12_se_basins_v2_local.pgdump"
# 
# pg_dump -t US_Historical_Counties postgresql://$username:$password@localhost/nwcGeoserver -O --file="dumps/us_historical_counties.pgdump"
# 
# pg_dump -t HUC08 postgresql://$username:$password@localhost/nwcGeoserver -O --file="dumps/huc08.pgdump"
# 
# pg_dump -t HUC12All postgresql://$username:$password@localhost/nwcGeoserver -O --file="dumps/huc12all.pgdump"
# 
# pg_dump -t HUC12 postgresql://$username:$password@localhost/nwcGeoserver -O --file="dumps/huc12.pgdump"

pg_dump -t huc12agg postgresql://$username:$password@localhost/nwcGeoserver -O --file="dumps/huc12agg.pgdump"
# 
# pg_dump -t gagesii_basins postgresql://$username:$password@localhost/nwcGeoserver -O --file="dumps/gagesii_basins.pgdump"
# 
# pg_dump -t epa_basins postgresql://$username:$password@localhost/nwcGeoserver -O --file="dumps/epa_basins.pgdump"

for file in dumps/*.pgdump; do gzip $file; done;

