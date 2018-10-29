#!/usr/bin/env bash

INITIALDIR=`sudo pwd`
cd `dirname $0`


echo -n "Swap caps for ctrl? [Y/n] default[Y]:"
read ANSWER

case $ANSWER in
	"N" | "n" | "no" | "No" | "NO" ) SWAP_KEY=false;;
	* ) SWAP_KEY=true;;
esac

if "${SWAP_KEY}" ; then
	bash lib/keyswap.sh
fi

exit 0