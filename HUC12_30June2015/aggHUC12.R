library(maptools)
library(HUCAgg)
library(rgeos)
library(rgdal)

# Set this to where the files are.
workingPath<-'HUC12_30June2015/HUC12_30June2015Agg'

setwd(workingPath)

# Load directly from shapefile
hucPoly<-readShapePoly("../data/WBDHU12.shp",proj4string= CRS('+init=epsg:4269'))

i <- sapply(hucPoly@data, is.factor)
hucPoly@data[i] <- lapply(hucPoly@data[i], as.character)

hucList<-hucPoly@data$HUC

# Or load from an old data export. (faster)
# load('hucPoly.rda')

# Build the fromHUC list
fromHUC<-sapply(as.character(unlist(hucList)),fromHUC_finder,hucs=hucPoly@data$HUC,tohucs=hucPoly@data$TOHUC)

# Or load it from a previous run
# load('fromHUC.rda')

# Generate the aggregate HUC list for everything.
aggrHUCs<-sapply(as.character(unlist(hucList)), HUC_aggregator, fromHUC=fromHUC)

# Or load it from a previous run.
# load('aggrHUCs.rda')

## TESTING One Watershed ##

# huc<-"070700051802" #Wisconsin River
# huc<-"020402040000" #Delaware River
# huc<-"150301070105" #Colorado River
#
# outHuc<-unionHUC(huc,aggrHUCs,hucPoly)
# outShp<-subset(hucPoly,hucPoly@data$HUC %in% huc)
# outShp@polygons[which(outShp@data$HUC %in% huc)][[1]]<-outHuc@polygons[[1]]
# writePolyShape(outShp,file.path(huc))

## TESTING One Watershed ##

## HUC02 03 and 06 ##

# testhucList<-c()
# for(huc in hucPoly@data$HUC) {
#   if(grepl('^0707.*',huc)) {
#     testhucList<-c(testhucList,huc)
#   }
# }

# outHucs<-sapply(unlist(hucList), unionHUC, upstreamHUCs=aggrHUCs, hucPoly=hucPoly)
# outShp<-subset(hucPoly,hucPoly@data$HUC %in% hucList)
# for(huc in outShp@data$HUC){
#   if(!is.null(outHucs[[huc]])){
#     print(huc)
#     outShp@polygons[which(outShp@data$HUC %in% huc)][[1]]<-outHucs[[huc]]@polygons[[1]]
#   }
# }
# writePolyShape(outShp,file.path('0707'))

## TESTING HUC02 03 and 06 ##

## Run whole country ##

# cl <- makeCluster(rep('localhost',2), type = "SOCK")
#
# range<-seq(from = 1, to = length(hucPoly@data$HUC), by=1000)
# ranges<-array(dim=c(length(range),2))
# ranges[,1]<-seq(from = 1, to = length(hucPoly@data$HUC), by=1000)
# ranges[,2]=seq(from = 1, to = length(hucPoly@data$HUC), by=1000)+1000
# ranges[nrow(ranges),2]=length(hucPoly@data$HUC)
#
# out<-parApply(cl, ranges, 1, natRunner, aggrHUCs=aggrHUCs, hucPoly=hucPoly, unionHUC=unionHUC, outPath=workingPath)
#
# stopCluster(cl)

## Run whole country ##

## Walk Down the Network ##
aggrHUCs<-aggrHUCs[hucList]
# hucPoly<-subset(hucPoly,hucPoly@data$HUC %in% hucList)

upstream_size<-sapply(aggrHUCs, length) # The length of the list of upstream hucs.

for ( setSize in 1:max(upstream_size) ) {
  hucs<-names(upstream_size[which(upstream_size==setSize)])
  print(setSize)
  print(paste('length of set is',length(hucs)))
  for ( huc in hucs ) {
    fromHUCs<-unlist(fromHUC[huc][[1]])
    hucListSub<-c(fromHUCs,huc)
    hucPolySub<-subset(hucPoly,hucPoly@data$HUC %in% hucListSub)
    hucPolySub@data$group<-1
    ind<-which(hucPoly@data$HUC %in% huc)
    tryCatch(
    hucPoly@polygons[ind][[1]]<-unionSpatialPolygons(hucPolySub,hucPolySub@data$group)@polygons[[1]],
    warning = function(w) {print(paste("Warning handling", huc, "warning was", w))},
    error = function(e) {print(paste("Error handling", huc, "error was", e))})
    hucPoly@polygons[ind][[1]]@ID<-huc
    hucPoly@data$AREAACRES[ind]<-sum(hucPolySub@data$AREAACRES)
    hucPoly@data$AREASQKM[ind]<-sum(hucPolySub@data$AREASQKM)
  }
}

# save(hucPoly,file='hucPoly_agg.rda')

# load('hucPoly_agg.rda')

hucPoly@data$UPHUCS<-paste(unlist(aggrHUCs[as.character(hucPoly@data$HUC12)]),collapse=',')

# ## Walk Down the Network
#
# range<-seq(from = 1, to = length(hucPoly@data$HUC), by=1000)
# ranges<-array(dim=c(length(range),2))
# ranges[,1]<-seq(from = 1, to = length(hucPoly@data$HUC), by=1000)
# ranges[,2]=seq(from = 1, to = length(hucPoly@data$HUC), by=1000)+1000
# ranges[nrow(ranges),2]=length(hucPoly@data$HUC)
#
# write_shape<-function(range,hucPoly) {
#   subPoly<-subset(hucPoly,hucPoly@data$HUC %in% as.character(hucPoly@data$HUC[range[1]:range[2]]))
#   for (p in 1:length(subPoly@polygons)) {
#     numCoords<-0
#     for (p2 in 1:length(subPoly@polygons[[p]]@Polygons)) {
#       numCoords<-numCoords+length(subPoly@polygons[[p]]@Polygons[[p2]]@coords)
#     }
#     if (numCoords>900000) {
#       print(subPoly@data$HUC12[p])
#       print(numCoords)
#       subPoly2<-subset(subPoly,subPoly@data$HUC %in% as.character(subPoly@data$HUC[p]))
#       subPoly@polygons[[p]]<-gSimplify(subPoly2,0.00005)@polygons[[1]]
#       numCoords<-0
#       for (p2 in 1:length(subPoly@polygons[[p]]@Polygons)) {
#         numCoords<-numCoords+length(subPoly@polygons[[p]]@Polygons[[p2]]@coords)
#       }
#       print(numCoords)
#     }
#   }
#   writePolyShape(subPoly,file.path('./',toString(range[1])))
# }
#
# apply(ranges,1,write_shape,hucPoly)

writeOGR(obj = hucPoly, dsn = 'huc12agg.pgdump', layer = 'huc12agg', driver = 'PGDump', layer_options = c("GEOMETRY_NAME=the_geom"))

system("perl -pi -e 's/OGC_FID/ogc_fid/g' huc12agg.pgdump")
