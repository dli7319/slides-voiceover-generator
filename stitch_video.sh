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
readarray -t durations <durations.txt
# Escape the colons in the durations
durations=("${durations[@]//:/\\:}")
# Load overlays file into an array
readarray -t overlays <overlays.txt
# Remove empty lines and comments
overlays=("${overlays[@]// /}")
overlays=("${overlays[@]//\#*}")
# Get the number of overlays
num_overlays=${#overlays[@]}

# Loop over each voice segment
for i in $(seq 0 $((num_voice_segments - 1))); do
    # Add the slide (i+1) formatted with 2 digits to the ffmpeg call
    ffmpeg_call="${ffmpeg_call} -loop 1 -i slides/slide-$(printf "%02d" $((i + 1))).png"
    # Add the voice segment to the ffmpeg call
    ffmpeg_call="${ffmpeg_call} -i voice_segments/${i}.wav"
done

# For each overlay, add the overlay to the ffmpeg call
for i in $(seq 0 $((num_overlays - 1))); do
    # Get the overlay for this slide and split on semicolons
    IFS=';' read -ra my_overlay <<<"${overlays[$i]}"
    start_time="${my_overlay[5]}"
    # If start_time is empty, set it to 0
    if [ -z "$start_time" ]; then
        start_time="0"
    fi
    # Add the overlay to the ffmpeg call
    ffmpeg_call="${ffmpeg_call} -ss $start_time -i ${my_overlay[0]}"
done

# Scale each input to 1080p and trim to 10 seconds
ffmpeg_call="${ffmpeg_call} -filter_complex \""
for i in $(seq 0 $((num_voice_segments - 1))); do
    ffmpeg_call="${ffmpeg_call}[$((2 * i))]scale=$output_resolution,trim=duration='${durations[$i]}'[v${i}];"
    ffmpeg_call="${ffmpeg_call}[$((2 * i + 1)):a]atrim=duration='${durations[$i]}',apad=whole_dur='${durations[$i]}'[a${i}];"
done
# Concatenate the segments
for i in $(seq 0 $((num_voice_segments - 1))); do
    ffmpeg_call="${ffmpeg_call}[v${i}][a${i}]"
done

# If we have overlays, add them to the video
if [ $num_overlays -gt 0 ]; then
    ffmpeg_call="${ffmpeg_call}concat=n=${num_voice_segments}:v=1:a=1[outv_0][outa]"
    # Loop over each overlay
    for i in $(seq 0 $((num_overlays - 1))); do
        # Get the overlay for this slide and split on semicolons
        IFS=';' read -ra my_overlay <<<"${overlays[$i]}"
        overlay_resolution="${my_overlay[1]}"
        overlay_position="${my_overlay[2]}"
        overlay_start="${my_overlay[3]}"
        overlay_end="${my_overlay[4]}"
        # Add the overlay to the ffmpeg call
        ffmpeg_call="${ffmpeg_call};[$((2*num_voice_segments + i))]scale=$overlay_resolution,setpts=PTS-STARTPTS+$overlay_start/TB[overlay_${i}];[outv_$i][overlay_${i}]overlay=${overlay_position}:enable='between(t\,$overlay_start\,$overlay_end)'[outv_$((i+1))]"
    done
    # Set the map to the output video and audio
    ffmpeg_call="${ffmpeg_call}\" -map \"[outv_$num_overlays]\" -map \"[outa]\""
else
    ffmpeg_call="${ffmpeg_call}concat=n=${num_voice_segments}:v=1:a=1[outv][outa]\""
    # Set the map to the output video and audio
    ffmpeg_call="${ffmpeg_call} -map \"[outv]\" -map \"[outa]\""
fi

# Limit to 60 seconds
# ffmpeg_call="${ffmpeg_call} -t 6"
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
