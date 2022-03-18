#!/bin/bash

# remarks:
#
# speedtest.net has no jitter measurement (.jitter has value null)
# speedtest.net upload/download values must be divided by 1000000 to get comparable results in Mbit/s (this is done in grafana dashboard)
#

# config

configfile='./speedtest2influx.conf'

if [ -f "$configfile" ]; 
then
  source "$configfile"
else
  echo "missing config file..."
  exit 1
fi

# check requirements

jq_required=$(jq --version 2>/dev/null)
returncode=$?
if [[ "$returncode" != 0  ]]; then
  echo "missing required package 'jq'"
  exit 1
fi

curl_required=$(curl --version 2>/dev/null)
returncode=$?
if [[ "$returncode" != 0  ]]; then
  echo "missing required package 'curl'"
  exit 1
fi

# execute speedtests

## librespeed

librespeedorg_result=$(librespeed-cli --telemetry-level disabled --json)
returncode=$?
if [[ "$returncode" != 0  ]]; then
  echo "error while executing librespeed.org ..."
  exit
fi

echo $librespeedorg_result | jq -r '.'

timestamp=$(echo $librespeedorg_result | jq -c -M '. | .timestamp')
timestamp=$(date -d $(echo $timestamp | tr -d \"\') +%s)
download=$(echo $librespeedorg_result | jq -c -M '. | .download')
upload=$(echo $librespeedorg_result | jq -c -M '. | .upload')
jitter=$(echo $librespeedorg_result | jq -c -M '. | .jitter')
ping=$(echo $librespeedorg_result | jq -c -M '. | .ping')

curl -i -S -XPOST "$DB_HOST/write?db=$DB_NAME_librespeedorg&precision=s&u=$DB_USERNAME&p=$DB_PASSWORD" --data-binary "download,host=$(hostname) value=$download $timestamp"
curl -i -S -XPOST "$DB_HOST/write?db=$DB_NAME_librespeedorg&precision=s&u=$DB_USERNAME&p=$DB_PASSWORD" --data-binary "upload,host=$(hostname) value=$upload $timestamp"
curl -i -S -XPOST "$DB_HOST/write?db=$DB_NAME_librespeedorg&precision=s&u=$DB_USERNAME&p=$DB_PASSWORD" --data-binary "jitter,host=$(hostname) value=$jitter $timestamp"
curl -i -S -XPOST "$DB_HOST/write?db=$DB_NAME_librespeedorg&precision=s&u=$DB_USERNAME&p=$DB_PASSWORD" --data-binary "ping,host=$(hostname) value=$ping $timestamp"

sleep 60

## speedtest.net


speedtestnet_result=$(speedtest-cli --json)
returncode=$?
if [[ "$returncode" != 0  ]]; then
  echo "error while executing speedtest.net ..."
  exit
fi

echo $speedtestnet_result | jq -r '.'

timestamp=$(echo $speedtestnet_result | jq -c -M '. | .timestamp')
timestamp=$(date -d $(echo $timestamp | tr -d \"\') +%s)
download=$(echo $speedtestnet_result | jq -c -M '. | .download')
upload=$(echo $speedtestnet_result | jq -c -M '. | .upload')
jitter=$(echo $speedtestnet_result | jq -c -M '. | .jitter')
ping=$(echo $speedtestnet_result | jq -c -M '. | .ping')


curl -i -S -XPOST "$DB_HOST/write?db=$DB_NAME_speedtestnet&precision=s&u=$DB_USERNAME&p=$DB_PASSWORD" --data-binary "download,host=$(hostname) value=$download $timestamp"
curl -i -S -XPOST "$DB_HOST/write?db=$DB_NAME_speedtestnet&precision=s&u=$DB_USERNAME&p=$DB_PASSWORD" --data-binary "upload,host=$(hostname) value=$upload $timestamp"
#curl -i -S -XPOST "$DB_HOST/write?db=$DB_NAME_speedtestnet&precision=s&u=$DB_USERNAME&p=$DB_PASSWORD" --data-binary "jitter,host=$(hostname) value=$jitter $timestamp"
curl -i -S -XPOST "$DB_HOST/write?db=$DB_NAME_speedtestnet&precision=s&u=$DB_USERNAME&p=$DB_PASSWORD" --data-binary "ping,host=$(hostname) value=$ping $timestamp"

