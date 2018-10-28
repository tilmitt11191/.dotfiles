#!/usr/bin/perl
package util;
use strict;
use warnings;

use Time::Piece;
use POSIX;

use Encode;
use File::Copy 'copy';

#if( @ARGV > 0 ){ print "@ARGV\n";}
######

######

sub util{ print "util start\n";
}

sub undefMat{
	my $mat = $_[0];
	my $mat_size =@{$_[0]};

	for(my $i=0;$i<$mat_size;$i++){
		for(my $j=0;$j<$mat_size;$j++){
			delete($mat->[$i][$j]);
		}
	}
}

sub printVec{
    print "printVec\n";
    my $i=0;
    foreach my $line (@{$_[0]}){
		print "$i:$line\n";
		$i++
	}
}

sub removeChar{ #print "removeChar start\n";
	#my $string = quotemeta $_[0]; #正規表現の文字の前に\
	my $string = $_[0];
	chomp($string); #改行コードを削除
	$string =~s/[\/\:]//g; #/と:を削除
	$string =~s/\s/-/g; #スペースを-に置換
	return $string;
}

sub utf8tosjis{ #print "utf8tosjis start\n";
	#my $string = quotemeta $_[0]; #正規表現の文字の前に\
	my $string = $_[0];
	#print "befor encode string=$string\n";
	$string = decode('utf8', $string);
	$string = encode('shiftjis', $string);
	#print "string=$string\n";
	return $string;
}
sub sjistoutf8{ #print "sjistoutf8 start\n";
	#my $string = quotemeta $_[0]; #正規表現の文字の前に\
	my $string = $_[0];
	#print "befor encode string=$string\n";
	$string = decode('shiftjis', $string);
	$string = encode('utf8', $string);
	#print "string=$string\n";
	return $string;
}

sub openFileReadmode{ #print "openFileReadmode start\n";
	open ( FILEHANDLE , " < $_[0]" ) or die("error no $_[0]:$!");
	my @array = <FILEHANDLE>;
	close(FILEHANDLE);
	return @array;
}

sub addPeriodforendofArray{ #print "addPeriodforendofArray\n";
	my $arraySize = @{$_[0]};
	for(my $i = 0; $i < $arraySize; $i++){
		${$_[0]}[$i] = "${$_[0]}[$i],";	
	}
}	
sub addStringForEndofArray{ #print "addStringForEndofArray\n";
	my $arraySize = @{$_[0]};
	for(my $i = 0; $i < $arraySize; $i++){
		${$_[0]}[$i] = "${$_[0]}[$i]$_[1]";	
	}
}


#test sub openFileReadmode
#my @array  = &openFileReadmode("util.pl");
#chomp(@array);
#&printVec(\@array);

1;
