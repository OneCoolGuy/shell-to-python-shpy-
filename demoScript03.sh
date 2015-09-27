#!/bin/bash - 
echo "I will try and do a magic trick for you!"
while true
do
echo -n "Are you read?(Y/n)"
read answer
myNumber=2
while [ $answer != 'Y' ]
do
myNumber=`expr $myNumber + 2`
echo -n "And now, are you ready?"
read answer
done
echo "Good! =)"
echo "Now please add $myNumber to your number"
echo "Now divide this number by 2"
echo "And now remove from this new number the number your original number"
$myNumber=`expr $myNumber / 2`
echo "Your number is $myNumber"
echo -n 'Wanna play again?(Y/n)'
read answer
if test $answer = 'n'
then
exit 0
fi
done
