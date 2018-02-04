export PGCLIENTENCODING=LATIN1
# for f in *.gz; do
#   echo "gunzip -c $f | psql postgresql://localhost:5432/nwcGeoserver"
# done
gunzip -c california_huc12agg.pgdump.gz | psql postgresql://localhost:5432/nwcGeoserver
gunzip -c colorado_huc12agg.pgdump.gz | psql postgresql://localhost:5432/nwcGeoserver
gunzip -c greatBasin_huc12agg.pgdump.gz | psql postgresql://localhost:5432/nwcGeoserver
gunzip -c greatLakes_huc12agg.pgdump.gz | psql postgresql://localhost:5432/nwcGeoserver
gunzip -c midAtlantic_huc12agg.pgdump.gz | psql postgresql://localhost:5432/nwcGeoserver
gunzip -c mississippi_huc12agg.pgdump.gz | psql postgresql://localhost:5432/nwcGeoserver
gunzip -c newEngland_huc12agg.pgdump.gz | psql postgresql://localhost:5432/nwcGeoserver
gunzip -c pacificNorthwest_huc12agg.pgdump.gz | psql postgresql://localhost:5432/nwcGeoserver
gunzip -c rioGrande_huc12agg.pgdump.gz | psql postgresql://localhost:5432/nwcGeoserver
gunzip -c sourisRedRainy_huc12agg.pgdump.gz | psql postgresql://localhost:5432/nwcGeoserver
gunzip -c southAtlanticGolf_huc12agg.pgdump.gz | psql postgresql://localhost:5432/nwcGeoserver
gunzip -c texasGolf_huc12agg.pgdump.gz | psql postgresql://localhost:5432/nwcGeoserver
gunzip -c huc12agg_final_merge.psql.gz | psql postgresql://localhost:5432/nwcGeoserver
