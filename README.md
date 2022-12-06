# slides-voiceover-generator

Convert slides and script into a video with TTS voiceover.<br>
This is a set of bash scripts to help convert a set of slides into a video with a voiceover.<br>
The voiceover is generated using [coqui-ai/TTS](https://github.com/coqui-ai/TTS).<br>
The scripts are designed to be run on a Linux machine with docker and ffmpeg installed.

## Usage

1. Clone this repository
2. Add a file called `script.txt` and add `slides.pdf`.
   - `script.txt` should contain the script for the voiceover, one line per slide.
   - `slides.pdf` should contain the slides.
3. Run `./extract_slides.sh` to extract the slides into individual images.
4. Run `./initialize_durations` to initialize the durations of each slide.
   - You can tune `durations.txt` to your liking, e.g. for overlay videos.
5. Run `./generate_voiceover.sh` to generate the voiceover.
