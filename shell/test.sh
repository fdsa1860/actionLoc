#!/bin/bash

# input file
_db="./videoList.txt"

# output file
o="./output.txt"

if [[ -f "$_db" ]]
then

while IFS= read -r line
    do
#echo "$line"
    ffmpeg -i $line -vcodec copy -f rawvideo -y /dev/null 2>&1 | tr ^M '\n' | awk '/^frame=/ {print $2}'|tail -n 1
done < $_db
fi
