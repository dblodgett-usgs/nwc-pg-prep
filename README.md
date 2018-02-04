# NWC Data Platform Data Preparation Scripts and Data

Unless Otherwise Noted:  
**This information is preliminary and is subject to revision. It is being provided to meet 
the need for timely best science. The information is provided on the condition that neither 
the U.S. Geological Survey nor the U.S. Government shall be held liable for any damages resulting 
from the authorized or unauthorized use of this information.**

These data feed a geoserver infrastructure available here: https://cida.usgs.gov/nwc/geoserver/web/

Every effort has been made to automate creation of .pgdump files using the scrip ogr2ogr\_local.sh  

This repository contains source data and assumes access to a locally running PostGres database and 
an R environment with packages to support the national\_runner.R script.