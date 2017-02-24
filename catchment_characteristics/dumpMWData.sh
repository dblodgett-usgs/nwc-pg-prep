 username=$1
 password=$2
 check=$3

 if [ -z "$username" ]; then
      echo "You must pass in two variables, admin username, password."
      exit
 fi

 if [ -n "$check" ]; then
     echo "You must pass in two variables, admin username, password."
     exit
 fi

 pg_dump -Fc -t characteristic_data.characteristic_metadata postgresql://$username:$password@localhost/nldi -O --file="characteristic_data.characteristic_metadata.pgdump"
 pg_dump -Fc -t characteristic_data.divergence_routed_characteristics postgresql://$username:$password@localhost/nldi -O --file="characteristic_data.divergence_routed_characteristics.pgdump"
 pg_dump -Fc -t characteristic_data.total_accumulated_characteristics postgresql://$username:$password@localhost/nldi -O --file="characteristic_data.total_accumulated_characteristics.pgdump"
 pg_dump -Fc -t characteristic_data.local_catchment_characteristics postgresql://$username:$password@localhost/nldi -O --file="characteristic_data.local_catchment_characteristics.pgdump"
#
for file in *.pgdump; do gzip $file; done;

# curl -u dblodgett --insecure -X PUT "https://cidasdpdasartip.cr.usgs.gov:8444/artifactory/nldi/datasets/characteristic_data.characteristic_data.characteristic_metadata.pgdump.gz" -T characteristic_data.characteristic_metadata.pgdump.gz -H "X-Checksum-Sha1:63620f28ec5a2d675882e9f953035f7875542131"
# curl -u dblodgett --insecure -X PUT "https://cidasdpdasartip.cr.usgs.gov:8444/artifactory/nldi/datasets/characteristic_data.divergence_routed_characteristics.pgdump.gz" -T characteristic_data.divergence_routed_characteristics.pgdump.gz -# -o log.txt -H "X-Checksum-Sha1:e4e4e2d3829dc3deda5dfc5e7918448cd915496a"
# curl -u dblodgett --insecure -X PUT "https://cidasdpdasartip.cr.usgs.gov:8444/artifactory/nldi/datasets/characteristic_data.total_accumulated_characteristics.pgdump.gz" -T characteristic_data.total_accumulated_characteristics.pgdump.gz -# -o log.txt -H "X-Checksum-Sha1:3589b4c5a5fbd01a66840647f06bb24c10660f26"
# curl -u dblodgett --insecure -X PUT "https://cidasdpdasartip.cr.usgs.gov:8444/artifactory/nldi/datasets/characteristic_data.local_catchment_characteristics.pgdump.gz" -T characteristic_data.local_catchment_characteristics.pgdump.gz -# -o log.txt -H "X-Checksum-Sha1:0965be8afc4f4bafb82af0b6ed4d16d56a01ed5c"