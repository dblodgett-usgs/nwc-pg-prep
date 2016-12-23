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

pg_dump -t charametadata postgresql://$username:$password@localhost/nldi -O --file="charametadata.pgdump"
pg_dump -t acc_charadata postgresql://$username:$password@localhost/nldi -O --file="acc_charadata.pgdump"
pg_dump -t tot_charadata postgresql://$username:$password@localhost/nldi -O --file="tot_charadata.pgdump"
pg_dump -t cat_charadata postgresql://$username:$password@localhost/nldi -O --file="cat_charadata.pgdump"

for file in *.pgdump; do gzip $file; done;
