# Reads in metadata table from Mike W.
# Cleans it up and writes it into a structured format.
# Creates dataList.json for later.

library("sbtools")
library("stringr")
library("jsonlite")

f<-file('NHDPlusv2_Variable_MasterList.txt')
inputText<-readLines(f)
close(f)

cleanText <- function(x) {
  x <- gsub('\x89|\xd5', "'", x, perl = TRUE)
  x <- gsub('\xd0', "-", x, perl = TRUE)
  x <- gsub('\xd2|\xd3', '"', x, perl = TRUE)
  x <- gsub('\xca', ' ', x, perl = TRUE)
  x <- iconv(x, "UTF-8", "ASCII", sub="")
}

themeURLs<-list(
  "Chemical"="https://www.sciencebase.gov/catalog/item/56fd600fe4b022712b81bf9a",
  "Climate"="https://www.sciencebase.gov/catalog/item/566ef828e4b09cfe53ca76f7",
  "Climate and Water Balance Model" = "https://www.sciencebase.gov/catalog/item/566f6c76e4b09cfe53ca77fe",
  "Geology" = "https://www.sciencebase.gov/catalog/item/5703c816e4b0328dcb82295a",
  "Hydro Mod" = "https://www.sciencebase.gov/catalog/item/570670f2e4b03f95a075aacd",
  "Hydrologic" = "https://www.sciencebase.gov/catalog/item/5669a8a4e4b08895842a1d4c",
  "Landscape" = "https://www.sciencebase.gov/catalog/item/5669a834e4b08895842a1d49",
  "Population Infrastructure" = "https://www.sciencebase.gov/catalog/item/57067106e4b03f95a075aacf",
  "Regions" = "https://www.sciencebase.gov/catalog/item/5785585ee4b0e02680bf2fd6",
  "Soils" = "https://www.sciencebase.gov/catalog/item/568d6554e4b0e7a44bc207f7",
  "Topographic Characteristics" = "https://www.sciencebase.gov/catalog/item/5789408ee4b0c1aacab7770b")

inputText<-cleanText(inputText)

meta <- read.delim(text = inputText, sep = "\t", stringsAsFactors = FALSE)

dataList<-list()
for(i in 1:nrow(meta)){
  item<-meta[i,]
  if(nchar(item$Theme)>0) {theme<-item$Theme}
  if(nchar(item$DESCRIPTION)>0) {title<-item$DESCRIPTION}
  if(grepl("http", item$`Science.Base.Link`)) {
    
    if(grepl("TOTalog", item$`Science.Base.Link`)) {
      item$`Science.Base.Link` <- stringr::str_replace(item$`Science.Base.Link`, "TOTalog", "catalog")
    }
    if(grepl("ACCalog", item$`Science.Base.Link`)) {
      item$`Science.Base.Link` <- stringr::str_replace(item$`Science.Base.Link`, "ACCalog", "catalog")
    }
    
    sciBu<-item$`Science.Base.Link`
    sb_id<-str_split(sciBu,"/")[[1]][6]}
  
  if(!sciBu %in% names(dataList)){
    item_files <- NA
    try(item_files<-item_list_files(sb_id)$fname)
    if(!all(is.na(item_files))){
      dataList[[sciBu]] <- list()
      dataList[[sciBu]][["files"]]<-item_files
      if(!length(item_files)>0) {
        children<-item_list_children(sb_id)
        dataList[[sciBu]][["files"]]<-c()
        for(child in children) {
          item_files<-item_list_files(child$id)$fname
          dataList[[sciBu]][["files"]]<-c(dataList[[sciBu]][["files"]],item_files)
        }
      }
    }
    dataList[[sciBu]][["vars"]]<-list(description=c(),
                                      localCatch_name=c(),
                                      divRoute_name=c(),
                                      totRoute_name=c(),
                                      units=c())
  }
  dataList[[sciBu]][["theme"]]<-theme
  dataList[[sciBu]][["themeURL"]]<-themeURLs[[theme]]
  dataList[[sciBu]][["title"]]<-title
  dataList[[sciBu]][["vars"]][["description"]]<-c(dataList[[sciBu]][["vars"]][["description"]],
                                                  item$DESCRIPTION)
  dataList[[sciBu]][["vars"]][["localCatch_name"]]<-c(dataList[[sciBu]][["vars"]][["localCatch_name"]],
                                                      item$`Catchment.Item.Name`)
  dataList[[sciBu]][["vars"]][["divRoute_name"]]<-c(dataList[[sciBu]][["vars"]][["divRoute_name"]],
                                                    item$`Divergence.Item.Name`)
  dataList[[sciBu]][["vars"]][["totRoute_name"]]<-c(dataList[[sciBu]][["vars"]][["totRoute_name"]],
                                                    item$`Total.Upstream.Item Name`)
  dataList[[sciBu]][["vars"]][["units"]]<-c(dataList[[sciBu]][["vars"]][["units"]],
                                            item$UNITS)
}

sink('dataList.json')
cat(toJSON(dataList))
sink()

# sink('datatext.txt')
# str(dataList)
# sink()