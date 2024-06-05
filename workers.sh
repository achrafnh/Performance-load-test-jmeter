#!/bin/bash
workdir=$1
slaves=$2

IFS=',' read -ra ADDR <<< "$slaves"
for i in "${ADDR[@]}"; do
  echo "Configuring JMeter server on $i"

  ssh -o StrictHostKeyChecking=no cdsjmeterecomeu@$i "
    # Determine total memory and calculate 80% of it for JVM heap
    total_mem_kb=\$(grep MemTotal /proc/meminfo | awk '{print \$2}')
    total_mem_mb=\$((total_mem_kb / 1024))
    heap_mem_mb=\$((total_mem_mb * 80 / 100))
    export JVM_ARGS=\"-Xms\${heap_mem_mb}m -Xmx\${heap_mem_mb}m\"
    echo \"Starting JMeter with JVM_ARGS=\$JVM_ARGS\"

    # Start JMeter server
    cd /home/cdsjmeterecomeu/jmeter-master/apache-jmeter-5.5/bin
    nohup ./jmeter-server > jmeter-server.log 2>&1 &

    # Check if JMeter server started
    sleep 5
    if pgrep -f jmeter-server > /dev/null; then
      echo 'JMeter server started successfully on $i'
    else
      echo 'Failed to start JMeter server on $i'
      exit 1
    fi
  "

  if [ $? -ne 0 ]; then
    echo "Failed to configure JMeter server on $i"
    exit 1
  else
    echo "Configured JMeter server on $i"
  fi
done

# Start JMeter server on the master node
echo "Starting JMeter server on the master node"

total_mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
total_mem_mb=$((total_mem_kb / 1024))
heap_mem_mb=$((total_mem_mb * 80 / 100))
export JVM_ARGS="-Xms${heap_mem_mb}m -Xmx${heap_mem_mb}m"
echo "Starting JMeter with JVM_ARGS=$JVM_ARGS"

cd /home/cdsjmeterecomeu/jmeter-master/apache-jmeter-5.5/bin
nohup ./jmeter-server > jmeter-server.log 2>&1 &

# Check if JMeter server started
sleep 5
if pgrep -f jmeter-server > /dev/null; then
  echo 'JMeter server started successfully on the master node'
else
  echo 'Failed to start JMeter server on the master node'
  exit 1
fi
