#!/bin/bash
# Author: [Rahul Verma]
# basic functions for checking token, checking internet connection, building the packages, and making sound

# env | grep prox
# unset http_proxy https_proxy
# env | grep prox

makeSound()  { for i in $(seq 1 5); do echo -en "\a"; sleep 0.25; done ; }
checkToken() { tokenStatus=$(alien-token-info 2>&1 | tail -1)  # Capture the output of alien-token-info
  if [[ "$tokenStatus" == "File >>><<< not found" ]];then
    echo "$(date) ❌ ERROR :: Token Not Found, Create the token" ; makeSound
    exit 1  #stop execution if token not found
  elif [[ "$tokenStatus" == *"alien-token-info: command not found" ]]; then
    echo "❌ ERROR :: alien-token-info command not found"
    echo "do    ==> alienv load  O2Physics/latest"
    echo "or do ==> alienv enter O2Physics/latest"
    echo "or do ==> alienv load  O2Physics/latest ninja/latest"
    echo "or do ==> alienv enter O2Physics/latest ninja/latest"
    makeSound
    exit 1  #stop execution if environment is not loaded
  else
    echo "✅ Token Found, Processing further ..."
  fi
}
buildO2Task(){
  echo "BUILDING EXECUTABLE"
  currentDir=$(pwd)
  cd "$ALIBUILD_WORK_DIR"/BUILD/O2Physics-latest/O2Physics/
  time ninja install &> output-01.log;
  if [[ $(tail -1 output-01.log) == *Up-to-date* ]] ; then
     echo "✅ BUILD SUCESSFULL. Processing further ..."
  else
     if tail -1 output-01.log | grep -q "ninja: command not found"; then
     echo "ninja: command not found"
     echo "do    ==> alienv enter O2Physics/latest ninja/latest"
     echo "or do ==> alienv load  O2Physics/latest ninja/latest"
     makeSound
     exit 1
     else
     echo "❌ BUILD FAILED" ; code output-01.log ; makeSound
     exit 1 #stop execution if build failed
     fi
  fi
  cd $currentDir
}
checkInternet(){ STATUS=$(curl -s --max-time 3 -o /dev/null -w "%{http_code}" http://captive.apple.com)
  if [ "$STATUS" -eq "200" ]; then
    echo "✅ Internet access available. Processing further ..."
  else
    echo "❌ Internet blocked or login required. HTTP Status: $STATUS"
    makeSound
    exit 1
  fi
}

export MEMORY_LIMIT="--resources-monitoring 2  --aod-memory-rate-limit 1000000000  --shm-segment-size 7500000000"

#Execution part
date
starttime=$(date)

#01- token check
checkToken

#02- Build The Task 
buildO2Task

#03- Check Internet Connection
checkInternet

#04- My Execution Functions






echo $starttime >> $outfile2
date >> $outfile2
code $outfile2

echo "Printing the Errors and Warnings " &> $outfile3
grep -e "IST" -e "\\[ERROR\\]" -e "\\[FATAL\\]" -e "segmentation" -e "Segmentation" -e "SEGMENTATION" -e "command not found" -e "Error:" -e "Error in " -e "\\[WARN\\]" -e "DEBUG" -e "Read info: lfn" $outfile2  >> $outfile3
code $outfile3
date

