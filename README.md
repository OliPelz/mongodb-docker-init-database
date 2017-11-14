# Instructions to build a mongodb docker image which correctly can init or seed a database
Information on how to create a mongodb Docker image which correctly initialized or seeds a database (using Docker compose)

read a lot of instructions, but none fully worked for me, so i hacked together this example which now does what i want

## Howto
1. put the data you want to import (which needs to be generated with mongodump command) into
```
./mongo-seed-data
```
2. change the target database (myawesomedb) you want to import to in
```
./mongodb-scripts/seed.sh

```
3. finally run docker compose to do the jobn
```
docker-compose up
```




## Files and test

docker-compose.yml

```
version: '3'
services:
  mongo.db:
        image: mongo:latest
        environment:
                 # provide your credentials here
                 - MONGO_INITDB_ROOT_USERNAME=mongoadmin
                 - MONGO_INITDB_ROOT_PASSWORD=mypass
        ports:
           - "27017"
        volumes:
           # to make a persistent database surviving docker restarts
           - mongodb-volume:/data/db
           # mongodump'ed data goes here
           - ./mongo-seed-data:/data/mongo-seed-data
           # script to start the actual import (besides other custom things
           # you may want to do
           - ./mongodb-scripts:/docker-entrypoint-initdb.d
volumes:
        mongodb-volume:
```

./mongodb-scripts/seed.sh

```bash
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

```


Everytime you need to seed a mongodb data you need to make sure to remove the 
mongodb-volume, otherwise the docker-entrypoint-initdb.d does not get executed!

## Testdrive stuff:

First create a valid mongodb database dump from some test data
```bash
mkdir /tmp/json-import
# optionally: remove any former dump data for this test
# $rm -rf $PWD/mongo-seed-data/*

wget https://raw.githubusercontent.com/mongodb/docs-assets/primer-dataset/primer-dataset.json -P /tmp/json-import
DOCKER_TMP_IMPORT_PROCESS=`docker run -d -v /tmp/json-import/:/data/json-import -v $PWD/mongo-seed-data/:/data/json-export mongo:latest`
docker exec $DOCKER_TMP_IMPORT_PROCESS /bin/bash -c 'mongoimport --db mydb --collection restaurants --drop --file /data/json-import/primer-dataset.json; mongodump -d mydb -o /data/json-export/'
docker kill $DOCKER_TMP_IMPORT_PROCESS
# prepare dumped data, as mongodump seems to be to dumb to have an option for this (create dump without creating the parent db dir)
mv $PWD/mongo-seed-data/mydb/* $PWD/mongo-seed-data/ && rmdir $PWD/mongo-seed-data/mydb
```

# now use this dump with our docker-compose setup
```bash
# first remove all existing volumes, otherwise the init scripts will not fire!, do this every time you need to init something new
docker-compose down -v

# now start the import ;)
docker-compose up
```
you should see something like the following in the log out
```bash
mongo.db_1  | 2017-11-14T13:35:17.874+0000	restoring myawesomedb.restaurants from /data/mongo-seed-data/restaurants.bson
mongo.db_1  | 2017-11-14T13:35:18.108+0000	no indexes to restore
mongo.db_1  | 2017-11-14T13:35:18.108+0000	finished restoring myawesomedb.restaurants (25359 documents)
mongo.db_1  | 2017-11-14T13:35:18.108+0000	done
mongo.db_1  | data imported

```

# test if data has been successfully imported (open in another window in same dir) 
docker-compose exec mongo.db /bin/bash -c "mongo -u mongoadmin -p mypass  myawesomedb --authenticationDatabase admin --eval 'db.restaurants.find();'"
```




