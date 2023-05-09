#!/bin/bash

# Script run on the target, to collect local benchmarks (graph-analytics, in-memory-analytics).
SPARK_ARGS="--driver-memory 15g --executor-memory 15g"
NRUNS=20

docker pull cloudsuite3/graph-analytics
docker pull cloudsuite3/twitter-dataset-graph
docker container inspect data > /dev/null || docker create --name data cloudsuite3/twitter-dataset-graph

docker pull cloudsuite3/in-memory-analytics
docker pull cloudsuite3/movielens-dataset
docker container inspect moviedata > /dev/null || docker create --name moviedata cloudsuite3/movielens-dataset

set -ex

for i in $(seq -w 1 $NRUNS); do
    docker run --rm --volumes-from data cloudsuite3/graph-analytics $SPARK_ARGS > graph-analytics-$i.log
    docker run --rm --volumes-from moviedata cloudsuite3/in-memory-analytics /data/ml-latest /data/myratings.csv $SPARK_ARGS > in-memory-analytics-$i.log
done
