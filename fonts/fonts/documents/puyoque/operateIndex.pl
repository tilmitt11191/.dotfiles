#!/usr/bin/perl
use strict;
use warnings;

require 'calcDiff.pl';
#calcDiff::calcDiff();
require 'util.pl';
#util::util();
require 'rename.pl';
#rename::rename();
use Time::Piece;
use POSIX;

use Encode;
use File::Copy 'copy';

#if( @ARGV > 0 ){ print "@ARGV\n";}

######
my $campaignID = $ARGV[0];
my $numofPage = $ARGV[1];
my $guildID = $ARGV[3];
my $userID = $ARGV[4];
my $timeSlotofSpeedRate = $ARGV[5];
my $iventName = $ARGV[6];

my $srcDirName = "";
my $srcFileName = "";
if($guildID eq "null"){
	$srcDirName ="api.puyoquest.jp/html/$iventName";
	$srcFileName = "_campaign_id=$campaignID&uid=$userID";
}
else{
	$srcDirName ="api.puyoquest.jp/html/${iventName}";
	$srcFileName = "_campaign_id=$campaignID&guild_id=$guildID&uid=$userID";
}
#my @pickUpRank = (1,300,1000,3000,10000,30000);
my @pickUpRank = ();
my $timeUnit = 5; #min

######
my $pickedUpTopGuildIdentifier = "pickUpTU";
my $pickedUpBottomGuildIdentifier = "pickUpBU";
my $pickedUpRankIdentifier = "pickUpRank";
my $rawDataIdentifier = "ranking";

#####
my $GUILDIVENT = "guild_ranking_sp_boss_rush";
my $PERSON = "person_ranking_sp_item_festival";
my $PERSONGUILD = "person_ranking_sp_item_festival_guild";
my $GUILDBATTLE = "guild_ranking_guild_battle";
my $GUILDBATTLEPERSON = "person_ranking_guild_battle_guild";

######
my $fileListName = "data/$guildID-filelist.txt";
my $nameFlowFilename = "data/$guildID-nameFlow.txt";
my $mergedOutputName = "data/$guildID-output.csv";

######
my $TRUE = 1;
my $FALSE = 0;



sub getNewestFileName{ #print "getNewewstFileName start\n";	
	my @array = util::openFileReadmode($fileListName);
	my $newestFileName = pop @array;
	chomp($newestFileName);
	return $newestFileName;
}

#topPickUpName.txtの内容を配列化しリファレンスを返す
sub getTopPickUpName{ #print "getTopPickUpName start\n";
	my $srcFileName = "./profile_topPickUpName.txt";
	my @array = util::openFileReadmode($srcFileName);
	chomp(@array);
	util::addStringForEndofArray(\@array,", ,\n,,\n,,");
	return \@array;
}

#bottomPickUpName.txtの内容を配列化しリファレンスを返す
sub getBottomPickUpName{ #print "getBottomPickUpName start\n";
	my $srcFileName = "./profile_bottomPickUpName.txt";
	my @array = util::openFileReadmode($srcFileName);
	chomp(@array);
	return \@array;
}

sub checkChangedName{
}

#ランキングをすべて取得して配列化しリファレンスを返す
#要素は 順位,ギルド名,数
sub getRanking{
	my @output = ();
	my $rank = 0;

	for(my $i=1;$i<=$numofPage;$i++){
		my @array = util::openFileReadmode("$srcDirName/$srcFileName&page=$i");
		my $FlagUser = 0;
		my $FlagDani = 0;
		my $userName = "";

		foreach my $line_ (@array){
			if($line_ =~ /"ranking_area_index"/) {$FlagUser = 1;}
			if($line_ =~/td id=\"dani\"/) {$FlagDani = 1;} #skip dani
			if($FlagDani && $line_ =~/td id=\"name\"/) {$FlagDani = 0;}
			if($FlagUser && !$FlagDani){
				if($line_ =~ /rank_user/) {
					$rank++;
					$line_ =~ s/<.*?>//g;
					$line_=~ s/\s+//g;
					$line_ =~ s/,//g; #カンマを削除
					chomp($line_);
					$userName = "$line_";
				}
				if($line_ =~ /progress_icon_b/) {
					$line_ =~ s/<.*?>//g;
					$line_=~ s/\s+//g;
					$line_ =~ s/\D//g;
					chomp($line_);
					$output[$rank-1] = "$rank,$line_,$userName";
				}
			}
		}
	}
	
	return \@output;
}

sub createOutput{ #print "createOutput start\n";
	my $output = "";
    foreach my $argv (@_) { 
    	foreach my $line_ (@{$argv}){
    		$output = "$output$line_\n";
    	}
    }
    return $output;
}

sub outputAll{ #print "outputAll start\n";
	my $output;
	my $t = $_[0];

	my @pickedUpTopGuildIdentifier = ($pickedUpTopGuildIdentifier);
	my @pickedUpBottomGuildIdentifier = ($pickedUpBottomGuildIdentifier);
	my @pickedUpRankIdentifier = ($pickedUpRankIdentifier);
	my @rawDataIdentifier = ($rawDataIdentifier);
	
	$output = &createOutput(\@pickedUpTopGuildIdentifier,&getTopPickUpName(),
		\@pickedUpRankIdentifier,
		\@pickUpRank,
		\@rawDataIdentifier,
		&getRanking(),
		\@pickedUpBottomGuildIdentifier,&getBottomPickUpName()
		);
	$output = ",$t\n$output"; #時刻を追加
	
	$t =~s/[\/\:]//g; #/と:を削除
	$t =~s/\s/-/g; #スペースを-に置換
	my $outputfilename = "data/$guildID-$t.csv";

	open (OUT, "> $outputfilename");
	$output = util::utf8tosjis($output);
	print OUT $output;
	close(OUT);

	open ( FILEHANDLE , " >> data/$guildID-filelist.txt " );
	print FILEHANDLE "$guildID-$t\n";
	close(FILEHANDLE);
	
	return $t;
}

sub removeUserName{
	pop(@{$_[0]});
}

sub createNameList{
	my $output;
	my $rank = 0;

	for(my $i=1;$i<=$numofPage;$i++){
		open ( FILEHANDLE , " < $srcDirName/$srcFileName&page=$i&uid= " ) or die("error :$!");
		my @array = <FILEHANDLE>;
		close(FILEHANDLE);
		my $FlagUser = 0;
	
		foreach my $line_ (@array){
			if($line_ =~ /"bt_r right"/) {$FlagUser = 1;}
			if($FlagUser){
				if($line_ =~ /rank_user/) {
					$rank++;
					$line_ =~ s/<.*?>//g;
					chomp($line_);
					$line_=~ s/\s+//g;
					$output = "$output xxxxxxxx$rank,$line_\n";
				}
			}
		}
	}

	$output = decode('utf8', $output);
	$output = encode('shiftjis', $output);

	my $t = $_[0];
	$t =~s/[\/\:]//g; #/と:を削除
	$t =~s/\s/-/g; #スペースを-に置換
	my $outputfilename = "data/$guildID-$t.txt";
	
	open (OUT, "> $outputfilename");
	print OUT $output;
	close(OUT);

	$outputfilename = "data/$guildID-namelist.txt";	
	open (OUT, "> $outputfilename");
	print OUT $output;
	close(OUT);
}

sub createMergedOutput{ #print "createMergedOutput start\n";
	my $newestFileName = &getNewestFileName();
	$newestFileName = "data/$newestFileName.csv";
	copy $newestFileName, $mergedOutputName;
}

sub addPickedUpTopGuild{ #print "addPickedUpTopGuild\n";
	my @mergedOutput = @{$_[0]};
	my $line = $_[1];
	my $i = $_[2];
	my $calcMode = $_[3];
	
	my @merged = split(/,/,util::sjistoutf8(util::removeChar($mergedOutput[$i])));
	my $numOfMerged = @merged;
	my @timeseries = split(/,/,util::sjistoutf8($line));
	
	if(($line eq $pickedUpTopGuildIdentifier) ){	
		return @mergedOutput;
	}
	
	my $newestFileName = &getNewestFileName();
	$newestFileName = "data/$newestFileName.csv";
	my @newestFile = util::openFileReadmode($newestFileName);
	

	if($calcMode == 0){
		my $findNameFlag = $FALSE;
		foreach my $line_ (@newestFile){
			$findNameFlag = $FALSE;
			my @array = split(/,/,$line_);
			my $arraySize = @array;
			#if($arraySize != 3){ print "arraySize=$arraySize ERROR at addPickedUpTopGuild\n"; exit(1);}
			#↓$arraySizeではなく$pickedUpTopGuildIdentifierで分岐が望ましい
			if($arraySize == 3){
				$array[2] = util::sjistoutf8($array[2]);
				chomp($array[2]);
				$array[2] =~ s/<.*?>//g;
				$array[2]=~ s/\s+//g;
				$array[2]=~ s/,//g; #カンマを削除
				#↓$merged[0]ではなくTopPickUpNameとの照合が望ましい
				if($array[2] =~ /$merged[0]/){
					$mergedOutput[$i] = "";
					foreach my $line_ (@merged){
						$line_ = util::utf8tosjis($line_);
						$mergedOutput[$i] = "$mergedOutput[$i],$line_";
					}
				$mergedOutput[$i] = "$mergedOutput[$i],$array[1]";
				substr($mergedOutput[$i],0,1) = "";
				$mergedOutput[$i] = "$mergedOutput[$i],\n";
				$findNameFlag = $TRUE;
				last;
				}
			}
		}
		if(!$findNameFlag){ #名前がランキングに無かった場合空白セル
			$mergedOutput[$i] = "";
			foreach my $line_ (@merged){
				$line_ = util::utf8tosjis($line_);
				$mergedOutput[$i] = "$mergedOutput[$i],$line_";
			}
			$mergedOutput[$i] = "$mergedOutput[$i],outofrank,";
			substr($mergedOutput[$i],0,1) = "";
			$mergedOutput[$i] = "$mergedOutput[$i],\n";
		}
	}	
	elsif($calcMode == 1){
		chomp($mergedOutput[$i]);
		if($i-1 <= 0){ print "ERROR at addPickedUpTopGuild1\n"; return 1;}
		$mergedOutput[$i] = calcDiff::calcDefeatTime(
			$mergedOutput[$i-1],
			$mergedOutput[$i], 
			$timeSlotofSpeedRate);
	}
	elsif($calcMode == 2){
		chomp($mergedOutput[$i]);
		if($i-2 <= 0){ print  "ERROR at addPickedUpTopGuild1\n"; return 1;}
		$mergedOutput[$i] = calcDiff::calcAverageDefeatTime(
		$mergedOutput[$i-2],
		$mergedOutput[$i],
		$timeSlotofSpeedRate);
	}
	return @mergedOutput;
}

sub addRawData{ #print "addRawData start\n";
	my @mergedOutput = @{$_[0]};
	my $line = $_[1];
	my $i = $_[2];

	my @merged = split(/,/,$mergedOutput[$i]);
	&removeUserName(\@merged);

	my @timeseries = split(/,/,$line);
	shift(@timeseries);
	
	$mergedOutput[$i] = "";
	foreach(@merged){$mergedOutput[$i] = "$mergedOutput[$i],$_";}
	foreach(@timeseries){$mergedOutput[$i] = "$mergedOutput[$i],$_";}
	substr($mergedOutput[$i],0,1) = "";
	$mergedOutput[$i] = "$mergedOutput[$i]\n";
	
	return @mergedOutput;
}
	
sub mergeTimeSeriesPlotintoAll{ #print "mergeTimeSeriesPlotintoAll start\n";
	if(-f $mergedOutputName){}
	else{ &createMergedOutput;return 0;}

	my $newestFileName = &getNewestFileName();
	$newestFileName = "data/$newestFileName.csv";
	my @timeSeriesPlot = util::openFileReadmode($newestFileName);
	my @mergedOutput = util::openFileReadmode($mergedOutputName);

	my $i = 0;
	my $mode = "";
	my $calcMode = 0;

	chomp($mergedOutput[0]);
	$mergedOutput[0] = "$mergedOutput[0]$timeSeriesPlot[0]";

	foreach my $line_ (@timeSeriesPlot){
		$line_ = &util::removeChar($line_);	

		if($line_ eq $pickedUpTopGuildIdentifier){ $mode = $pickedUpTopGuildIdentifier;}
		elsif($line_ eq $pickedUpBottomGuildIdentifier){ $mode = $pickedUpBottomGuildIdentifier;} 
		elsif($line_ eq $pickedUpRankIdentifier){ $mode = $pickedUpRankIdentifier;}
		elsif($line_ eq $rawDataIdentifier){ $mode = $rawDataIdentifier;}
		
		if($mode eq $pickedUpTopGuildIdentifier ){
			my $element = $line_;
			$element =~s/\s//g; #スペースを削除
			$element =~ s/,//g; #カンマを削除
			if($element ne ""){ 
				$calcMode = 0;
				@mergedOutput =  &addPickedUpTopGuild(\@mergedOutput,$line_,$i,$calcMode);
			}
			elsif(($calcMode == 0 or $calcMode == 1) and $iventName eq $GUILDIVENT){
				$calcMode = 1;
				@mergedOutput = &addPickedUpTopGuild(\@mergedOutput,$line_,$i,$calcMode);
				$calcMode = 2;
			}
			elsif(($calcMode == 0 or $calcMode == 1) and $iventName eq $GUILDBATTLE){
				$calcMode = 1;
				@mergedOutput = &addPickedUpTopGuild(\@mergedOutput,$line_,$i,$calcMode);
				$calcMode = 2;
			}
			elsif(($calcMode == 0 or $calcMode == 1) and $iventName eq $GUILDBATTLEPERSON){
				$calcMode = 1;
				@mergedOutput = &addPickedUpTopGuild(\@mergedOutput,$line_,$i,$calcMode);
				$calcMode = 2;
			}
			elsif($calcMode == 2 and $iventName eq $GUILDIVENT){
				@mergedOutput = &addPickedUpTopGuild(\@mergedOutput,$line_,$i,$calcMode);
				$calcMode = 1;
			}
			elsif(($calcMode == 0 or $calcMode == 1) and $iventName eq $PERSON){
				$calcMode = 1;
				@mergedOutput = &addPickedUpTopGuild(\@mergedOutput,$line_,$i,$calcMode);
				$calcMode = 2;
			}
			elsif($calcMode == 2 and $iventName eq $PERSON){
				@mergedOutput = &addPickedUpTopGuild(\@mergedOutput,$line_,$i,$calcMode);
				$calcMode = 1;
			}
			elsif(($calcMode == 0 or $calcMode == 1) and $iventName eq $PERSONGUILD){
				$calcMode = 1;
				@mergedOutput = &addPickedUpTopGuild(\@mergedOutput,$line_,$i,$calcMode);
				$calcMode = 2;
			}
			elsif($calcMode == 2 and $iventName eq $PERSONGUILD){
				@mergedOutput = &addPickedUpTopGuild(\@mergedOutput,$line_,$i,$calcMode);
				$calcMode = 1;
			}
			elsif($calcMode == 2 and $iventName eq $GUILDBATTLE){
				@mergedOutput = &addPickedUpTopGuild(\@mergedOutput,$line_,$i,$calcMode);
				$calcMode = 1;			
			}
			elsif($calcMode == 2 and $iventName eq $GUILDBATTLEPERSON){
				@mergedOutput = &addPickedUpTopGuild(\@mergedOutput,$line_,$i,$calcMode);
				$calcMode = 1;			
			}
			else{ print "IVENTMODE ERROR [IVENTNAME=$iventName]\n"; return 1;}
		}			
				
		if($mode eq $rawDataIdentifier){
			@mergedOutput =  &addRawData(\@mergedOutput,$line_,$i);}

		$i++;
	}
	open ( OUT , " > $mergedOutputName " );
	print OUT @mergedOutput;
	close(OUT);
}

#####

my $t = POSIX::strftime "%Y/%m/%d %H:%M:%S", localtime(time);
if($ARGV[2]==1){
	&outputAll($t);
	if (!(-e  $mergedOutputName)) {&createMergedOutput();}
	else{&mergeTimeSeriesPlotintoAll();}
}
if($ARGV[2]==2){ ; }

#&util::printVec(&getTopPickUpName());
#&util::printVec(&getBottomPickUpName());
#&util::printVec(&getRanking);
print "\noperateIndex.pl processed by erico\n";
