#!/usr/bin/env bash
if [ -z "$1" ]; then
  echo "Missing argument : MongoDB URI without database";
  echo "Example for localhost without security : mongodb://localhost "
  echo "Example for Atlas with user/password   : mongodb+srv://user:password@freecluster-abcde.mongodb.net"
  exit 1
fi
mongoimport --drop -c books --uri $1/test catalog.books.json
mongoimport --drop -c countries --uri $1/test country.json
mongoimport --drop -c covers --uri $1/test covers.json
mongoimport --drop -c grades --uri $1/test grades.json
mongoimport --drop -c products --uri $1/test products.json
mongoimport --drop -c profiles --uri $1/test profiles.json
mongoimport --drop -c restaurants --uri $1/test restaurant.json
mongoimport --drop -c students --uri $1/test students.json
wget -qO- http://media.mongodb.org/zips.json | mongoimport --drop -c zips --uri $1/test

unzip palbum.zip
mongoimport --drop -c images --uri $1/music palbum/images.json
mongoimport --drop -c albums --uri $1/music palbum/albums.json
rm -rf palbum

unzip tweets.zip
mongorestore --drop --uri $1
rm -rf dump
