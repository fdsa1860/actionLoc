#!/bin/bash

# input file
_db="./videoList.txt"

# output file
o="./output.txt"

if [[ -f "$_db" ]]
then

while IFS= read -r line
    do
#	echo "$line"
	ffprobe -select_streams v -show_streams $line 2>/dev/null | grep nb_frames | sed -e 's/nb_frames=//'
done < $_db
fi
