# slides-voiceover-generator

Convert slides and script into a video with TTS voiceover.<br>
This is a set of bash scripts to help convert a set of slides into a video with a voiceover.<br>
The voiceover is generated using [coqui-ai/TTS](https://github.com/coqui-ai/TTS).<br>
The scripts are designed to be run on a Linux machine with docker, an nvidia gpu, and ffmpeg installed.

## Usage

1. Clone this repository
2. Add a file called `script.txt` and add `slides.pdf`.
   - `script.txt` should contain the script for the voiceover, one line per slide.
   - `slides.pdf` should contain the slides.
3. Run `./extract_slides.sh` to extract the slides into individual images.
4. Run `./generate_voiceover.sh` to generate the voiceover.
5. Run `./initialize_durations` to initialize the durations of each slide.
   - You can tune `durations.txt` to your liking, e.g. for overlay videos.
6. Run `./stitch_video.sh` to combine the slides and voiceover into a video.<br>
   Or use your own video editor software to combine the voiceover into a video.

## Notes
* You can optionally an `overlays.txt` file to add video overlays to the video.<br>
  This should be a txt file where each line has the format:<br>
   `filename;width:height;position_x:position_y;start_overlay_time;end_overlay_time;start_time`<br>
   For example, to put `overlay.mp4` in the top-left corner from time 0s to 10s:<br>
   `overlay.mp4;200:-2:0:0;0:10:0`
