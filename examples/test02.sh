#!/bin/bash - 
args=$@
for i in $args
do
   echo "hi $@ $# $*"
done
