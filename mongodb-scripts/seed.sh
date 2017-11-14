#!/usr/bin/env bash

echo "start importing data"
# db_to_feed needs to be defined
# mongorestore -u mongoadmin -p mypass --authenticationDatabase admin -d db_to_feed ./mongo-seed-data
# e.g.
mongorestore -u mongoadmin -p mypass --authenticationDatabase admin -d myawesomedb /data/mongo-seed-data
echo "data imported"


echo "Doing other useful mongodb database stuff, e.g creating additional mongo users..."
mongo admin -u mongoadmin -p mypass --eval "db.createUser({user: 'another_user', pwd: 'reallysecret', roles: [{role: 'readWrite', db: 'myawesomedb'}]});"
echo "Mongo users created."

