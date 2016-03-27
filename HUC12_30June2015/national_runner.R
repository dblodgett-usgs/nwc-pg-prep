library(maptools)
library(rgeos)
library(HUCAgg)
library(rgdal)

# Set this to where the files are.
workingPath<-'databaseShapefiles/HUC12_30June2015/HUC12_30June2015Agg/'

setwd(workingPath)

init_regions<-function(WBDPath,regionsPath) {
  regions<-list(newEngland=c('01'), midAtlantic=c('02'), southAtlanticGolf=c('03'),
                greatLakes=c('04'),  mississippi=c('05','06','07','10','11','08'),
                sourisRedRainy=c('09'), texasGolf=c('12'), rioGrande=c('13'),
                colorado=c('14','15'), greatBasin=c('16'), 
                pacificNorthwest=c('1701','1702','1703','1704','1705','1706',
                                   '1707','1709','1710','1711','1712','1708'),
                california=c('18'), alaska=c('1901','1902','1903','1904','1905','1906'), hawaii=c('20'))
  if(!dir.exists(regionsPath)) {
    hucPoly<-readShapePoly(WBDPath,proj4string= CRS('+init=epsg:4269'))
    i <- sapply(hucPoly@data, is.factor); hucPoly@data[i] <- lapply(hucPoly@data[i], as.character)
    dir.create(regionsPath)
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
    }
  }
  return(regions)
}

WBDPath<-"../data/WBDHU12.shp"
regionsPath<-"regions"

regions<-init_regions(WBDPath, regionsPath)

for(region in names(regions[1:length(names(regions))])) {
  print(region)
  load(file.path('regions',paste0(region,'.rda')))
  for(subRegion in regions[region][[1]]) { # Mysterious errors occur when the scale is above a region at a time.
    print(paste('aggregating hucs for',subRegion))
    hucList<-c()
    for(huc in subhucPoly@data$HUC12) {
      if(grepl(paste0('^',subRegion,'.*'),huc)) {
        hucList<-c(hucList,huc)
      }
    }
    fromHUC<-sapply(as.character(unlist(hucList)),fromHUC_finder,hucs=subhucPoly@data$HUC12,tohucs=subhucPoly@data$TOHUC)
    aggrHUCs<-sapply(as.character(unlist(hucList)), HUC_aggregator, fromHUC=fromHUC)
    upstream_size<-sapply(aggrHUCs, length)
    for ( setSize in 1:max(upstream_size)) {
      hucs<-names(upstream_size[which(upstream_size==setSize)])
      for ( huc in hucs ) {
        fromHUCs<-c(unlist(fromHUC[huc][[1]]),huc)
        if(length(fromHUCs)>50) {print(paste(huc,'has',length(fromHUCs),'contributing hucs'))}
        for (ihuc in 2:length(fromHUCs)) { # I found that it is much faster to combine two iteratively rather than a ton in one block.
          hucListSub<-c(fromHUCs[ihuc-1],fromHUCs[ihuc])
          subhucPolySub<-subset(subhucPoly,subhucPoly@data$HUC12 %in% hucListSub)
          subhucPolySub@data$group<-1
          ind<-which(subhucPoly@data$HUC12 %in% huc)
          tryCatch(
            subhucPoly@polygons[ind][[1]]<-unionSpatialPolygons(subhucPolySub,subhucPolySub@data$group)@polygons[[1]],
            warning = function(w) {print(paste("Warning handling", huc, "warning was", w))},
            error = function(e) {print(paste("Error handling", huc, "error was", e))})
        }
        subhucPoly@polygons[ind][[1]]@ID<-huc
        subhucPoly@data$AREAACRES[ind]<-sum(subhucPolySub@data$AREAACRES)
        subhucPoly@data$AREASQKM[ind]<-sum(subhucPolySub@data$AREASQKM)
      }
    }
    print('simplifying hucs')
    for (p in 1:length(subhucPoly@polygons)) {
      numCoords<-0
      for (p2 in 1:length(subhucPoly@polygons[[p]]@Polygons)) {
        numCoords<-numCoords+length(subhucPoly@polygons[[p]]@Polygons[[p2]]@coords)
      }
      if (numCoords>50000) {
        subhucPolySub<-subset(subhucPoly,subhucPoly@data$HUC %in% as.character(subhucPoly@data$HUC[p]))
        tryCatch(
          subhucPoly@polygons[[p]]<-gSimplify(subhucPolySub,0.00005,topologyPreserve=TRUE)@polygons[[1]],
          warning = function(w) {print(paste("Warning simplifying", huc, "warning was", w))},
          error = function(e) {print(paste("Error simplifying", huc, "error was", e))})
      }
    }
  }
  subhucPoly@data$UPHUCS<-paste(unlist(aggrHUCs[as.character(subhucPoly@data$HUC12)]),collapse=',')
  print('writing output')
  if (grepl(region,names(regions)[1])) {layer_options = c("GEOMETRY_NAME=the_geom", "CREATE_TABLE=ON", "DROP_TABLE=OFF")} else
  {layer_options = c("GEOMETRY_NAME=the_geom", "CREATE_TABLE=OFF", "DROP_TABLE=OFF")}
  writeOGR(obj = subhucPoly, dsn = paste0(region,'_huc12agg.pgdump'), layer = 'huc12agg', driver = 'PGDump', layer_options = layer_options)
  system(paste0("perl -pi -e 's/OGC_FID/ogc_fid/g' ", region, "_huc12agg.pgdump"))
  system(paste0("gzip ", region, "_huc12agg.pgdump"))
}