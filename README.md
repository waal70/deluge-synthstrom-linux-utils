
# Synthstrom Deluge utils

Forked from [https://github.com/amiga909/deluge-synthstrom-utils]
Adapted by waal70 to work on Linux systems. Tested on Debian 12 (bookworm)

## Requirements

Have ffmpeg installed on your system
''''sudo apt install ffmpeg

## samplefixer.sh

### Platforms

- Linux (Debian bookworm)

### Want a tidy sample library?

- Get rid of "UNSUPPORTED" messages in the Synthstrom Deluge file browser
- Place this script in the root directory of the SD Card
- Consider a backup before running any write commands
- Supported audio file extensions: .wav, .aif, .aiff
- Will convert to 16bit/44100Hz. Use --resample to force resampling, which is sometimes needed

### Use cases

- Analyze all data:
`sh samplefixer.sh convert_clean`

- Fix all data
`sh samplefixer.sh convert_clean_write`

### Options

Default path is the Deluge SAMPLES folder. You may pass a directory as an optional parameter. Pass it as relative path, e.g. `sh samplefixer.sh clean RESAMPLE/`, to narrow the search space. 

- **convert [PATH]**
List WAV files below 44kHz. Inspect for fishy data formats as well.

- **clean [PATH]**
List non-audio files and WAV samples Synthstrom Deluge might not be able to load.

- **convert_write [PATH]**
Convert WAV files lower than 44kHz to 44kHz/16bit. No backup! Attention, disk usage might increase a lot.

- **clean_write [PATH]**
Delete non audio files and WAV samples Synthstrom Deluge might not be able to load. No backup!
