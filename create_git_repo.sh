#!/bin/bash

CURL_EXE=""
if [ "XX${CURL:+1}" = "XX" ]; then
	CURL=curl
	export CURL_EXE=$(which $CURL) >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "This program needs curl executable on your PATH"
		exit
	fi
fi
echo "Using $CURL_EXE as the curl executable"

if [ $# -ne 2 ]; then
	echo "Usage: $0 <token file> <repo_name>"
	echo "Token file format: username:private_token, eg olive:12345A83833F"
	exit
else
	token_file=$1
	repo_name=$2
	if [ -f $token_file ]; then
		token_string=$( cat $token_file )
	else
		echo "Couln't open $token_file"
		exit
	fi
fi


cat <<EOF
Press return to execute:
$CURL_EXE -u "${token_string}" -H "Content-Type:application/json" https://api.github.com/user/repos -d "{ \"name\": \"<${repo_name}>\"}"
EOF
read this
$CURL_EXE -u "${token_string}" -H "Content-Type:application/json" https://api.github.com/user/repos -d "{ \"name\": \"<${repo_name}>\"}"
