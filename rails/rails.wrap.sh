#!/bin/bash
# rails.sh wrapper for local testing and debugging

# create temp file
file=$(mktemp)
chmod +x $file
cat rails.sh > $file

# replace variables with example data
sed -i 's/${{DOCKER_IMAGE}}/alpine:3/g' $file
sed -i 's/${{SECRETS_PREFIX}}/MY_APP/g' $file


# run and delete file
$file "$@"
rm $file

