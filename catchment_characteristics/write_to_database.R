library(jsonlite)
library(dplyr)
library(RPostgreSQL)
# Assumes working directory has data_cleanup and dump_files directories.
# This was used to populate tables for development. The approach does not scale well and was abandoned.

metadata<-fromJSON("data_cleanup//metadata.json")
names(metadata) <- c("characteristic_id", "characteristic_description", "units", "dataset_label",
                     "dataset_url", "theme_label", "theme_url", "characteristic_type")

drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "nldi",
                 host = "localhost", port = 5432,
                 user = "dblodgett")
df_postgres <- dbGetQuery(con, 'DROP TABLE characteristic_data.characteristic_metadata;')
df_postgres <- dbGetQuery(con, 'CREATE TABLE characteristic_data.characteristic_metadata
(
characteristic_id text NOT NULL,
characteristic_description text,
units text,
dataset_label text,
dataset_url text,
theme_label text,
theme_url text,
characteristic_type text,
CONSTRAINT characteristic_metadata_pkey PRIMARY KEY (characteristic_id)
)
WITH (
  OIDS=TRUE
);
ALTER TABLE characteristic_data.characteristic_metadata
OWNER TO nldi;')

datasets<-list()
extensions<-c("_acc.rds", "_tot.rds", "_cat.rds")
tables<-c("divergence_routed_characteristics", 
          "total_accumulated_characteristics", 
          "local_catchment_characteristics")
varsForTesting <- c("_N97", "P97", "PEST219",# chemical
                    "ET", "PRSNOW", "TAV7100_ANN", "WDANN", "PPT7100_ANN", "SENAY_AET", #Climate
                    "OLSON_PERM", "OLSON_UCS", # geology
                    "NDAMS_1930", "NID_STORAGE_1930",  "NDAMS_2013", "NID_STORAGE_2013", # hydro mode
                    "RECHG", "WB5100_ANN", "RUN7100", #  hydrologic
                    "IMPV01", "IMPV11", "CDL12_1", "NWALT02_25", "NWALT02_26", # landscape
                    "POPDENS00", "POPDENS10", "TOTAL_ROAD_DENS", # Population Infrastructure
                    "ECOL3_3", "ECOL3_15", "ECOL3_27", "ECOL3_69", #regions
                    "PERMAVE", "WTDEP", "BASIN_SLOPE", "BASIN_AREA", "STREAM_SLOPE") # soils

# varsForTesting <- c("_N97",# chemical
#                     "ET", 
#                     "POPDENS00", # Population Infrastructure
#                     "ECOL3_3", #regions
#                     "PERMAVE") # soils
varsForTestingregex <- paste(varsForTesting,collapse = "$|_")

metadataCols<-c()

for(dataType in 1:3) {
  table<-tables[dataType]
  extension<-extensions[dataType]
  dbGetQuery(con, paste0('DROP TABLE characteristic_data.',table, ';'))
  dbGetQuery(con, paste0('CREATE TABLE characteristic_data.',table, '
                       (
                          comid integer NOT NULL,
                          characteristic_id text NOT NULL,
                          characteristic_value numeric,
                          percent_nodata smallint,
                          CONSTRAINT ', table, '_pkey PRIMARY KEY (comid, characteristic_id)
                       )
                       WITH (
                           OIDS=TRUE
                       );
                       ALTER TABLE characteristic_data.', table,
                         ' OWNER TO nldi;'))
  for(urlID in 1:length(unique(metadata$dataset_url))) {
    url <- unique(metadata$dataset_url)[urlID]
    rdsFile<-paste0("data_cleanup/rds/broken_out/",strsplit(url,split = "/")[[1]][6],extension)
    varsFromURL<-metadata$characteristic_id[which(metadata$dataset_url == url)]
    if(any(grepl(varsForTestingregex,varsFromURL))) {
      varData<-readRDS(rdsFile)
      if(length(names(varData))>1) {
        for(column in 2:length(names(varData))) {
          colName <- names(varData)[column]
          if(!grepl("NODATA", colName) && grepl(varsForTestingregex, colName)) {
            if(!grepl("NODATA", colName)) {
            print(metadata$dataset_label[min(which(metadata$dataset_url %in% url))])
            print(colName)
            dataTable <- data.frame(varData$COMID)
            names(dataTable) <-c("comid")
            dataTable["characteristic_id"] <- 
              metadata$characteristic_id[which(metadata$characteristic_id %in% names(varData)[column][[1]])]
            metadataCols <- 
              c(metadataCols, which(metadata$characteristic_id %in% names(varData)[column][[1]]))
            dataTable["val"] <- varData[column]
            dataTable["val"][dataTable["val"] == -9999] <- NA
            if(any(grepl("NODATA", names(varData)))) {
              dataTable["nodatap"] <- as.integer(varData[which(grepl("NODATA", names(varData)))][[1]])
            } else {
              dataTable["nodatap"] <- 0
            }
            dataTable["nodatap"][dataTable["nodatap"] == 200080] <- 100 # some nodata values were way big.
            dbWriteTable(con, c("characteristic_data",table),
                         value = dataTable, row.names = FALSE, append = TRUE)
          }
        }
        }
      } else {
        print("Didn't find data for this dataset.")
      }
    }
  }
}

metadata <- metadata[metadataCols, ]

dbWriteTable(con, c("characteristic_data","characteristic_metadata"),
             value = metadata, row.names = FALSE, append = TRUE)

dbDisconnect(con)
