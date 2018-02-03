library(rgeos)
library(rgdal)
library(sp)
setwd("~/Documents/Projects/WaterSmart/5_data/databaseShapefiles/catchment_characteristics/points")
prep <- TRUE
for(shpf in list.files("./",pattern = "*.shp$",full.names=TRUE)) {
	shpfData <- readOGR(shpf, verbose = FALSE, stringsAsFactors = FALSE)
	if(prep) {
		all_shpfData <- shpfData
		prep = FALSE 
	} else {
		all_shpfData <- spRbind(all_shpfData, shpfData)
	}
	print(shpf)
}
writeOGR(all_shpfData, dsn = "outlet", layer="outlet", driver = "ESRI Shapefile")
