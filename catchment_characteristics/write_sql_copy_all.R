library(jsonlite)
library(dplyr)
library(RPostgreSQL)
library(data.table)
# Assumes working directory has data_cleanup and dump_files directories.

metadata<-fromJSON("data_cleanup/metadata.json")

metadata_outfile <- "dump_files/characteristic_data.characteristic_metadata.pgdump"

names(metadata) <- c("characteristic_id", "characteristic_description", "units", "dataset_label",
                     "dataset_url", "theme_label", "theme_url", "characteristic_type")

datasets<-list()

extensions<-c("_acc", "_tot", "_cat")

tables<-c("divergence_routed_characteristics", 
          "total_accumulated_characteristics", 
          "local_catchment_characteristics")

# These were just pulled from a standard pg_dump output file naively.
header_sql <- "SET statement_timeout = 0;\r\nSET lock_timeout = 0;\r\nSET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';\r\nSET standard_conforming_strings = on;\r\nSET check_function_bodies = false;
SET client_min_messages = warning;\r\nSET row_security = off;\r\nSET search_path = characteristic_data, pg_catalog;
SET default_tablespace = '';\r\nSET default_with_oids = true;\r\n\r\n"

metadataCols<-c()

total_steps <- 3*length(unique(metadata$dataset_url))

step <- 1

for(dataType in 1:3) {
  
  table<-tables[dataType]
  
  extension<-extensions[dataType]
  
  for(urlID in 1:length(unique(metadata$dataset_url))) {
    
    url <- unique(metadata$dataset_url)[urlID]
    
    rdsFile <- paste0("data_cleanup/rds/broken_out/",strsplit(url,split = "/")[[1]][6],extension,".rds")
    
    varsFromURL <- metadata$characteristic_id[which(metadata$dataset_url == url)]
    
    varData <- readRDS(rdsFile)
    
    if(length(names(varData))>1) {
      for(column in 2:length(names(varData))) {
        
        colName <- names(varData)[column]
        
        if(!grepl("NODATA", colName)) {
          
          outFile <- paste0("dump_files/",table, "_", strsplit(url,split = "/")[[1]][6],extension, "_", colName, ".pgdump")
          
          if(!file.exists(paste0(outFile,".gz"))) {
            
            cat(header_sql, file = outFile)
            
            cat(paste0("COPY ", table, " (comid, characteristic_id, characteristic_value, percent_nodata) FROM stdin;\r\n"),
                file = outFile, append = TRUE)
            
            print(paste("Step ", step, "of", total_steps))
            
            dataTable <- data.frame(varData$COMID)
            
            names(dataTable) <-c("comid")
            
            dataTable["characteristic_id"] <- 
              metadata$characteristic_id[which(metadata$characteristic_id %in% names(varData)[column][[1]])]
            
            metadataCols <- 
              c(metadataCols, which(metadata$characteristic_id %in% names(varData)[column][[1]]))
            
            dataTable["val"] <- subset(varData,select = names(varData)[column])
            
            dataTable["val"][dataTable["val"] == -9999] <- NA
            
            if(any(grepl("NODATA", names(varData)))) {
              
              dataTable["nodatap"] <- as.integer(subset(varData, 
                                                        select = names(varData)[which(grepl("NODATA", names(varData)))])[[1]])
              
            } else {
              
              dataTable["nodatap"] <- 0
              
            }
            
            dataTable["nodatap"][dataTable["nodatap"] > 100] <- 100 # some nodata values were way big.
            
            fwrite(dataTable, file = outFile, append = TRUE, sep = "\t", col.names = FALSE, na = '\\N', eol = "\r\n")
            
            cat(paste0("\\.\r\n"),
                file = outFile, append = TRUE)
            
            system(paste0("gzip ", outFile)) 
          }
        }
      }
    } else {
      print("Didn't find data for this dataset.")
    }
    
    step <- step + 1
  }
}

metadata <- metadata[metadataCols, ]

cat(header_sql, file = metadata_outfile)

cat(paste0("COPY characteristic_data.characteristic_metadata (characteristic_id, characteristic_description, units, dataset_label, dataset_url, theme_label, theme_url, characteristic_type) FROM stdin;\r\n"),
    file = metadata_outfile, append = TRUE)

fwrite(metadata, file = metadata_outfile, append = TRUE, sep = "\t", col.names = FALSE, na = 'unknown')

cat(paste0("\\.\r\n"),
    file = metadata_outfile, append = TRUE)

system(paste0("gzip ", metadata_outfile)) 
