#!/usr/bin/bash
mech_dump=$( which mech-dump  | sed 's#/cygdrive/c#C:#' )
plink=" -user=IDXXXXX -password=XXXXXID $link"

recurse_link(){
 url=$1
 for link in $( perl64 $mech_dump $plink --links $url | egrep -v 'disclaimer.html|termsofuse.html|edisclaimer.html|privacypolicy.html' ); do
	if [ "XX$link" != "XX" ]; then
		if [[ $link = *forex-trading*500* ]]; then
			plink=" -user=IDXXXXX -password=XXXXXID $link"
			echo "recurse $plink"; read this
			recurse_link $plink
		fi
		if [[ $link = *forex-trading* ]]; then
			echo "recurse $link"; read this
			recurse_link $link
		fi
	fi
 done
}
recurse_link $1


