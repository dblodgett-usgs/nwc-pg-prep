psql --file=setup.sql postgresql://nldi@localhost/nldi
for f in dump_files/*.gz; do echo $f; time gunzip -c $f | psql postgresql://nldi@localhost/nldi; done
psql --file=add_constraints.sql postgresql://nldi@localhost/nldi