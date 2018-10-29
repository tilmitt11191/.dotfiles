#!/usr/bin/env bash

INITIALDIR=`sudo pwd`
cd `dirname $0`

echo "Swap caps for ctrl"
echo "XKBOPTIONS=\"ctrl:nocaps\"" | sudo tee -a /etc/default/keyboard 2>&1 >/dev/null

cd $INITIALDIR
true
