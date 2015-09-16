#!/usr/bin/perl

# written by andrewt@cse.unsw.edu.au August 2015
# as a starting point for COMP2041/9041 assignment 
# http://cgi.cse.unsw.edu.au/~cs2041/assignment/shpy

$line_sep = "!#&@!";
@program = ();
%libraries;

while ($line = <>) {
    chomp $line;
	push(@program,$line);
	
    if ($line =~ /^#!/ && $. == 1) {
        print "#!/usr/bin/python2.7\n";
	}
}

libraryCall(\@program); # to determine what to import

foreach $line (@program){
	$line =~ s/^(\s*)//;#get the identation of the line and remove it from the line
	$identation = $1;
	next if (echo($line, $identation)); #see if it is a echo line
	next if (variable($line, $identation));
	next if ($libraries{'subprocess'} == 1 && sprocess($line, $identation));

}


sub libraryCall{
	my $prog = join($line_sep, @{$_[0]});
	if ($prog =~ m/\Q$line_sep\E\s*(ls|pwd|id|date|rm)/g){
		print "import subprocess\n";
		$libraries{'subprocess'} = 1; # say that this library was called
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
			print "$line\n";
		} elsif ( $line =~ m/^["]/ ) {#double quotes print the whole line PS: DEAL WITH VARIABLES 
			print "$line\n";
		} else {
			$line = $line . " "; # add a white space so my match can get the last word
			my @words = ( $line =~ m/([^\s]*)/g);
			my $index = 0;
			@words = grep { $_ ne '' } @words; #remove any white space from the array
			while ($index < @words){
				$word = $words[$index];
				chomp $word;
				if ($word =~ m/^\$(.*)/){
					print " $1"; #print the variable withouth quotes
				} else {
					print " '$word'" if ($word !~ m/^$/);
				}
				if (++$index < @words){
					print "," if ($word !~ m/^$/); #print the comma if its not the last word
				}
			}
		}
		print "\n";
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
	} elsif ($line = m/(\w*)=\$(.)/){ # for special variables
		print $_[1]; #to print identation
		print "THIS IS A SPECIAL VARIBLE\n";
		$r = 1;
	}
	return $r;	
}
