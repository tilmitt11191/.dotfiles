#!/usr/bin/zsh

HOMEDIR=/home/alladmin/puyoQue/personokashinaredel20151028/
cd $HOMEDIR
#iventName=guild_ranking_guild_battle
#iventNamePerson=person_ranking_guild_battle_guild
#campaignID=12005

iventName=person_ranking_sp_item_festival
iventNamePerson=person_ranking_sp_item_festival_guild
campaignID=2038

#iventName=guild_ranking_sp_boss_rush
#iventNamePerson=$iventName
#campaignID=6022

numofPage=11
execNum=$3
#$3=2 getborder

borderlist=(1 10 34 100 334 1000)
#30		1ÇÃç≈å„
#300	10ÇÃç≈å„
#1000	34ÇÃè„Ç©ÇÁ10î‘ñ⁄
#3000	100ÇÃç≈å„
#10000	334ÇÃàÍî‘è„
#30000	1000ÇÃç≈å„

if [ $1 = "thomson" ]; then
	guildID=115783 #thomson
	#userID=12b02d5c13cb3b0a0ed5633c60e23f5a #pachikuri
        userID=4dd9524137cc065dc68c14af1b0c4ea4 #erio

	numofPage=2
elif [ $1 = "doroeri" ]; then
	guildID=197519 #doroeri
	userID=4dd9524137cc065dc68c14af1b0c4ea4 #erio
	numofPage=2
elif [ $1 = "sunrise" ]; then
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

#1-330
if [ $execNum -eq 1 ]; then
	page=0
	until [ $page -ge $numofPage ];
	do
		page=`expr $page + 1`
		if [ $guildID = "null" ]; then
			mkdir -p "api.puyoquest.jp/html/$iventName/"
			#wget -r -l 1 "http://api.puyoquest.jp/html/$iventName/?campaign_id=$campaignID&uid=4dd9524137cc065dc68c14af1b0c4ea4&page=$page" --output-document="api.puyoquest.jp/html/$iventName/_campaign_id=$campaignID&uid=4dd9524137cc065dc68c14af1b0c4ea4&page=$page"
			#:
		else
			mkdir -p "api.puyoquest.jp/html/$iventNamePerson/"
			#wget -r -l 1 "http://api.puyoquest.jp/html/$iventNamePerson/?campaign_id=$campaignID&guild_id=$guildID&$userID&uid=$userID&page=$page" --output-document="api.puyoquest.jp/html/$iventNamePerson/_campaign_id=$campaignID&guild_id=$guildID&uid=4dd9524137cc065dc68c14af1b0c4ea4&page=$page"
			#:
		fi
	done

	if [ $guildID = "null" ]; then
		perl operateIndex.pl $campaignID $numofPage $execNum $guildID $userID $timeSlot $iventName
		#:
	else
		perl operateIndex.pl $campaignID $numofPage $execNum $guildID $userID $timeSlot $iventNamePerson
		#:
	fi
fi

#$3=2 getborder
if [ $execNum -eq 2 ]; then
	date=`date +%Y%m%d%k%M`
	mkdir -p "border/$date/$iventName/"
	for page in $borderlist;do
		echo "wget $pageNum"
	wget -r -l 1 "http://api.puyoquest.jp/html/$iventName/?campaign_id=$campaignID&uid=4dd9524137cc065dc68c14af1b0c4ea4&page=$page" --output-document="border/$date/$iventName/_campaign_id=$campaignID&uid=4dd9524137cc065dc68c14af1b0c4ea4&page=$page"
	done

	#perl operateIndex.pl $campaignID $numofPage $execNum $guildID $userID $timeSlot $iventName

fi


exit 0
