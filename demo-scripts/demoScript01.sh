#!/bin/bash - 
echo "what langague do you want to compile your files? Python, C or Perl";
read language
for i in $@
do
   if test $language = C
   then
      if test -w $i
      then
         echo gcc -c $i
      fi
   elif [ $language == Python ]
   then
      if [ -x $i ] 
      then
         echo "python $i"
      fi
   elif [ $language = Perl ]
   then
      if test -s $i
      then
         echo "Magic $i"
      fi
   else
      echo "Google $i"
   fi
done

