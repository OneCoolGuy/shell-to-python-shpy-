# shell-to-python-shpy-
A shell to python script converter written in perl

## Usage

It's a basic converter from shell to python that I did for a class while I was studying abroad in UNSW.

It receives a shell script and outputs a python script that tries to emulate the same behauvior.

NOTE: It is far from perfect, and even some of the demoScripts don't work as intended, but it was a great learning project.
It helped me to learn Shell, Python, Perl and regular expressions.

Examples:

#Shell

```
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
```

Python Output

```
#!/usr/bin/python2.7 -u
import sys
import os
print "what langague do you want to compile your files? Python, C or Perl";
language = sys.stdin.readline().rstrip()
for i in sys.argv[1:]:
   if language == 'C':
      if os.access(i, os.W_OK):
         print 'gcc', '-c', i
   elif language == 'Python':
      if os.access(i, os.X_OK):
         print "python",i
   elif language == 'Perl':
      if os.path.getsize(i) > 0:
         print "Magic",i
   else:
      print "Google",i
```
