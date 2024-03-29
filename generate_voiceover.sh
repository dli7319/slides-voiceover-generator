#!/bin/bash
trap "exit" INT
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "${DIR}" || exit 1

DOCKER_IMAGE=ghcr.io/coqui-ai/tts:main
DOCKER_IMAGE_CPU=ghcr.io/coqui-ai/tts-cpu:main
MODEL_NAME=tts_models/en/vctk/vits
SPEAKER=p273
CACHE_DIR="${DIR}/cache"
SPEECH_LENGTH="1.0"

script_file="script.txt"
script=$(cat "${script_file}")

user_id=$(id -u)
gpu_support=$(command -v nvidia-smi >/dev/null && echo true || echo false)

docker_gpu_flag=()
if [ "$gpu_support" = true ]; then
    docker_gpu_flag=("--gpus" "all")
else
    echo "No GPU support detected, using CPU-only image"
    DOCKER_IMAGE=$DOCKER_IMAGE_CPU
fi

function run_setup {
    if [ ! -d "${CACHE_DIR}" ]; then
        # Download the model
        mkdir -p "${CACHE_DIR}"
        docker run --rm "${docker_gpu_flag[@]}" \
            -v "${CACHE_DIR}":/root/.local \
            $DOCKER_IMAGE \
            --text "Test" \
            --model_name $MODEL_NAME \
            --speaker_idx $SPEAKER \
            --out_path "/tmp/a.wav"
        docker run --rm "${docker_gpu_flag[@]}" \
            -v "${CACHE_DIR}":/root/.local \
            --entrypoint /bin/bash \
            $DOCKER_IMAGE \
            -c "chown $user_id:$user_id -R /root/.local/"
    fi
    docker run --rm "${docker_gpu_flag[@]}" \
        -v "${CACHE_DIR}":/root/.local \
        --entrypoint /bin/bash \
        $DOCKER_IMAGE \
        -c "find . -name config.json | xargs sed -i '/length_scale/c\        \"length_scale\": $SPEECH_LENGTH,'"
}

function generate_voiceover_line {
    local line_number="$1"
    local line="$2"
    line_number_padded=$(printf "%03d" "$line_number")
    use_cuda=()
    if [ "$gpu_support" = true ]; then
      use_cuda=("--use_cuda" "true")
    fi
    mkdir -p "${DIR}/voice_segments"
    docker run --rm "${docker_gpu_flag[@]}" \
        -v "${DIR}/voice_segments:/root/tts-output" \
        -v "${CACHE_DIR}":/root/.local \
        $DOCKER_IMAGE \
        --text "$line" \
        --model_name $MODEL_NAME \
        --speaker_idx $SPEAKER \
        --out_path "/root/tts-output/$line_number_padded.wav" \
        "${use_cuda[@]}"
    docker run --rm "${docker_gpu_flag[@]}" \
        -v "${DIR}/voice_segments:/root/tts-output" \
        --entrypoint /bin/bash \
        $DOCKER_IMAGE \
        -c "chown $user_id:$user_id -R /root/tts-output/"
}

run_setup
# Loop over each line in the script, outputting the line number and the line itself.
line_number=1
while IFS= read -r line; do
    echo "Line ${line_number}: ${line}"
    generate_voiceover_line "$line_number" "$line"
    line_number=$((line_number + 1))
done <<<"$script"
