
echo "test"

if [ $HOST = "Gemini" ]; then
	echo "host is gemini"
fi

isUbuntu=`[ $HOST = "Gemini" ]`
isUbuntuVM=`[ $HOST = "ubuntuVM" ]`
if $isUbuntu; then
	echo "host is gemini2"
fi
if $isUbuntuVM; then
	echo "host is ubuntuVM"
fi
