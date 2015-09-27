#!/usr/bin/python2.7 -u
import sys
number = 42
if int(len(sys.argv[1:])) > int(0):
   for i in sys.argv[1:]:
      if int(i) > int(number):
         number = i
print "Start",number
while int(number) != int(1):
   temp =  int(number) % int(2)
   if int(temp) == int(0):
      number =  int(number) / int(2)
   else:
      number =  int(3) * int(number) + int(1)
   print number


