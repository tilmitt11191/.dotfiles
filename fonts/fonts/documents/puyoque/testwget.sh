#!/bin/bash

HOMEDIR=/home/alladmin/f/game/puyoQue/guildmisia20150121/test

cd $HOMEDIR

iventName=guild_ranking_sp_boss_rush
campaignID=6018
numofPage=11
execNum=$3

if [ $1 == "thomson" ]; then
	guildID=115783 #thomson
	userID=12b02d5c13cb3b0a0ed5633c60e23f5a #pachikuri
	numofPage=2
elif [ $1 == "doroeri" ]; then
	guildID=197519 #doroeri
	userID=4dd9524137cc065dc68c14af1b0c4ea4 #erio
	numofPage=2
elif [ $1 == "sunrise" ]; then
	guildID=27625 #sunrise
	userID=3871c44250f7e4ad1b6686d44cbc03c5 #melt
	numofPage=2
else
	guildID=null
	userID=4dd9524137cc065dc68c14af1b0c4ea4
fi

if [ $2 -gt 0 ]; then
	timeSlot=$2
else
	timeSlot="null"
fi

if [ $execNum -eq 1 ]; then
page=0
until [ $page -ge $numofPage ];
do
page=`expr $page + 1`
if [ $guildID == "null" ]; then
wget -r -l 1  "http://api.puyoquest.jp/html/$iventName/?campaign_id=$campaignID&uid=4dd9524137cc065dc68c14af1b0c4ea4&page=$page"
:
else
wget -r -l 1 http://api.puyoquest.jp/html/"$iventName"_guild/?campaign_id=$campaignID"&"guild_id=$guildID"&"uid=$userID"&"page=$page
:
fi
done
fi

#perl operateIndex.pl $campaignID $numofPage $execNum $guildID $userID $timeSlot $iventName
