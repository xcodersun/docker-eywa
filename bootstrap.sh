#!/bin/bash

# grant proper permissions
chown -R elasticsearch:elasticsearch /var/elasticsearch
chown -R elasticsearch:elasticsearch /etc/elasticsearch
chown -R eywa:eywa /var/eywa
chown -R eywa:eywa /etc/eywa

# start elasticsearch
supervisorctl start elasticsearch

sleep 5
curl localhost:9200
started=$?
iter=0

while [[ $started -ne 0 ]]; do
  iter=$((iter+1))
  if [[ $iter -gt 30 ]]; then
    echo 'Failed to start Elasticsearch...'
    exit 1
  fi
  echo 'Waiting for Elasticsearch to start...'
  sleep 1
  curl localhost:9200
  started=$?
done

# migrate database
supervisorctl start eywa_migrate 

# setup es templates
supervisorctl start eywa_setup_es 

# start eywa
supervisorctl start eywa_serve

