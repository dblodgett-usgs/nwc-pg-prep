username=$1

# For failures about ecoding...
# export PGCLIENTENCODING=LATIN1

# # Create new database role for tables
# psql -c "CREATE ROLE $username LOGIN PASSWORD '$password' NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;" postgresql://$username:$password@localhost:5432/
# 
# # Create database nwcGeoserver
# psql -c "CREATE DATABASE \"nwcGeoserver\" WITH OWNER = \"$username\";" postgresql://$username@localhost:5432/
# 
# Install postgis extension
# psql -c "CREATE EXTENSION postgis; CREATE EXTENSION postgis_topology;" postgresql://$username@localhost:5432/nwcGeoserver
# 
# ogr2ogr -overwrite -progress -f "PostGreSQL" PG:"host=localhost user=$username password=$password dbname=nwcGeoserver" -nln "huc12_SE_Basins_v2" -nlt PROMOTE_TO_MULTI -lco "GEOMETRY_NAME=the_geom" -a_srs huc12_SE_Basins_v2/huc12_SE_Basins_v4.prj huc12_SE_Basins_v2/huc12_SE_Basins_v4.shp
# 
# ogr2ogr -overwrite -progress -f "PostGreSQL" PG:"host=localhost user=$username password=$password dbname=nwcGeoserver" -nln "huc12_SE_Basins_v2_local" -nlt PROMOTE_TO_MULTI -lco "GEOMETRY_NAME=the_geom" -a_srs huc12_SE_Basins_v2_local/huc12_SE_Basins_v4_local.prj huc12_SE_Basins_v2_local/huc12_SE_Basins_v4_local.shp
# 
# ogr2ogr -overwrite -progress -f "PostGreSQL" PG:"host=localhost user=$username dbname=nwcGeoserver" -nln "US_Historical_Counties" -nlt PROMOTE_TO_MULTI -lco "GEOMETRY_NAME=the_geom" -a_srs US_Historical_Counties/US_Historical_Counties.prj US_Historical_Counties/US_Historical_Counties.shp
# 
# ogr2ogr -overwrite -progress -f "PostGreSQL" PG:"host=localhost user=$username password=$password dbname=nwcGeoserver" -nln "HUC08" -nlt PROMOTE_TO_MULTI -lco "GEOMETRY_NAME=the_geom" -lco "PRECISION=NO" -a_srs  HUC08_30June2015/WBDHU8_clip.prj  HUC08_30June2015/WBDHU8_clip.shp
# 
# ogr2ogr -overwrite -progress -f "PostGreSQL" PG:"host=localhost user=$username dbname=nwcGeoserver" ../NHDPlusV21_National_Seamless.gdb -sql "SELECT HUC_12 AS HUC12, HU_12_DS AS TOHUC, ACRES AS AREAACRES, AreaHUC12 AS AREASQKM, HU_12_NAME AS NAME, HU_12_TYPE AS HUTYPE, HU_12_MOD AS HUMOD, STATES as STATES, NCONTRB_A AS NONCONTRIB FROM HUC12" -nln huc12all_temp -nlt PROMOTE_TO_MULTI -lco GEOMETRY_NAME=the_geom -lco "PRECISION=NO"

# psql -c "CREATE TABLE huc12all AS (SELECT huc12, tohuc, areaacres, areasqkm, name, hutype,humod, states, noncontrib, st_SimplifyPreserveTopology(the_geom, 0.0005) as the_geom FROM huc12all_temp);" postgresql://$username@localhost:5432/nwcGeoserver

# psql -c "DROP TABLE huc12all_temp;" postgresql://$username@localhost:5432/nwcGeoserver

# sleep 10
# psql -c "CREATE TABLE union_county AS (SELECT ST_MakeValid(ST_Simplify(ST_Union(ST_Transform(us_historical_counties.the_geom, 4269)), 0.1, false)) as the_geom FROM us_historical_counties)" postgresql://$username@localhost:5432/nwcGeoserver
# psql -c "CREATE TABLE huc12 AS (SELECT * FROM huc12all);" postgresql://$username@localhost:5432/nwcGeoserver
# psql -c "UPDATE huc12 SET the_geom = ST_Multi(ST_Intersection(huc12.the_geom, union_county.the_geom)) FROM union_county WHERE ST_Intersects(huc12.the_geom, union_county.the_geom);" postgresql://$username@localhost:5432/nwcGeoserver
# psql -c "DROP TABLE union_county;" postgresql://$username@localhost:5432/nwcGeoserver
# psql -c "DELETE FROM huc12 WHERE states = 'CAN';" postgresql://$username@localhost:5432/nwcGeoserver

# ogr2ogr -overwrite -progress -f "PostGreSQL" PG:"host=localhost user=$username password=$password dbname=nwcGeoserver" -nln "gagesii_basins" -nlt PROMOTE_TO_MULTI -lco "GEOMETRY_NAME=the_geom" -lco "PRECISION=NO" -a_srs EPSG:5070 -t_srs EPSG:4326 gagesii_boundaries/bas_ref_all.shp
# 
# for i in gagesii_boundaries/nonref/*.shp; do ogr2ogr -append -progress -f "PostGreSQL" PG:"host=localhost user=$username password=$password dbname=nwcGeoserver" -nln "gagesii_basins" -nlt PROMOTE_TO_MULTI -lco "GEOMETRY_NAME=the_geom" -lco "PRECISION=NO" -a_srs EPSG:5070 -t_srs EPSG:4326 $i; done 
# 
# ogr2ogr -overwrite -progress -f "PostGreSQL" PG:"host=localhost user=$username password=$password dbname=nwcGeoserver" -nln "epa_basins" -nlt PROMOTE_TO_MULTI -lco "GEOMETRY_NAME=the_geom" -lco "PRECISION=NO" -a_srs EPSG:5070 -t_srs EPSG:4326 basins_all/basins_all.shp
# 
# pg_dump -t huc12_SE_Basins_v2 postgresql://$username:$password@localhost/nwcGeoserver -O --file="dumps/huc12_se_basins_v2.pgdump"
# 
# pg_dump -t huc12_SE_Basins_v2_local postgresql://$username:$password@localhost/nwcGeoserver -O --file="dumps/huc12_se_basins_v2_local.pgdump"
# 
# pg_dump -t US_Historical_Counties postgresql://$username:$password@localhost/nwcGeoserver -O --file="dumps/us_historical_counties.pgdump"
# 
# pg_dump -t HUC08 postgresql://$username:$password@localhost/nwcGeoserver -O --file="dumps/huc08.pgdump"
# 
# pg_dump -t huc12all postgresql://$username@localhost/nwcGeoserver -O --file="dumps/huc12all.pgdump"
#
# pg_dump -t huc12 postgresql://$username@localhost/nwcGeoserver -O --file="dumps/huc12.pgdump"

# pg_dump -t huc12agg postgresql://$username:$password@localhost/nwcGeoserver -O --file="dumps/huc12agg.pgdump"
# 
# pg_dump -t gagesii_basins postgresql://$username:$password@localhost/nwcGeoserver -O --file="dumps/gagesii_basins.pgdump"
# 
# pg_dump -t epa_basins postgresql://$username:$password@localhost/nwcGeoserver -O --file="dumps/epa_basins.pgdump"

# for file in dumps/*.pgdump; do gzip $file; done;

