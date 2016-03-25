library(maptools)
library(rgeos)
library(HUCAgg)
library(rgdal)

# Set this to where the files are.
workingPath<-'/Users/dblodgett/Documents/Projects/WaterSmart/5_data/databaseShapefiles/HUC12_30June2015/HUC12_30June2015Agg'

setwd(workingPath)

regions<-list(newEngland=c('01'), midAtlantic=c('02'), southAtlanticGolf=c('03'),
              greatLakes=c('04'),  mississippi=c('05','06','07','08','10','11'),
              sourisRedRainy=c('09'), texasGolf=c('12'), rioGrande=c('13'),
              colorado=c('14','15'), greatBasin=c('16'), pacificNorthwest=c('17'),
              california=c('18'), alaska=c('19'), hawaii=c('20'))

# If the regional data hasn't been created yet, initialize it.
if(!dir.exists('regions')) { # should put this in a function.
  hucPoly<-readShapePoly("../data/WBDHU12.shp",proj4string= CRS('+init=epsg:4269'))
  i <- sapply(hucPoly@data, is.factor); hucPoly@data[i] <- lapply(hucPoly@data[i], as.character)
  dir.create('regions')
  for(region in names(regions)) {
    print(regions[region])
    subhucList<-c()
    for(huc02 in regions[region][[1]]) { 
      for(huc in hucPoly@data$HUC) {
        if(grepl(paste0('^',huc02,'.*'),huc)) { 
          subhucList<-c(subhucList,huc) 
        }
      } 
    }
    subhucPoly<-subset(hucPoly,hucPoly@data$HUC %in% as.character(subhucList))
    save(subhucPoly, file=file.path('regions',paste0(region,'.rda')))
    rm(subhucPoly)
  } 
  rm(hucPoly) 
}

for(region in names(regions)) {
  print(region)
  load(file.path('regions',paste0(region,'.rda')))
  hucList<-subhucPoly@data$HUC
  fromHUC<-sapply(as.character(unlist(hucList)),fromHUC_finder,hucs=subhucPoly@data$HUC,tohucs=subhucPoly@data$TOHUC)
  aggrHUCs<-sapply(as.character(unlist(hucList)), HUC_aggregator, fromHUC=fromHUC)
  upstream_size<-sapply(aggrHUCs, length)
  for ( setSize in 1:max(upstream_size)) {
    hucs<-names(upstream_size[which(upstream_size==setSize)])
    print(setSize)
    print(paste('length of set is',length(hucs)))
    for ( huc in hucs ) {
      fromHUCs<-unlist(fromHUC[huc][[1]])
      hucListSub<-c(fromHUCs,huc)
      subhucPolySub<-subset(subhucPoly,subhucPoly@data$HUC %in% hucListSub)
      subhucPolySub@data$group<-1
      ind<-which(subhucPoly@data$HUC %in% huc)
      tryCatch(
        subhucPoly@polygons[ind][[1]]<-unionSpatialPolygons(subhucPolySub,subhucPolySub@data$group)@polygons[[1]],
        warning = function(w) {print(paste("Warning handling", huc, "warning was", w))},
        error = function(e) {print(paste("Error handling", huc, "error was", e))})
      subhucPoly@polygons[ind][[1]]@ID<-huc
      subhucPoly@data$AREAACRES[ind]<-sum(subhucPolySub@data$AREAACRES)
      subhucPoly@data$AREASQKM[ind]<-sum(subhucPolySub@data$AREASQKM)
    } 
  }
  subhucPoly@data$UPHUCS<-paste(unlist(aggrHUCs[as.character(subhucPoly@data$HUC12)]),collapse=',')
  if (grepl(region,names(regions)[1])) {layer_options = c("GEOMETRY_NAME=the_geom", "CREATE_TABLE=ON", "DROP_TABLE=OFF")} else
  {layer_options = c("GEOMETRY_NAME=the_geom", "CREATE_TABLE=OFF", "DROP_TABLE=OFF")}
  writeOGR(obj = subhucPoly, dsn = paste0(region,'_huc12agg.pgdump'), layer = 'huc12agg', driver = 'PGDump', layer_options = c("GEOMETRY_NAME=the_geom", "CREATE_TABLE=OFF"))
  system(paste0("perl -pi -e 's/OGC_FID/ogc_fid/g' ", region, "_huc12agg.pgdump"))
}
