#!/usr/bin/perl -w

# written by Lucas Germano da Silva August 2015
# as a COMP2041/9041 assignment 
# http://cgi.cse.unsw.edu.au/~cs2041/assignment/shpy

@whileAndForStack = (); # stack that keeps count of whiles and fors
$ifFlag = 0;  #
$line_sep = "!#&@!";
@program = ();
# %libraries;

while ($line = <>) {
   chomp $line;
   push(@program,$line);

   if ($line =~ /^#!/ && $. == 1) {
      print "#!/usr/bin/python2.7 -u\n";
      shift @program;
   }
}

unshift(@program, $line_sep);
libraryCall(\@program); # to determine what to import
shift(@program);
$comments = "";

foreach $line (@program){
   print "$comments\n" if ($comments !~ m/^\s*$/);
   $comments = "";
   $line =~ s/^(\s*)//;#get the identation of the line and remove it from the line
   $identation = '   ' x ($ifFlag + scalar @whileAndForStack);
   if ($line =~ s/[^\$](#[^"']+)$//){
      $comments = $1;
   }
   next if ($ifFlag > 0 && thenElseElifFi($line, $identation)); # for when inside a if loop
   next if (scalar @whileAndForStack > 0 && doOrDone($line, $identation)); # if inside a for loop
   next if (echo($line, $identation)); #see if it is a echo line
   next if (variable($line, $identation));
   next if (exists $libraries{'subprocess'} && sprocess($line, $identation));
   next if (exists $libraries{'os'} && cd($line, $identation));
   next if (exists $libraries{'sys'} && sys($line, $identation));
   next if (forloops($line, $identation)); 
   next if (ifelse($line, $identation));
   next if (whileLoop($line, $identation));
   if ($line =~ m/^#/){
      print "$identation$line\n";
   } elsif ($line !~ m/^\s*$/){
      print "#$identation$line\n" ;
   } else {
      print "\n";
   }
}


sub libraryCall{
   my $prog = join($line_sep, @{$_[0]});
   
   if ($prog =~ m/\Q$line_sep\E\s*(ls|pwd|id|date|rm)/g || $prog =~ m/`(ls|pwd|id|date|rm)/g){ # or in the begining or as after `
      print "import subprocess\n";
      $libraries{'subprocess'} = 1; # say that this library was called
   }
   if ($prog =~ m/\Q$line_sep\E\s*(read|exit|-n)/g || $prog =~ m/\$[\d\@\#\*]/g){
      print "import sys\n";
      $libraries{'sys'} = 1;
   }
   if ($prog =~ m/\Q$line_sep\Ecd/g || $prog =~ m/-[drsfwx]/){
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
         $word = notPrintVariable($word);
         if ($word =~ m/sys\./){
            print "] + $word";
            $index++;
         } else {
            if ($index++ > 0 && $index < @words){
               print "," if ($word !~ m/^$/); #print the comma if its not the last word
            }
            print " $word";
            if ($index >= @words){
               print "]";
            }
         }
      }
      print ")\n";
      return 1;
   }
   return 0;
}

sub sprocessNoLine{ #same as above but withouth new line
   my $line = $_[0];
   if ($_[0] =~ m/^(ls|pwd|id|date|rm)/){
      print "subprocess.call([";
      $line = $line . " "; # add a white space so my match can get the last word
      my @words = ( $line =~ m/([^\s]*)/g);
      my $index = 0;
      @words = grep { $_ ne '' } @words; #remove any white space from the array
      while ($index < @words){
         $word = $words[$index];
         chomp $word;
         $word = notPrintVariable($word);
         if ($word =~ m/sys\./){
            print "] + $word";
            $index++;
         } else {
            if ($index++ > 0 && $index <= @words){
               print "," if ($word !~ m/^$/); #print the comma if its not the last word
            }
            print " $word";
            if ($index >= @words){
               print "]";
            }
         }
      }
      return 1;
   }
   return 0;
}

sub echo{
   my $line = $_[0];
   my $noNewLines = 0;
   if ($line =~ m/echo\s+\-n/){
      $noNewLines = 1;
      $line =~ s/\-n//;
   }
   if ($line =~ m/echo/){
      print $_[1]; #to print any identation
      if ($noNewLines == 0){
         print "print";
      } else {
         print "sys.stdout.write(";
      }
      $line =~ s/^\s*echo\s*//;
      if ($line =~ m/^[']/){ #single quotes print the whole line
         print " $line";
      } elsif ( $line =~ m/^["]/ ) {#double quotes print the whole line PS: DEAL WITH VARIABLES 
         my @vars = ($line =~ m/(\$[^ ]+)/g);
         foreach my $var (@vars){
            my $temp = notPrintVariable($var);
            $temp =~ s/^(sys\..*)/' '.join\($1\)/; #case where it's $@
            $var = quotemeta $var;
            $line =~ s/$var/",$temp,"/;
         }
         $line =~ s/"?,"$//;
         $line =~ s/ "/"/g;
         $line =~ s/" /"/g;
         $line =~ s/"",//g;
         print " $line";
      } else {
         $line = $line . " "; # add a white space so my match can get the last word
         my @words = ( $line =~ m/([^\s]*)/g);
         my $index = 0;
         @words = grep { $_ ne '' } @words; #remove any white space from the array
         while ($index < @words){
            $word = $words[$index];
            chomp $word;
            # print "WORD $word WORD\n";
            my @vars = ($word =~ m/(\$?[^\$ ]+)/g);
            foreach my $var (@vars){
               my $temp = notPrintVariable($var);
               $temp =~ s/^(sys\..*)/''.join\($1\)/; #case where it's $@
               $var = quotemeta $var;
               $word =~ s/$var/$temp,/; #change old var for new temp
               $word =~ s/,$//; #remove last ,
            }
            print " $word";
            if (++$index < @words){
               print "," if ($word !~ m/^$/); #print the comma if its not the last word
            }
         }
      }
      if ($noNewLines == 0){
         print "\n";
      } else {
         print ")\n";
      }
      return 1; #return if found a echo TRUE
   }
   return 0; #return false otherwise
}

sub variable{
   my $line = $_[0];
   my $r = 0;
   if ($line =~ m/(\w+)=([a-zA-Z]+)/){ #for strings
      print $_[1]; #to print identation
      print "$1 = '$2'\n";
      $r = 1;
   } elsif ($line =~ m/(\w+)=`expr\s*(.*)/){ # for expr
      print $_[1]; #to print identation
      print "$1 = ".dealingWithExpr($2)."\n";
      $r = 1;
   } elsif ($line =~ m/(\w+)=(`.*)/){
      print $_[1];
      print "$1 = ";
      my @procall = $line =~ m/`(.*)`/g;
      foreach $proc (@procall){
         sprocessNoLine($proc);
      }
      print ")\n"; 
      $r = 1;
   } elsif ($line =~ m/(\w+)=([0-9]+)/){ # for numerical values
      print $_[1]; #to print identation
      print "$1 = $2\n";
      $r = 1;
   } elsif ($line =~ m/(\w+)=\$([\d])/) { # for special variables
      print $_[1];
      print "$1 = sys.argv[$2]\n";
      $r = 1;
   } elsif ($line =~ m/(\w+)=(\$[\*#@])/){ # for special variables
      print $_[1]; #to print identation
      my $name = $1;
      my $var = $2;
      if ($line =~ m/@/){
         $var = "sys.argv[1:]";
      } else {
         $var = notPrintVariable($var);
      }
      print "$name = $var\n";
      $r = 1;
   } elsif ($line =~ m/(\w+)=\$([^ ]+)/){
      print $_[1]; #to print identation
      print "$1 = $2\n";
      $r = 1;
   }
   return $r;	
}

sub forloops{ #ADD seq{..} support
   my $line = $_[0];
   my $loop;
   if ($line =~ m/^for/){
      print $_[1];
      unshift(@whileAndForStack, 'for');
      my $variable = ($line =~ m/for\s+([^ ]+)/g)[0];
      if ($line =~ m/in\s*(.*[\/\*\?\[\]].*)\s*/g){
         $loop = "sorted(glob.glob(\"$1\"))";
         print "for $variable $loop";
      } elsif ($line =~ m/in\s*\{(\d+)\.\.(\d+).*\}/g) { #for loops using {1..10} syntax
         my $var1 = notPrintVariable($1);
         my $var2 = notPrintVariable($2);
         if ($line =~ m/(\d+)\.\.(\d+)\.\.(\d+)/g){
            my $var3 = $3;
            $loop = "in range ($var1, ". ($var2 + 1) . ", $var3)";
         } elsif ($line =~ m/(\d+)\.\.(\d+)/g) {
            $loop = "in range ($var1, ". ($var2 + 1) .")";
         }
         print "for $variable $loop";
      } elsif ($line =~ m/in\s*\$\(seq\s*(\$[^ ]*|\d+)\s*(\$[^ ]*|\d+).*/g) { #for loops using seq{1..10} syntax
         my $var1 = notPrintVariable($1);
         my $var2 = notPrintVariable($2);
         if ($line =~ m/seq\s+(\$[^ ]*|\d+)\s*(\$[^ ]*|\d+)\s*(\$[^ ]*|\d+)/g){
            my $var3 = $3;
            $loop = "in range (int($var1),  int($var2) + 1, int($var3))";
         } elsif ($line =~ m/seq\s+(\$[^ ]*|\d+)\s*(\$[^ ]*|\d+)/g) {
            $loop = "in range (int($var1), int($var2 + 1))";
         }
         print "for $variable $loop";
      } elsif ($line =~ m/in\s*`(.*)`/g) {
         print "for $variable in ";
         sprocessNoLine($1);
         print ")";
      } elsif ($line =~ m/in\s*(.*)/g) {
         my @words = split(' ', $1);
         print "for $variable in ";
         my $index = 0;
         while ($index < @words){
            my $word = $words[$index];
            chomp $word;
            $word = notPrintVariable($word);
            print $word;
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

sub whileLoop{
   my $line =$_[0];
   if ($line =~ m/^while/){
      print $_[1];
      unshift(@whileAndForStack, 'while'); # keep count of while and for 
      if ($line =~ m/while\s*(?:test|\[)?\s*([^ ]+)\s+([!=<>]{1,2})\s+([^ ]+)/){
         my $var1 = $1; 
         my $var2 = $3;
         $var1 = notPrintVariable($var1); 
         $var2 = notPrintVariable($var2);
         my $comp = $2;
         print "while $var1 $comp $var2:\n";
      } elsif ($line =~ m/while\s*(?:test|\[)?\s*(\$?[^ ]+)\s+(-[a-z]{2})\s+(\$?[^ ]+)/){
         my $var1 = $1; 
         my $var2 = $3;
         $var1 = notPrintVariable($var1); 
         $var2 = notPrintVariable($var2);
         my $comp = $2;
         print "while int($var1) ";
         numComparison($comp);
         print " int($var2):\n";
      } elsif ($line =~ m/while\s*(?:test|\[)?\s*(-[a-z])\s+([^ ]+)/) { #while for files
         print "while ";
         osComparison($1, $2);
         print ":\n";
      } elsif ($line =~ m/while\s+read\s+(.*)\s*$/){ # when wants to read fromm std in
         print "while True:\n";
         print $_[1]."\t"; #print identation
         print "$1 = sys.stdin.readline()\n";
         print $_[1]."\t"; #print identation
         print "if not $1:\n";
         print $_[1]."\t\t"; #print identation
         print "break\n"
      } elsif ($line =~ m/while\s+(?:true)?\s*$/){
         print "while True:\n";
      }
      return 1;
   }
   return 0;
}



sub doOrDone{ # for do or done in while and for loops
   my $line = $_[0];
   if ($line =~ m/^do\s*$/g){
      return 1;
   } elsif ($line =~ m/^done\s*$/g){
      shift(@whileAndForStack);
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
      if ($line =~ m/if\s*(?:test|\[)?\s*"?([^ ]+)"?\s+([!=<>]{1,2})\s+"?([^ ]+)"?/){ #not numeric
         my $var1 = $1; 
         my $var2 = $3;
         my $comp = $2;
         $var1 = notPrintVariable($var1);
         $var2 = notPrintVariable($var2);
         if ($comp =~ m/^=$/){
            print "if $var1 $comp$comp $var2:\n";
         } else {
            print "if $var1 $comp $var2:\n";
         }
      } elsif ($line =~ m/if\s*(?:test|\[)?\s*(\$?[^ ]+)\s+(-[a-z]{2})\s+(\$?[^\] ]+)/){ #numeric
         my $var1 = $1; 
         my $var2 = $3;
         my $comp = $2;
         $var1 = notPrintVariable($var1);
         $var2 = notPrintVariable($var2);
         print "if int($var1) ";
         numComparison($comp);
         print " int($var2):\n";
      } elsif ($line =~ m/if\s*(?:test|\[)?\s*(-[a-z])\s+([^ ]+)/) { #if for files
         print "if ";
         osComparison($1, $2);
         print ":\n";
      } elsif ($line =~ m/if\s*(true|false)/i) {
         print "if $1\n"
      }
      return 1;
   }
   return 0;
}

sub thenElseElifFi{
   my $line = $_[0];
   $ident = $_[1];
   $ident =~ s/ {3}$//; # remove one level of identation 
   # print "\n";
   if ($line =~ m/^then\s*$/){
      return 1;
   } elsif ($line =~ m/^el(if.*)/){
      print $ident;
      print "el";
      # print "AQUI $ifFlag LOl\n";
      $ifFlag--;
      ifelse($1,''); # call if function with el in the begginning and with no identation
      return 1;
   } elsif ($line =~ m/^else\s*/){
      print $ident;
      print "else:\n";
      return 1;
   } elsif ($line =~ m/^fi/){
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

sub osComparison{# for comparison related to files and directories that need to call the os
   my $comp = $_[0];
   my $var = $_[1];
   if ($comp =~ m/-[rf]/){
      if ($var =~ m/^\$/){
         $var =~ s/\$//;
         print "os.access($var, os.R_OK)";
      } else {
         print "os.access('$var', os.R_OK)";
      }
   } elsif ( $comp =~ m/-d/){
      if ($var =~ m/^\$/){
         $var =~ s/\$//;
         print "os.path.isdir($var)";
      }else{
         print "os.path.isdir('$var')";
      }
   } elsif ( $comp =~ m/-s/){
      if ($var =~ m/^\$/){
         $var =~ s/\$//;
         print "os.path.getsize($var) > 0";
      } else {
         print "os.path.getsize('$var') > 0";
      }
   } elsif ( $comp =~ m/-w/){
      if ($var =~ m/^\$/){
         $var =~ s/\$//;
         print "os.access($var, os.W_OK)";
      } else {
         print "os.access('$var', os.W_OK)";
      }
   } elsif ( $comp =~ m/-x/){
      if ($var =~ m/^\$/){
         $var =~ s/\$//;
         print "os.access($var, os.X_OK)";
      } else {
         print "os.access('$var', os.X_OK)";
      }
   }
}

sub notPrintVariable{ # NOT PRINTING VARIABLE USED TO DISCOVER WHAT VARIABLE IT IS
   my $line = $_[0];
   my $var = $line;
   if ($line =~ m/^([^\$|\d|'|"]+)$/){ #for strings
      $var = "'$1'";
   } elsif ($line =~ m/^([0-9]+)$/){ # for numerical values
      $var = $1;
   } elsif ($line =~ m/^"?\$(\d)"?/) { # for special variables
      $var = "sys.argv[$1]";
   } elsif ($line =~ m/^["]?\$([@#\*])["]?/){ # for special variables
      my $temp = $1;
      $var = "sys.argv[1:]" if ($temp =~ m/@/);
      $var = "len(sys.argv[1:])" if $temp =~ m/#/;
      $var = "' '.join(sys.argv[1:])" if $temp =~ m/\*/;
   } elsif ($line =~ m/^["]?\$(.+)["]?/){
      $var = "$1";
   } elsif ($line =~ m/^('.+')/){
      $var = "$1";
   }
   return $var;	
}

sub dealingWithExpr{
   my $line = $_[0];
   $line =~ s/(`)//g;
   my $expr = "";
   my @words = split / /, $line;
   foreach my $word (@words){
      if ($word =~ m/^\s*$/){
         next;
      } elsif ($word =~ m/([\*\+\-\/\|\&\<\=\%])/){
         $expr = $expr." ".$1;
      } else {
         $expr = $expr." int(".notPrintVariable($word).")";
      }
   }
   return $expr;
}
