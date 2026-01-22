#!/bin/bash
# Author: [Rahul Verma]
# basic functions for checking token, checking internet connection, building the packages, and making sound

unsetHTTPproxy() {
  echo "[unsetHTTPproxy]: HTTP and HTTPS proxies before unset"
  env | grep prox
  unset http_proxy https_proxy
  echo "[unsetHTTPproxy]: HTTP and HTTPS proxies After unset"
  env | grep prox
  echo "[unsetHTTPproxy]: HTTP and HTTPS proxies have been unset."
}

makeSound() { for i in {1..5}; do printf '\a'; sleep 0.25; done; }

checkFiles() { #one or many files
  for f in "$@"; do
    [ -f "$f" ] && echo "✅ :: $f exists" || { echo "[checkFiles]: ❌ ERROR :: $f does not exist"; exit 1; }
  done
}

now_ns() { date +%s%N 2>/dev/null || gdate +%s%N; }  #gdate makes it macOS safe

getTime() {
  if [ $# -eq 1 ]; then
    # One argument: compute time elapsed since given start time
    local start="$1"
    local now=$(date +%s%N 2>/dev/null || gdate +%s%N) # nanoseconds
    local elapsed=$(( (now - start) / 1000 ))  # convert to microseconds
    echo "$elapsed"
  elif [ $# -eq 2 ]; then
    # Two arguments: return time difference in microseconds
    local start="$1"
    local end="$2"
    local elapsed=$((end - start))
    echo "$elapsed"
  else
    echo "Usage:"
    echo "  getTime <start>              # Shows elapsed time in microseconds"
    echo "  getTime <start> <end>        # Shows difference in microseconds"
    return 1
  fi
}

microToSeconds() {
  local microseconds="$1"
  awk "BEGIN {printf \"%.4f\", $microseconds / 1000000}"
}

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
  time ninja install &> output-01.log;  # { time ninja install; } &> output-01.log will also redirect the time output (which is stderr) in the file
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

downloadAliceFiles(){
  local alicePathList="input_ALICEPathList.txt"
  local localPathList="input_ALICEPathToLocalFile.txt"
  local alienStorageSuffix="@ALICE::CERN::EOS"
  local fileList="input_data.txt"
  local fileStat="input_data.stat"

  checkFiles "$alicePathList" "$localPathList"

  # dFlag 0 --> don't download files 
  # dFlag 1 --> download files
  # sFlag 0 --> dont get stat information
  # sFlag 1 --> get stat information

  # Default flags as false (0)
  local dFlag=0 sFlag=0
  for arg in "$@"; do
    case $arg in
      --dFlag=*)
        dFlag="${arg#*=}"
        if [[ "$dFlag" != "0" && "$dFlag" != "1" ]]; then
          echo "Invalid value for dFlag: $dFlag (expected 0 or 1). Using default 0."
          dFlag=0
        fi
        ;;
      --sFlag=*)
        sFlag="${arg#*=}"
        if [[ "$sFlag" != "0" && "$sFlag" != "1" ]]; then
          echo "Invalid value for sFlag: $sFlag (expected 0 or 1). Using default 0."
          sFlag=0
        fi
        ;;
      *)
        echo "Warning: unknown argument '$arg'"
        ;;
    esac
  done

  echo "Download files flag (dFlag): $dFlag"
  echo "Get stat info  flag (sFlag): $sFlag"

  cp "$fileList" "bkp_$fileList_$(date '+%Y_%m_%d__%H-%M-%S')"

  rm -rf "$fileList"
  if [[ "$sFlag" == "1" ]]; then rm -rf "$fileStat"; fi

  # Store inputList in an array
  local FileArray=()
  while IFS= read -r line || [[ -n $line ]]; do     #[[ -n $line ]]  will capture the last line if the file ends without new line  
      FileArray+=("$line")                       #Read from the file list and append the FileList
  done < "$alicePathList"

  local localPathArray=()
  while IFS= read -r line || [[ -n $line ]]; do     #[[ -n $line ]]  will capture the last line if the file ends without new line  
      localPathArray+=("$line")                       #Read from the file list and append the FileList
  done < "$localPathList"

  if [[ ${#FileArray[@]} -ne ${#localPathArray[@]} ]]; then
    echo "[downloadAliceFiles]: ❌ ERROR :: #FileArray[@] != #localPathArray[@] i.e. ${#FileArray[@]} != ${#localPathArray[@]}"
    exit 1
  fi

  echo 
  echo "Files to be downloaded :: nFiles = ${#FileArray[@]}"
  # Print all lines
  echo 
  local TotalTimeStart=$(( $(now_ns)/1000 ))
  local whereis_TotalTime=0
  local cp_TotalTime=0
  local timeDiff
  echo "FILE DOWNLOAD START ..."
  for (( i=0; i< ${#FileArray[@]}; i++ )) ; do
    echo "[downloadAliceFiles]: $((i+1))/${#FileArray[@]} :: ${FileArray[i]}  ==> ${localPathArray[i]}"
    echo "[downloadAliceFiles]: $((i+1))/${#FileArray[@]} :: Downloading...⏳"
    local filePath=${FileArray[$i]}
    local localPath=${localPathArray[$i]}

    if [[ "$sFlag" == "1" ]]; then
      whereis_TimeStart=$(( $(now_ns)/1000 ))
      echo "checking file :: $filePath" >> $fileStat
      alien.py whereis "$filePath" >> "$fileStat"
      timeDiff=$(getTime "$whereis_TimeStart")
      (( whereis_TotalTime += timeDiff ))        #((whereis_TotalTime+= $(getTime "$whereis_TimeStart")))
    fi

    if [[ "$dFlag" == "1" ]] ; then 
      local cp_TimeStart=$(( $(now_ns)/1000 ))
      if alien.py cp "${filePath}${alienStorageSuffix}" "file::$localPath" ; then
        echo "[downloadAliceFiles]: File Download Successful"
        echo "$localPath" >> "$fileList"
      else
        echo "[downloadAliceFiles]: File Download Failed"
      fi
      timeDiff=$(getTime "$cp_TimeStart")
      (( cp_TotalTime += timeDiff ))
    else 
      echo "$localPath" >> "$fileList"
    fi
  done
  
  checkFiles $fileList
  echo "FILE DOWNLOAD OVER :: alien.py cp Time = $(microToSeconds $cp_TotalTime ) seconds"
  echo "FILE DOWNLOAD OVER :: whereIs     Time = $(microToSeconds $whereis_TotalTime ) seconds"
  echo "FILE DOWNLOAD OVER :: total       Time = $(microToSeconds "$(getTime "$TotalTimeStart")") seconds"
}
