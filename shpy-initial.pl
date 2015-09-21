#!/usr/bin/perl

# written by andrewt@cse.unsw.edu.au August 2015
# as a starting point for COMP2041/9041 assignment 
# http://cgi.cse.unsw.edu.au/~cs2041/assignment/shpy

$forFlag = 0;
$ifFlag = 0;
$line_sep = "!#&@!";
@program = ();
%libraries;

while ($line = <>) {
   chomp $line;
   push(@program,$line);

   if ($line =~ /^#!/ && $. == 1) {
      print "#!/usr/bin/python2.7 -u\n";
   }
}

libraryCall(\@program); # to determine what to import

foreach $line (@program){
   $line =~ s/^(\s*)//;#get the identation of the line and remove it from the line
   $identation = $1;
   next if ($ifFlag > 0 && thenElseElifFi($line, $identation)); # for when inside a if loop
   next if ($forFlag > 0 && doOrDone($line, $identation)); # if inside a for loop
   next if (echo($line, $identation)); #see if it is a echo line
   next if (variable($line, $identation));
   next if ($libraries{'subprocess'} == 1 && sprocess($line, $identation));
   next if ($libraries{'os'} == 1 && cd($line, $identation));
   next if ($libraries{'sys'} == 1 && sys($line, $identation));
   next if (forloops($line, $identation)); #see if it is a echo line
   next if (ifelse($line, $identation));

}


sub libraryCall{
   my $prog = join($line_sep, @{$_[0]});
   if ($prog =~ m/\Q$line_sep\E\s*(ls|pwd|id|date|rm)/g){
      print "import subprocess\n";
      $libraries{'subprocess'} = 1; # say that this library was called
   }
   if ($prog =~ m/\Q$line_sep\E\s*(read|exit)/g || $prog =~ m/\$[\d]/g){
      print "import sys\n";
      $libraries{'sys'} = 1;
   }
   if ($prog =~ m/\Q$line_sep\E\s*(cd)/g){
      print "import os\n";
      $libraries{'os'} = 1;
   }
   if ($prog =~ m/\Q$line_sep\E.*(glob)/g){
      print "import glob\n";
      $libraries{'glob'} = 1;
   }
}


sub sprocess{
   my $line = $_[0];
   if ($_[0] =~ m/^(ls|pwd|id|date|rm)/){
      print "$_[1]"; #identation
      print "subprocess.call([";
      $line = $line . " "; # add a white space so my match can get the last word
      my @words = ( $line =~ m/([^\s]*)/g);
      my $index = 0;
      @words = grep { $_ ne '' } @words; #remove any white space from the array
      while ($index < @words){
         $word = $words[$index];
         chomp $word;
         print " '$word'" if ($word !~ m/^$/);
         if (++$index < @words){
            print "," if ($word !~ m/^$/); #print the comma if its not the last word
         }
      }
      print "])\n";
      return 1;
   }
   return 0;
}

sub echo{
   my $line = $_[0];
   if ($line =~ m/echo/){
      print $_[1]; #to print any identation
      print "print";
      $line =~ s/^\s*echo\s*//;
      if ($line =~ m/^[']/){ #single quotes print the whole line
         print " $line\n";
      } elsif ( $line =~ m/^["]/ ) {#double quotes print the whole line PS: DEAL WITH VARIABLES 
         print " $line\n";
      } else {
         $line = $line . " "; # add a white space so my match can get the last word
         my @words = ( $line =~ m/([^\s]*)/g);
         my $index = 0;
         @words = grep { $_ ne '' } @words; #remove any white space from the array
         while ($index < @words){
            $word = $words[$index];
            chomp $word;
            if ($word =~ m/^\$(\d)/) {
               print " sys.argv[$1]";
            } elsif ($word =~ m/^\$(.*)/){
               print " $1"; #print the variable withouth quotes
            } else {
               print " '$word'" if ($word !~ m/^$/);
            }
            if (++$index < @words){
               print "," if ($word !~ m/^$/); #print the comma if its not the last word
            }
         }
      print "\n";
      }
      return 1; #return if found a echo TRUE
   }
   return 0; #return false otherwise
}

sub variable{
   my $line = $_[0];
   my $r = 0;
   if ($line = m/(\w*)=([a-zA-Z]*)/){ #for strings
      print $_[1]; #to print identation
      print "$1 = '$2'\n";
      $r = 1;
   } elsif ($line = m/(\w*)=([0-9]*)/){ # for numerical values
      print $_[1]; #to print identation
      print "$1 = $2\n";
      $r = 1;
   } elsif ($line = m/(\w*)=\$(\d)/){ # for special variables
      print $_[1];
      print "$1 = sys.argv[$2]";
      $r = 1;
   } elsif ($line = m/(\w*)=\$(.)/){ # for special variables
      print $_[1]; #to print identation
      print "$1 = $2";
      $r = 1;
   }
   return $r;	
}

sub forloops{
   my $line = $_[0];
   my $loop;
   if ($line =~ m/^for/){
      print $_[1]; #print identation
      $forFlag++;
      my $variable = ($line =~ m/for\s+([^ ]+)/g)[0];
      if ($line =~ m/in\s*(.*[\/\*\?\[\]].*)\s*/g){
         $loop = "sorted(glob.glob(\"$1\"))";
         print "for $variable $loop";
      } elsif ($line =~ m/in\s*\{(\d+)\.\.(\d+).*\}/g) { #for loops using {1..10} syntax
         if ($line =~ m/(\d+)\.\.(\d+)\.\.(\d+)/g){
            $loop = "in range ($1, ". ($2 + 1) . ", $3)";
         } elsif ($line =~ m/(\d+)\.\.(\d+)/g) {
            $loop = "in range ($1, ". ($2 + 1) .")";
         }
         print "for $variable $loop";
      } elsif ($line =~ m/in\s*(.*)/g) {
         my @words = split(' ', $1);
         print "for $variable in ";
         my $index = 0;
         while ($index < @words){
            my $word = $words[$index];
            chomp $word;
            if ($word =~ m/\d+/){
               print " $word"; #print the variable withouth quotes
            } else {
               print " '$word'";
            }
            if (++$index < @words){
               print "," if ($word !~ m/^$/); #print the comma if its not the last word
            }
         }
      }  
      print ":\n";
      return 1;
   }
   return 0;
}

sub doOrDone{ # for do or done in for loops
   my $line = $_[0];
   if ($line =~ m/^do\s*$/g){
      return 1;
   } elsif ($line =~ m/^done\s*$/g){
      $forFlag = 0;
      return 1;
   }
   return 0;
}
   
sub cd{ #for cd 
   my $line = $_[0];
   if ($line =~ m/^cd\s*(.*)/g){
      print $_[1];
      print "os.chdir('$1')\n";
      return 1;
   }
   return 0;
}

sub sys{ #for commands that use the sys libary
   my $line = $_[0];
   if ($line =~ m/^exit\s*([^ ]*)/g){ #exit
      print $_[1];
      print "sys.exit($1)\n";
      return 1;
   }
   if ($line =~ m/^read\s*([^ ]*)/g){ #read
      print $_[1];
      print "$1 = sys.stdin.readline().rstrip()\n";
      return 1;
   }
   return 0;
}


sub ifelse{ 
   my $line = $_[0];
   if ($line =~ m/^if\s*/){
      print $_[1];
      $ifFlag++;
      if ($line =~ m/if\s*(?:test|\[)?\s*([^ ]+)\s+([!=<>]{1,2})\s+([^ ]+)/){
         print "if '$1' $2 '$3':\n";
      } elsif ($line =~ m/if\s*(?:test|\[)?\s*([^ ]+)\s+(-[a-z]{2})\s+([^ ]+)/){
         my $var = $3;  #store var 2 in case it is lost
         print "if $1 ";
         numComparison($2);
         print " $var:";
      } elsif (FALSE) { #if for files
      }
      return 1;
   }
   return 0;
}

sub thenElseElifFi{
   my $line = $_[0];
   if ($line =~ m/^then\s*$/){
      return 1;
   } elsif ($line =~ m/^el(if.*)/){
      print $_[1];
      print "el";
      ifelse($1,'');
      return 1;
   } elsif ($line =~ m/^else\s*/){
      print $_[1];
      print "else:\n";
      return 1;
   } elsif ($line =~ m/^fi/){
      print $_[1];
      $ifFlag--;
      return 1;
   }
   return 0;
}


sub numComparison{ # to decide which numerical comparison to use
   my $comp = $_[0];
   if ($comp =~ m/-eq/){
      print "==";
   } elsif ($comp =~ m/-ne/){
      print "!=";
   } elsif ($comp =~ m/-lt/){
      print "<";
   } elsif ($comp =~ m/-le/){
      print "<=";
   } elsif ($comp =~ m/-gt/){
      print ">";
   } elsif ($comp =~ m/-ge/){
      print ">=";
   }
}

