library(jsonlite)
library(dplyr)
library(data.table)
library(netcdf.dsg)
# Assumes working directory has data_cleanup and dump_files directories.

setwd("~/Documents/Projects/WaterSmart/5_data/databaseShapefiles/catchment_characteristics/")

metadata<-fromJSON("data_cleanup/metadata.json")

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

# for(dataType in 1:3) {
	dataType <- 1
	table<-tables[dataType]
	
	extension<-extensions[dataType]
	
	for(urlID in 1:length(unique(metadata$dataset_url))) {
	
		url <- unique(metadata$dataset_url)[urlID]
		
		rdsFile <- paste0("data_cleanup/rds/broken_out/",strsplit(url,split = "/")[[1]][6],extension,".rds")
		
		varsFromURL <- metadata$characteristic_id[which(metadata$dataset_url == url)]
		
		varData <- readRDS(rdsFile)
		
		if(length(names(varData))>1) {
			
			outFile <- paste0(table, "_", strsplit(url,split = "/")[[1]][6], ".nc")
			
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
				hack <- rep(0, nrow(dataTable))
				nc_file <- write_point_dsg(nc_file = outFile, lats = hack, lons = hack, alts = hack, times = as.POSIXct("1970-01-01"), 
																	 data = dataTable[2:ncol(dataTable)], data_units = as.character(hack), 
																	 feature_names = as.character(dataTable[1][[1]]),force_v4 = TRUE)
			}
		} else {
			print("Didn't find data for this dataset.")
		}
		
		step <- step + 1
	}
# }

metadata <- metadata[metadataCols, ]
