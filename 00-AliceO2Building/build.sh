#!/bin/bash
# Author: [Rahul Verma]
# command: nohup ./build.sh &> build.log &
# https://alice-doc.github.io/alice-analysis-tutorial/building/ #official aliBuild site.
# python3 -m pip uninstall alibuild
# python3 -m pip install alibuild --upgrade --user
# type aliBuild

nCore=20
coreSet=" -j$nCore "
buildCommand="aliBuild build O2Physics $coreSet --debug"
buildDir="$ALIBUILD_WORK_DIR/../"
currentDir=$(pwd)
timestamp=$(date '+%Y_%m_%d__%H:%M:%S')
buildLogDir=$(pwd)"/buildLogDir_$timestamp"

if ! grep -Fxq 'eval "$(direnv hook bash)"' ~/.bashrc; then
  echo 'ERROR :: eval "$(direnv hook bash)" is missing from ~/.bashrc: add this before building any task'
  return 1
fi

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
