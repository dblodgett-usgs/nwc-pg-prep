# A script that parses and verifies some aspects of the NHDPlus V2 metadata for: 
# https://www.sciencebase.gov/catalog/item/5669a79ee4b08895842a1d47
# Reads dataList.json from 02_metadata_cleanup.R
# First tries to make sense of all the file naming patterns and what they are.
# Then unzips and reads in all the data saves it in buld to rds files for later.

library("jsonlite")
library("data.table")
library("sbtools")
setwd('~/temp')
f<-file('dataList.json')
dataList<-fromJSON(readLines(f))
close(f)
rm(f)
verified_items_files<-c()
items_files<-list()
for(item in names(dataList)) {
  # There are some variables that don't have accumulated data.
  if(any(grepl('N/A',dataList[item][[1]]$vars$divRoute_name))) {
    cat(paste('Missing accumulated Vars in',
              dataList[item][[1]]$title,
              'missing variable is',
              dataList[item][[1]]$vars$localCatch_name[which(grepl('N/A',dataList[item][[1]]$vars$divRoute_name))],
              '\n'))
  }
  # There are some items that have more than one file.
  if(length(dataList[item][[1]]$files)>1) {
    # Case 1 where ACC, CAT, and TOT are broken out.
    if(length(dataList[item][[1]]$files)==3 &&
       any(grepl('_CAT_',dataList[item][[1]]$files)) && 
       any(grepl('_ACC_',dataList[item][[1]]$files)) && 
       any(grepl('_TOT_',dataList[item][[1]]$files))) {
      verified_items_files<-c(verified_items_files,item)
      items_files[[item]]<-dataList[item][[1]]$files
    } else if(length(dataList[item][[1]]$files)==4 && # Case 1a where ACC, CAT, TOT, and DOM are broken out.
              any(grepl('_CAT_',dataList[item][[1]]$files)) && 
              any(grepl('_ACC_',dataList[item][[1]]$files)) && 
              any(grepl('_TOT_',dataList[item][[1]]$files)) &&
              any(grepl('_DOM_',dataList[item][[1]]$files))) {
      verified_items_files<-c(verified_items_files,item)
      items_files[[item]]<-dataList[item][[1]]$files
    } else if(all(grepl('[1-2][0-9][0-9][0-9]',dataList[item][[1]]$files))) { # Case 2 where data are available for multiple years.
      verified_items_files<-c(verified_items_files,item)
    } else if(any(grepl('BFI.JPG',dataList[item][[1]]$files))) {  # Case 6 where there is a jpg file in the BFI dataset.
      verified_items_files<-c(verified_items_files,item)
      items_files[[item]]<-'BFI_CONUS.zip'
    } else if(any(grepl('xml',dataList[item][[1]]$files)))  # Case 3 where there is an xml record in the item.
    {
      verified_items_files<-c(verified_items_files,item)
      items_files[[item]]<-dataList[item][[1]]$files[which(!grepl('xml',dataList[item][[1]]$files))]
    } else if(any(grepl('_JFM_',dataList[item][[1]]$files)) && # Case 4 where the data are broken accross seasons.
              any(grepl('_AMJ_',dataList[item][[1]]$files)) && 
              any(grepl('_JAS_',dataList[item][[1]]$files))) {
      verified_items_files<-c(verified_items_files,item)
      items_files[[item]]<-dataList[item][[1]]$files
    } else if(any(grepl('AET_CONUS.zip',dataList[item][[1]]$files))) {  # Case 5 where there is a zipped tiff file from Senay et. al.
      verified_items_files<-c(verified_items_files,item)
      items_files[[item]]<-'SENAY_AET_CONUS.zip'
    }
  } else if(length(dataList[item][[1]]$files)==1) {
    # Base Case
    verified_items_files<-c(verified_items_files,item)
    items_files[[item]]<-dataList[item][[1]]$files
  }
}

missing<-which(!names(dataList) %in% verified_items_files)
for(i in missing) {
  cat(paste('File name patterns not found or understood for'), dataList[[i]]$title, 'with files', dataList[[i]]$files)
}

for(item in names(items_files)) {
  if(!file.exists(paste0(str_replace(item,"https://www.sciencebase.gov/catalog/item/",""),".rds")) && !identical(items_files[[item]], character(0))) {
    print(items_files[[item]])
    if(any(!file.exists(items_files[[item]]))) {
      try(item_file_download(str_replace(item,"https://www.sciencebase.gov/catalog/item/",""), dest_dir = './', overwrite_file = TRUE))
    }
    for(unzipFile in items_files[[item]]) {
      unzip(unzipFile,overwrite = FALSE)
      if(file.exists(str_replace(unzipFile,'.zip','.TXT'))) {
        file.rename(str_replace(unzipFile,'.zip','.TXT'), str_replace(unzipFile,'.zip','.txt'))
      }
    }
    tempData<-fread(str_replace(items_files[[item]][1],'.zip','.txt'),stringsAsFactors = FALSE)
    file.remove(str_replace(items_files[[item]][1],'.zip','.txt'))
    if (length(items_files[[item]])>1) {
      for(f in 2:length(items_files[[item]])) {
        tempData<-merge(tempData,fread(str_replace(items_files[[item]][f],'.zip','.txt'),stringsAsFactors = FALSE),by="COMID")
        file.remove(str_replace(items_files[[item]][f],'.zip','.txt'))
      }
    }
    saveRDS(object=tempData,file = paste0(str_replace(item,"https://www.sciencebase.gov/catalog/item/",""),".rds"))
  }
}