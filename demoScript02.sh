#!/bin/bash - 
args=$@
numArgs=$#
strArgs=$*
echo "We have $numArgs argumets"
echo 'And they are'
for i in $args
do
   echo $i
done
echo "Now let's check how they look together"
for i in $args
do
   echo -n $i
done
echo
echo "Just to remenber our argumets were: $strArgs"


