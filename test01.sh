#!/bin/bash - 
oi=$@
poi=$#
ppoi=$*
echo $poi$oi
echo $ppoi
ppoi=`expr $ppoi \* 2`
