#!/bin/bash
trap "exit" INT
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "${DIR}" || exit 1

output_resolution="1920:1080"
output_file="output.mp4"
ffmpeg_call="ffmpeg"

# Get the number of voice segments
num_voice_segments=$(ls voice_segments | wc -l)
# Load durations.txt into an array
readarray -t durations < durations.txt
# Escape the colons in the durations
durations=("${durations[@]//:/\\:}")

# Loop over each voice segment
for i in $(seq 0 $((num_voice_segments - 1))); do
    # Add the slide (i+1) formatted with 2 digits to the ffmpeg call
    ffmpeg_call="${ffmpeg_call} -loop 1 -i slides/slide-$(printf "%02d" $((i+1))).png"
    # Add the voice segment to the ffmpeg call
    ffmpeg_call="${ffmpeg_call} -i voice_segments/${i}.wav"
done

# Scale each input to 1080p and trim to 10 seconds
ffmpeg_call="${ffmpeg_call} -filter_complex \""
for i in $(seq 0 $((num_voice_segments - 1))); do
    ffmpeg_call="${ffmpeg_call}[$((2*i))]scale=$output_resolution,trim=duration='${durations[$i]}'[v${i}];"
    ffmpeg_call="${ffmpeg_call}[$((2*i+1)):a]atrim=duration='${durations[$i]}',apad=whole_dur='${durations[$i]}'[a${i}];"
done
# Concatenate the segments
for i in $(seq 0 $((num_voice_segments - 1))); do
    ffmpeg_call="${ffmpeg_call}[v${i}][a${i}]"
done
ffmpeg_call="${ffmpeg_call}concat=n=${num_voice_segments}:v=1:a=1[outv][outa]\""
# Set the map to the output video and audio
ffmpeg_call="${ffmpeg_call} -map \"[outv]\" -map \"[outa]\""

# Limit to 60 seconds
# ffmpeg_call="${ffmpeg_call} -t 60"
# Output at 30 fps
ffmpeg_call="${ffmpeg_call} -r 30"

# Set the codec to libx264 and the audio codec to aac
ffmpeg_call="${ffmpeg_call} -c:v libx264 -c:a aac"
# Set the pixel format to yuv420p and use shortest
ffmpeg_call="${ffmpeg_call} -pix_fmt yuv420p -shortest"
# Set the output file to output.mp4
ffmpeg_call="${ffmpeg_call} -y ${output_file}"
# Run the ffmpeg call
eval "${ffmpeg_call}"
# echo "${ffmpeg_call}"