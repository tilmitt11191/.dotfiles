
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

#if [ "$(uname)" = "CYGWIN_NT-10.0" ];then
#UNAME="$(uname)"
#if [["$UNAME" == "CYGWIN"* ]];then
case "$(uname)" in
CYGWIN*)
	echo "this is cygwin"
esac

TEST="test1234"
echo $TEST
if [[ $TEST == *"12"* ]]
then
    echo $TEST" is ok"
fi
