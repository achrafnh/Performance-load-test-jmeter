#!/bin/bash
workdir=$1
slaves=$2

IFS=',' read -ra ADDR <<< "$slaves"
for i in "${ADDR[@]}"; do
  echo "Creating work directory on $i"
  ssh -tt -o StrictHostKeyChecking=no cdsjmeterecomeu@$i "mkdir -p $workdir"

  echo "Copying files to $i"
  scp -o StrictHostKeyChecking=no -C -r $workdir/* cdsjmeterecomeu@$i:$workdir
done
