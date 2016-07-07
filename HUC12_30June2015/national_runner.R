library(HUCAgg)
library(rgdal)
library(maptools)

# Set this to where the files are.
workingPath<-'~/Documents/Projects/WaterSmart/5_data/databaseShapefiles/HUC12_30June2015/HUC12_30June2015Agg/'

setwd(workingPath)

WBDPath<-"../data/WBDHU12.shp"
regionsPath<-"regions"

regions<-init_regions(WBDPath, regionsPath)

for(region in names(regions)) {
  print(region)
  load(file.path('regions',paste0(region,'.rda')))
  subhucPoly@data$UPHUCS<-""
  for(subRegion in regions[region][[1]]) { # Mysterious errors occur when the scale is above a region at a time.
    print(paste('aggregating hucs for',subRegion))
    hucList<-getHUCList(subRegion,subhucPoly)
    fromHUC<-sapply(as.character(unlist(hucList)),fromHUC_finder,hucs=subhucPoly@data$HUC12,tohucs=subhucPoly@data$TOHUC)
    aggrHUCs<-sapply(as.character(unlist(hucList)), HUC_aggregator, fromHUC=fromHUC)
    subhucPoly<-unionHUCSet(aggrHUCs, fromHUC, subhucPoly)
    print('simplifying hucs')
    subhucPoly<-simplifyHucs(subhucPoly, simpTol = 1e-04)
    for(huc in names(aggrHUCs)) {
      hucInd<-which(subhucPoly@data$HUC12 %in% huc)
      subhucPoly@data$UPHUCS[hucInd]<-paste(unlist(aggrHUCs[as.character(subhucPoly@data$HUC12[hucInd])]),collapse=',')
    }
  }
  print('writing output')
  tryCatch(
    subhucPoly<-spChFIDs(subhucPoly,subhucPoly@data$HUC12),
    warning = function(w) {print(paste("Warning handling", region, "warning was", w))},
    error = function(e) {print(paste("Error handling", region, "error was", e, "trying to fix"))
      remove<-c()
      for( ind in which(duplicated(subhucPoly@data$HUC12))) { # This is horrible, but it does combine duplicated entries.
        subhucPolySub<-subset(subhucPoly,subhucPoly@data$HUC12 %in% subhucPoly@data$HUC12[ind])
        subhucPolySub@data$group<-1
        subhucPolySub<-spChFIDs(subhucPolySub,as.character(seq(length(subhucPolySub@data$TNMID))))
        subhucPoly@polygons[ind][[1]]<-unionSpatialPolygons(subhucPolySub,subhucPolySub@data$group)@polygons[[1]]
        remover<-which(subhucPoly@data$HUC12 %in% subhucPoly@data$HUC12[ind])
        remove<-c(remove,remover[!remover %in% ind])
      }
      subhucPoly<-subhucPoly[-remove,]
      subhucPoly<-spChFIDs(subhucPoly,subhucPoly@data$HUC12)
    })
  print('writing output pgdump')
  layer_options = c("GEOMETRY_NAME=the_geom", "CREATE_TABLE=ON", "DROP_TABLE=OFF")
  writeOGR(obj = subhucPoly, dsn = paste0(region,'_huc12agg.pgdump'), 
           layer = paste0(region,'_huc12agg'), driver = 'PGDump', layer_options = layer_options)
  system(paste0("perl -pi -e 's/OGC_FID/ogc_fid/g' ", region, "_huc12agg.pgdump"))
  system(paste0("gzip ", region, "_huc12agg.pgdump"))
}