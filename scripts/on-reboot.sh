#!/bin/sh

# SETUP VM FOR ELASTICSEARCH

sudo sysctl -w vm.max_map_count=262144

# START

cd ~/SEPIA
./run-sepia.sh