#!/usr/bin/perl
package rename;

require 'util.pl';
#util::util();
require 'calcDiff.pl';
#calcDiff::calcDiff();

use strict;
use warnings;
no warnings 'redefine';

use Time::Piece;
use POSIX;

use Encode;
use File::Copy 'copy';

#######

#######

sub rename{ print "renamef start\n";
}

sub getFileNameBefore{ print "getFileNameBefore($_[0])";

}

sub calculateOrderFluctuationRange{ print "calculateOrderFluctuationRange start\n";
	#my $timeSlotofSpeedRate = $_[0];
	return $_[0] * 5; #単位時間あたりの最大変動順位を設定
}

sub openNameFlow{ #print "openNameFlow start\n";
	my $nameFlowFileName= $_[0];
	
	if (!(-e $nameFlowFileName)) {
		open (OUT ,"> $nameFlowFileName"); #空のファイル作成
		close OUT;
	}
	
	return &util::openFileReadmode($nameFlowFileName);
}

sub createNameFlow{ print "createNameFlow start\n";
	my $nameFlowFileName= $_[0];
	my $fileListName = $_[1];
	my $timeSlot = $_[2];
	my $timeSlotofSpeedRate = $_[3];
	
	my @array = &openNameFlow($nameFlowFileName);
	chomp(@array);
	
	#&calcDiff::getCurrentFileName($fileListName);
	&calcDiff::getCurrentFileName($fileListName);

	my $orderFluctuationRange = &calculateOrderFluctuationRange($timeSlotofSpeedRate);
	print "orderFluctuationRange = $orderFluctuationRange\n";

}

#&createNameFlow("data/nameFlowFile.txt","data/null-filelist.txt",1,2);


sub renameandcreateOutput{
	my $output;
	my $t = $_[0];
	my $numofPage = 11;
	my $srcDirName = "";
	my $srcFileName = "";

	#名前重複チェック
		#無限ループ
	my @namelist = ();
	my @numlist = ();

	for(my $i=1;$i<=$numofPage;$i++){
		open ( FILEHANDLE , " < $srcDirName/$srcFileName&page=$i&uid= " ) or die("error :$!");

		my @array = <FILEHANDLE>;
		close(FILEHANDLE);
		my $FlagUser = 0;

		foreach my $line_ (@array){
			if($line_ =~ /"bt_r right"/) {$FlagUser = 1;}
			if($FlagUser){
				if($line_ =~ /rank_user/) {
					$line_ =~ s/<.*?>//g;
					chomp($line_);
					$line_=~ s/\s+//g;
					push(@namelist,$line_);
				}
				if($line_ =~ /progress_icon_b/) {
					$line_ =~ s/<.*?>//g;
					chomp($line_);
					$line_=~ s/\s+//g;
					$line_ =~ s/\D//g;
					push(@numlist,$line_);
				}
			}
		}
	}
	
	my $numofList = @namelist;
	for(my $i=0;$i<$numofList;$i++){
		for(my $j=$i+1;$j<$numofList;$j++){
			if($namelist[$j] eq $namelist[$i]){
				print "overlapped data \[rank$i,$namelist[$i]\] and \[rank$j,$namelist[$j]\]\n";
				print "who is \[rank$i,$namelist[$i]\]?\n";
				while(){
					print "please push 1or2or3 \[1:number/2:new name/3:open namelist\]";
					my $answer = <STDIN>;
					chomp($answer);
					if($answer == 1 ){
						#1:number
						print "111\n";
						last; #whileから抜ける
					}
					if($answer == 2 ){
						#2:new name
						print "222\n";
						last; #whileから抜ける
					}
					if($answer == 3 ){
						#1:open namelist
						print "333\n";
						#`C:\Program\ Files\ \(x86\)\Hidemaru\Hidemaru.exe`;
						#whileから抜けない
					}
					undef($answer);
				}
			}
		}
	}
	&undef_mat(@namelist);
	&undef_mat(@numlist);
	

	#名前変更及び新規名前チェック
		#[number/new name/open namelist]

=comment
	for(my $i=1;$i<=$numofPage;$i++){
		open ( FILEHANDLE , " < $srcDirName/$srcFileName&page=$i&uid= " ) or die("error :$!");
		my @array = <FILEHANDLE>;
		close(FILEHANDLE);
		my $FlagUser = 0;

		foreach $line_ (@array){
			if($line_ =~ /"bt_r right"/) {$FlagUser = 1;}
			if($FlagUser){
				if($line_ =~ /rank_user/) {
					$line_ =~ s/<.*?>//g;
					chomp($line_);
					$line_=~ s/\s+//g;
					$output = "$output$line_";
				}
				if($line_ =~ /progress_icon_b/) {
					$line_ =~ s/<.*?>//g;
					chomp($line_);
					$line_=~ s/\s+//g;
					$line_ =~ s/\D//g;
					$output = "$output,$line_\n";
				}
			}
		}
	}

	$outputfilename = "data/$t.csv";
	open (OUT, "> $outputfilename");
	$output = decode('utf8', $output);
	$output = encode('shiftjis', $output);
	print OUT $output;
	close(OUT);

	open ( FILEHANDLE , " >> data/filelist.txt " );
	print FILEHANDLE "$t\n";
	close(FILEHANDLE);

	undef($FlagUser);
	undef($line_);
	&undef_mat(@array);
	undef($output);
=cut
	
	return $t;
}


1;
