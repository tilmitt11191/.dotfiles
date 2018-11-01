#!/usr/bin/perl
package calcDiff;

require 'util.pl';
#util::util();
require 'rename.pl';
#rename::rename();

use strict;
use warnings;

use Time::Piece;
use POSIX;

use Encode;
use File::Copy 'copy';

#######

#######

sub calcDiff{ #print "calcDiff start\n";
}

sub getCurrentFileName{ print "getCurrentFileName\n";
	my $fileListName = $_[0];
	my @fileList = &util::openFileReadmode($fileListName);
	chomp(@fileList);
	&util::printVec(\@fileList);
}

sub calcDefeatTime{ #print "calcDefeatTime\n" ;
	my $seriesOfDefeats = $_[0];
	my $seriesOfDefeatTime = $_[1];
	my $timeSlotofSpeedRate = $_[2];
	
	chomp($seriesOfDefeats);
	my @defeat= split(/,/,$seriesOfDefeats);
	my $numOfDefeats = @defeat;
	chomp($seriesOfDefeatTime);
	my @time = split(/,/,$seriesOfDefeatTime);
	my $numOfTime = @time;

	if($numOfDefeats <=3){
		return "$seriesOfDefeatTime"."$timeSlotofSpeedRate,\n";
	}
	elsif($defeat[$numOfDefeats - 2] eq $defeat[$numOfDefeats-1]){
		my $defeatTime = $time[$numOfTime-1] + $timeSlotofSpeedRate;
		return "$seriesOfDefeatTime"."$defeatTime,\n";
	}
	elsif($defeat[$numOfDefeats-2] < $defeat[$numOfDefeats-1]){
		my $defeatTime = $timeSlotofSpeedRate / ( $defeat[$numOfDefeats-1] - $defeat[$numOfDefeats-2]);
		return "$seriesOfDefeatTime"."$defeatTime,\n";
	}		
	else{print "ERROR at calcDefeatTime\n"}
}

sub calcAverageDefeatTime{  #print "calcAverageDefeatTime\n";
	my $seriesOfDefeats = $_[0];
	my $seriesOfAverageDefeatTime = $_[1];
	my $timeSlotofSpeedRate = $_[2];
	
	chomp($seriesOfDefeats);
	my @defeat= split(/,/,$seriesOfDefeats);
	my $numOfDefeats = @defeat;
	chomp($seriesOfAverageDefeatTime);
	my @average = split(/,/,$seriesOfAverageDefeatTime);
	my $numOfAverage = @average;

	if($numOfDefeats <=3){
		return "$seriesOfAverageDefeatTime"."-,\n";
	}	
	if($defeat[$numOfDefeats-1] - $defeat[2] < 5){
		return "$seriesOfAverageDefeatTime"."-,\n";
	}
	
	my $i = 2;
	foreach (@defeat){
		if($defeat[$numOfDefeats-1] - $defeat[$numOfDefeats - $i] >= 5){
			#my $averageTime =  ($defeat[$numOfDefeats-1] - $defeat[$numOfDefeats - $i]) / (($i-1) * $timeSlotofSpeedRate);
			my $averageTime = ($i - 1)  * $timeSlotofSpeedRate / 5 ;
			return "$seriesOfAverageDefeatTime"."$averageTime,\n";
		}
		elsif($i == $numOfDefeats){
			return "$seriesOfAverageDefeatTime"."0,\n";
		}
		$i ++;
	}
	print "ERROR calcAverageDefeatTime\n";
}


1;
