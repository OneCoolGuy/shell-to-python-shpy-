#!/bin/bash - 
number=42
if test $# -gt 0
then 
   for i in $@
   do
      if [ $i -gt $number ]
      then
         number=$i
      fi
   done
fi
echo "Start $number"
while [ $number -ne 1 ]
do
   temp=`expr $number % 2`
   if test $temp -eq 0
   then
      number=`expr $number / 2`
   else
      number=`expr 3 \* $number + 1`
   fi
   echo $number
done
   

