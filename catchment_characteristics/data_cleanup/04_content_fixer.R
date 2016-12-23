# Reads in dataList.json from 02_metadata_cleanup.R.
# Reads in rds files named as ScienceBase IDs
# Works through a ton of gotchas about column naming in the dataset
# Saves rds files per data type (watershed type) for each dataset (sb ID)

library("jsonlite")
library("tidyr")
library("stringr")
library("data.table")
setwd('~/temp')
f<-file('dataList.json')
dataList<-fromJSON(readLines(f))
close(f)
rm(f)
setwd('~/temp/rds/')
metadata_table<-data.frame(ID=character(0), description=character(0),
                           units=character(0), datasetLabel=character(0),
                           datasteURL=character(0), themeLabel=character(0),
                           themeURL=character(0), watershedType=character(0),
                           stringsAsFactors = FALSE)
## Had to add the 0 row for CDL data
## Had to add the AC soils row to the SURRGO soil class metadata
## Hard to add a row for ECO3 DOM (TOT) only variables.
## had to change some ACC colNames in the TOT column.
## duplicate row for ACC_ECOL3_24
for(rdsFile in list.files(pattern = '*.rds')) {
  sbID<-str_replace(rdsFile,'.rds','')
  if(!file.exists(paste0("broken_out/", sbID, "_tot.rds"))) {
    sbURL<-paste0("https://www.sciencebase.gov/catalog/item/", sbID)
    if(!is.null(dataList[[sbURL]])) {
      print(dataList[[sbURL]]$title)
      dataTable<-readRDS(rdsFile)
      if(grepl("Dams Built Before", dataList[[sbURL]]$title)) { # Used to make years unique in metadata, could fix by updating all ids.
        for(j in 1:length(dataList[[sbURL]]$vars$localCatch_name)) {
          year<-tail(str_split(dataList[[sbURL]]$title," ")[[1]],n=1)
          dataList[[sbURL]]$vars$localCatch_name[j]<-paste(dataList[[sbURL]]$vars$localCatch_name[j],year,sep="_")
          dataList[[sbURL]]$vars$divRoute_name[j]<-paste(dataList[[sbURL]]$vars$divRoute_name[j],year,sep="_")
          dataList[[sbURL]]$vars$totRoute_name[j]<-paste(dataList[[sbURL]]$vars$totRoute_name[j],year,sep="_")
        }
      }
      for(i in 1:length(names(dataTable))) {
        colName<-names(dataTable)[i]
        if(grepl("COMID",colName)) { #select COMID collumn to be included once.
          idCol<-colName
          colSelector<-list(localCatch_name="COMID", divRoute_name="COMID", totRoute_name="COMID")
        } else {
          if(grepl("Dams Built Before", dataList[[sbURL]]$title)) { # Used to make colNames unique. See similar rename for metadata above.
            year<-tail(str_split(dataList[[sbURL]]$title," ")[[1]],n=1)
            colName<-paste(colName,year,sep="_")
            names(dataTable)[i]<-colName
          }
          if(grepl("BUSHREED", colName) && !grepl("BUSHREED_",colName)) { # rename so colNames match metadata.
            colName<-str_replace(colName, "BUSHREED", "BUSHREED_")
            names(dataTable)[i]<-colName
          }
          if(grepl("IMPV11", colName) && grepl("Buffer",dataList[[sbURL]]$title)) { # rename so colNames match metadata.
            colName<-str_replace(colName, "IMPV11", "IMPV11_BUFF100")
            names(dataTable)[i]<-colName
          }
          if(grepl("_WD", colName) && grepl("Monthly Mean Number of Days Measurable Precipitation",dataList[[sbURL]]$title)) { # rename so colNames match metadata.
            colName<-str_replace(colName, "_WD", "_WD6190_")
            names(dataTable)[i]<-colName
          }
          if(grepl("_AET", colName) && grepl("Average Annual Actual Evapotranspiration",dataList[[sbURL]]$title)) { # rename so colNames match metadata.
            colName<-str_replace(colName, "_AET", "_SENAY_AET")
            names(dataTable)[i]<-colName
          }
          if(grepl("Water balance model output 2000-2014",  dataList[[sbURL]]$title)) { # rename so colNames match metadata.
            colName<-paste0(colName,"_2012")
            names(dataTable)[i]<-colName
          }
          if(grepl("\\bCAT_", colName)) { # Set watershedType and determine uniqueName to be added to non-unique NODATA.
            watershedType<-"localCatch_name"
            if(!grepl("NODATA",colName)) uniqueName<-str_replace(colName,'\\bCAT_','')
          } else if(grepl("\\bACC_", colName)) {
            watershedType<-"divRoute_name"
            if(!grepl("NODATA",colName)) uniqueName<-str_replace(colName,'\\bACC_','')
          } else if(grepl("\\bTOT_", colName)) {
            watershedType<-"totRoute_name"
            if(!grepl("NODATA",colName)) uniqueName<-str_replace(colName,'\\bTOT_','')
          } else if(grepl("NODATA", colName)) { # Some CAT NODATA is just plain 'NODATA' - this makes it unique.
            print("found lone NODATA")
            colName<-paste0("CAT_",colName)
            names(dataTable)[i]<-colName
            watershedType<-"localCatch_name"
          } else if(grepl("sinuosity", colName) || # Add CAT to variables that should be in that set.
                    grepl("LENGTH_KM", colName) || 
                    grepl("AREA_SQKM", colName) || 
                    grepl("STRM_DENS", colName)) {
            colName<-paste0("CAT_", colName)
            names(dataTable)[i]<-colName
          } else if(grepl("ECO3_BAS_PCT", colName) || 
                    grepl("ECO3_BAS_DOM", colName) || 
                    grepl("MAX", colName) || 
                    grepl("MAJORITY", colName)) { # Add TOT to variables that should be in that set.
            colName<-paste0("TOT_", colName)
            names(dataTable)[i]<-colName
          } else { # If none of the previous were used, stop and look around.
            print("Col Name Not Used")
            print(colName)
            stop()
          }
          if(!grepl(uniqueName, colName) && grepl("NODATA", colName)) { # Some NODATA collumns don't have the unique name, add it here.
            print(paste("found non-unique name, assume NODATA, CHECK!! was", colName))
            colName<-str_replace(colName,"NODATA",paste0(uniqueName,"_NODATA"))
            names(dataTable)[i]<-colName
            print(paste("Is now:",colName))
          }
          if(!grepl("NODATA", colName)) { # Skips NODATA
            varInd<-which(dataList[[sbURL]]$vars[[watershedType]] %in% colName)[1] # Removes any duplicate metadata rows with [1]
            newRow<-as.list(c(colName,dataList[[sbURL]]$vars$description[varInd], dataList[[sbURL]]$vars$units[varInd], 
                              dataList[[sbURL]]$title, sbURL, dataList[[sbURL]]$theme, dataList[[sbURL]]$themeURL, watershedType))
            metadata_table<-rbindlist(list(metadata_table,newRow))
          }
          colSelector[[watershedType]]<-c(colSelector[[watershedType]],colName)
        }
      }
      saveRDS(dataTable[,colSelector[["localCatch_name"]], with=FALSE],file = paste0("broken_out/", sbID, "_cat.rds"))
      saveRDS(dataTable[,colSelector[["divRoute_name"]], with=FALSE],file = paste0("broken_out/", sbID, "_acc.rds"))
      saveRDS(dataTable[,colSelector[["totRoute_name"]], with=FALSE],file = paste0("broken_out/", sbID, "_tot.rds"))
    } else {
      print(paste("Missing", sbURL))
    }
  }
}

write.csv(metadata_table, "metadata_table.csv")