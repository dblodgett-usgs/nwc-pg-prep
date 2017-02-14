#!/bin/sh

psql --file=setup.sql postgresql://nldi@localhost:5432/nldi
for f in dump_files/*.gz; do gunzip -c $f | psql postgresql://nldi@localhost:5432/nldi; done