library(jsonlite)
library(dplyr)
library(data.table)
library(rgdal)
library(rgeos)
library(maptools)
library(sp)
setwd("~/Documents/Projects/WaterSmart/5_data/databaseShapefiles/catchment_characteristics/points")
unzip(zipfile = "NHDPlusV2Outlets.zip")
for(zipf in list.files("./",pattern = "*.zip$",full.names=TRUE)) {
  unzip(zipf)
}
# system("for f in *.shp; do ogrinfo --config SHAPE_RESTORE_SHX true $f; done") # not sure why this doesn't work...

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

setwd("~/Documents/Projects/WaterSmart/5_data/databaseShapefiles/catchment_characteristics/")

metadata<-fromJSON("data_cleanup/metadata.json")

# cat_points <- readOGR("./points/outlet/outlet.shp", layer = "outlet", stringsAsFactors = FALSE)

cat_points <- all_shpfData

rm(all_shpfData)

orig_cat_points_data <- data.table(cat_points@data)

comids <- data.frame(as.integer(orig_cat_points_data$FEATUREID))

names(comids) <- c("comid")

comids$id <- 1:nrow(comids)

metadata_outfile <- "characteristic_metadata.csv"

names(metadata) <- c("characteristic_id", "characteristic_description", "units", "dataset_label",
										 "dataset_url", "theme_label", "theme_url", "characteristic_type")

datasets<-list()

extensions<-c("_acc", "_tot", "_cat")

tables<-c("divergence_routed_characteristics", 
					"total_accumulated_characteristics", 
					"local_catchment_characteristics")

metadataCols<-c()

total_steps <- 3*length(unique(metadata$dataset_url))

step <- 1

for(dataType in 1:3) {
	# dataType <- 1
	table<-tables[dataType]
	
	extension<-extensions[dataType]
	
	for(urlID in 1:length(unique(metadata$dataset_url))) {
	# urlID <- 1
		url <- unique(metadata$dataset_url)[urlID]
		
		rdsFile <- paste0("data_cleanup/rds/broken_out/",strsplit(url,split = "/")[[1]][6],extension,".rds")
		
		varsFromURL <- metadata$characteristic_id[which(metadata$dataset_url == url)]
		
		varData <- readRDS(rdsFile)
		
		if(length(names(varData))>1) {
			
			outFile <- paste0("./points/pgdump/",table, "_", strsplit(url,split = "/")[[1]][6], ".pgdump")
			
			if(!file.exists(outFile)) {
				
				dataTable <- data.frame(varData$COMID)
				
				names(dataTable) <-c("comid")
				
				for(column in 2:length(names(varData))) {
				
					colName <- names(varData)[column]
				
					if(!grepl("NODATA", colName)) {
					
						print(paste("Step ", step, "of", total_steps))
						
						characteristic_id <- 
							metadata$characteristic_id[which(metadata$characteristic_id %in% names(varData)[column][[1]])]
						
						characteristic_id_nodatap <- paste0(characteristic_id, "_percent_nodata")
						
						metadataCols <- 
							c(metadataCols, which(metadata$characteristic_id %in% names(varData)[column][[1]]))
						
						dataTable[characteristic_id] <- subset(varData,select = names(varData)[column])
						
						dataTable[characteristic_id][dataTable[characteristic_id] == -9999] <- NA
						
						if(any(grepl("NODATA", names(varData)))) {
							
							dataTable[characteristic_id_nodatap] <- as.integer(subset(varData, 
																												select = names(varData)[which(grepl("NODATA", names(varData)))])[[1]])
							
						} else {
							
							dataTable[characteristic_id_nodatap] <- 0
							
						}
						
						dataTable[characteristic_id_nodatap][dataTable[characteristic_id_nodatap] > 100] <- 100 # some nodata values were way big.
						
					}
				}
				
				cat_points@data <- comids
				cat_points@data <- merge(cat_points@data, dataTable, by = "comid", all.x = TRUE)
				cat_points@data <- cat_points@data[order(cat_points@data$id), ]
				writeOGR(cat_points, dsn = outFile, layer=outFile, driver = "PGDUMP")
				system(paste0("gzip ", outFile))
			}
		} else {
			print("Didn't find data for this dataset.")
		}
		
		step <- step + 1
	}
}

metadata <- metadata[metadataCols, ]
