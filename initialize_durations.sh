#!/bin/bash
trap "exit" INT
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "${DIR}" || exit 1

duration_file=durations.txt

# Get the list of files in voice_segments/
voice_files=$(ls voice_segments)
# Sort the voice files
voice_files=$(echo "$voice_files" | tr " " " " | sort -n)
# Remove the durations.txt file if it exists
if [ -f $duration_file ]; then
    rm $duration_file
fi
# Loop over audio files in voice_segments/
for file in $voice_files; do
    # Get the duration of the file
    duration=$(ffmpeg -i voice_segments/$file 2>&1 | grep "Duration" | cut -d ' ' -f 4 | sed s/,//)
    echo $duration >>$duration_file
done
