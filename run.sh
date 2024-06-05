#!/bin/bash
host=$1
vu=$2
executionTime=$3
slaves=$4
workdir=$5
rampUpSec=$6
loopCount=$7

mkdir -p $workdir/reports/new

# Determine total memory and calculate 80% of it for JVM heap
total_mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
total_mem_mb=$((total_mem_kb / 1024))
heap_mem_mb=$((total_mem_mb * 80 / 100))
export JVM_ARGS="-Xms${heap_mem_mb}m -Xmx${heap_mem_mb}m"

echo "Running JMeter test with JVM_ARGS=$JVM_ARGS"
/home/cdsjmeterecomeu/jmeter-master/apache-jmeter-5.5/bin/jmeter.sh -p /home/cdsjmeterecomeu/jmeter-master/apache-jmeter-5.5/bin/user.properties -JmyPauseProperty=0 -R $slaves -G SERVER_NAME=$host -G VU_TOT=$vu -G VU=$vu -G RAMP_UP_SEC=$rampUpSec -G LOOP_COUNT=$loopCount -G DURATION_SEC=$executionTime -G RAMP_UP=$rampUpSec -G PATHJMX=$workdir/scenario/website/FO.EU.SC03.jmx -n -t $workdir/scenario/website/FO.EU.SC03.jmx -l $workdir/results.csv &

JMETER_PID=$!
sleep $((executionTime + rampUpSec))  # Wait for the test to complete
kill $JMETER_PID

# Check if the CSV file has incomplete lines and clean it
awk -F, 'NF == 17' $workdir/results.csv > $workdir/results_clean.csv
mv $workdir/results_clean.csv $workdir/results.csv

echo "Generating JMeter report"
/home/cdsjmeterecomeu/jmeter-master/apache-jmeter-5.5/bin/jmeter.sh -J jmeter.reportgenerator.overall_granularity=10000 -J jmeter.reportgenerator.report_title="jmeter-test" -g $workdir/results.csv -o $workdir/reports/new

if [ $? -ne 0 ]; then
  echo "Failed to generate JMeter report"
  exit 1
else
  echo "JMeter report generated successfully"
fi
