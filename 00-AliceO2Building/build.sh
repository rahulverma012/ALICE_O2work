#!/bin/bash
# Author: [Rahul Verma]

nCore=20
buildCommand="aliBuild build O2Physics -j$nCore --debug"
buildDir="$ALIBUILD_WORK_DIR/../"
currentDir=$(pwd)
timestamp=$(date '+%Y_%m_%d__%H:%M:%S')
buildLogDir=$(pwd)"/buildLogDir_$timestamp"

echo $buildLogDir

mkdir $buildLogDir
cd $buildDir
for i in $(seq 1 20); do
  echo $i ; 
  echo $buildCommand
  logFile="$buildLogDir/buildOutput-$i.log"
  echo $logFile
  time $buildCommand &> $logFile
done

echo "Building loop is over"
