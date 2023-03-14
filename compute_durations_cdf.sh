#!/bin/bash

output_file="durations_cdf.txt"

# remove output file if it exists
if [ -f $output_file ]; then
  rm $output_file
fi

# initialize cumulative sum to 0
cumulative_sum=0.0
# read each line of the file
while read line; do
  # convert duration to a floating-point number of seconds
  timestamp=$(echo "$line" | awk -F: '{ print ($1 * 3600) + ($2 * 60) + $3 }')
  # echo $timestamp

  # add duration's timestamp to cumulative sum
  cumulative_sum=$(echo "$cumulative_sum + $timestamp" | bc)
  echo "$cumulative_sum" >> $output_file
  
done < durations.txt
