#!/bin/bash

set -euo pipefail
# FORCE_RESAMPLE will recreate the file, regardless of it meeting the requirements
#  This can be used to strip metadata or fix other file encoding issues
FORCE_RESAMPLE=false
# User-defined variable for temporary file-system size
# This should be larger than your largest sample file!
TMPFS_SIZE=500M

# Check for ffmpeg
if ! command -v ffmpeg &> /dev/null; then
    echo "Error: ffmpeg is required. Please install ffmpeg" >&2
    exit 1
fi

# Check whether a directory was passed on the command line
if [[ $# -ne 1 || ! -d "$1" ]]; then
    echo "Using folder: $0"
    exit 1
fi

# Function to check audio properties
check_audio_properties() {
    local file="$1"
    ffprobe -v error \
            -select_streams a:0 \
            -show_entries stream=codec_name,sample_rate,channels,bits_per_sample \
            -of default=noprint_wrappers=1 \
            "$file"
}

# Process all .wav files in the folder supplied

# First, create a temporary in-memory file-system
  tempdir=$(mktemp -d)

  sudo mount -t tmpfs -o size="$TMPFS_SIZE" tmpfs "$tempdir"

find "$1" -type f \( -name "*.wav" -o -name "*.mp3" \) | while read -r f; do
    f=$(realpath "$f")
    echo "Checking $f..."
    
    # Check adherence to standard when not forcing resample
    # Forcing resample will always recreate the file
    if ! $FORCE_RESAMPLE; then
        properties=$(check_audio_properties "$f" 2>/dev/null)
        codec=$(grep -oP 'codec_name=\K\S+' <<< "$properties")
        samplerate=$(grep -oP 'sample_rate=\K\S+' <<< "$properties")
        bitdepth=$(grep -oP 'bits_per_sample=\K\S+' <<< "$properties")
        
        if [[ "$codec" == "pcm_s16le" && 
              "$samplerate" == "44100" && 
              "$bitdepth" == "16" ]]; then
            echo "File is already Deluge compliant: $f (skipping)"
            if [[ "${f##*.}" != "wav" ]]; then
                echo "RENAME ALERT ============== Renaming $f to ${f%.*}.wav"
                mv "$f" "${f%.*}.wav"
                f="${f%.*}.wav"
                continue
            fi
            continue
        fi
    fi
    
    echo "Processing $f..."
    # Ensure the temporary file is created in the in-memory file-system
    tempfile="$tempdir${f%.*}.tmp.wav"
    mkdir -p "$(dirname "$tempfile")"
    
    # Conversion command
    # Default for the Deluge is 24bit/44.1kHz, but 16bit/44.1kHz is also supported
    # This is plenty for most use cases
    # TODO: make the target format configurable
    if [ ! -f "$f" ]; then
        echo "File not found: $f"
        exit 1
    fi
    if ffmpeg -i "$f" -hide_banner -loglevel error -stats \
                -f wav \
                -flags +bitexact \
                -map_metadata -1 \
                -acodec pcm_s16le \
                -ar 44100 \
                -y \
                "$tempfile" </dev/null; then
        mv -f "$tempfile" "${f%.*}.wav"
        echo "Succesfully processed: ${f%.*}.wav"
    else
        echo "Error while processing $f, skipping!" >&2
        rm -f "$tempfile"
    fi
done

echo "Conversion complete!"

# Clean up the temporary file-system
trap "sudo umount '$tempdir' && rmdir '$tempdir'" EXIT
