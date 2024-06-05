#!/bin/bash
workdir=$1
slaves=$2

IFS=',' read -ra ADDR <<< "$slaves"
for i in "${ADDR[@]}"; do
  echo "Stopping JMeter on $i"

  ssh -o StrictHostKeyChecking=no cdsjmeterecomeu@$i "
    echo 'Checking if JMeter server is running on port 1099 on $i...'
    PID=\$(lsof -t -i:1099)
    if [ ! -z \"\$PID\" ]; then
      echo 'JMeter server is running on port 1099 on $i, attempting to stop...'
      kill \$PID
      if [ \$? -eq 0 ]; then
        echo 'Successfully stopped JMeter on $i'
      else
        echo 'Failed to stop JMeter on $i'
        exit 1
      fi
    else
      echo 'JMeter server is not running on port 1099 on $i'
    fi
  "

  if [ $? -ne 0 ]; then
    echo "SSH command failed on $i, but continuing with the next worker"
  else
    echo "SSH command succeeded on $i"
  fi
done

exit 0
