These data were prepared to be loaded into the NWC Data Platform in September 2017.

The source data are available here: https://www.epa.gov/waterdata/nhdplus-national-data

The outcomes are:  
`huc12.pgdump.gz`  
`huc12all.pgdump.gz`  
and `*_huc12agg.pgdump.gz`  

## Can be done by hand or automated with ogr2ogr\_local.sh

### Hand made `huc12.pgdump.gz` `huc12all.pgdump.gz`
First transferred to geopackage with:  
`ogr2ogr -f gpkg WBDHU12_NHDPlus.gpkg NHDPlusV21_National_Seamless.gdb -nln huc12all -sql "SELECT HUC_12 AS HUC12, HU_12_DS AS TOHUC, ACRES AS AREAACRES, AreaHUC12 AS AREASQKM, HU_12_NAME AS NAME, HU_12_TYPE AS HUTYPE, HU_12_MOD AS HUMOD, STATES as STATES, NCONTRB_A AS NONCONTRIB FROM HUC12" -lco GEOMETRY_NAME=the_geom`  
This renaming step is needed because the NWC data platform is based on attribute names from the primary WBD schema, not the NHDPlus WBD schema.  

This gets loaded into QGIS and clipped to state boundaries. This layer was then clipped to the US state boundaries to convey that we did not estimate water budget parameters in HUC areas outside the CONUS.
  
Then they get written to pgdump files and gziped.
`ogr2ogr -f PGDUMP huc12.pgdump WBDHU12_NHDPlus.gpkg huc12 -nln huc12 -lco GEOMETRY_NAME=the_geom`
`ogr2ogr -f PGDUMP huc12all.pgdump WBDHU12_NHDPlus.gpkg huc12all -nln huc12 -lco GEOMETRY_NAME=the_geom`
`gzip *.pgdump`

`huc12all.pgdump.gz` is the same as `huc12.pgdump.gz` but was not clipped. It is used as a visual aid in the NWC Portal.

### `*_huc12agg.pgdump.gz`
The `national_runner.R` script was run to create aggregate hucs. It outputs a collection of pgdump files, one for each region run by the national_runner.R. These each get deployed to artifactory and are used to deploy to the NWC Data Platform database.