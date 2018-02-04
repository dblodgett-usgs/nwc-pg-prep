for f in *.pgdump.gz
  do 
  echo $f
  curl -X PUT "https://cidasdpdasartip.cr.usgs.gov:8444/artifactory/nwc-config/pgdump/$f" -T $f --insecure -u dblodgett:PASSWORD
done
