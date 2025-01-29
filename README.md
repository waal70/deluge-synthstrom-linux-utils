
# Synthstrom Deluge utils

Forked from [https://github.com/amiga909/deluge-synthstrom-utils]
Adapted by waal70 to work on Linux systems. Tested on Debian 12 (bookworm)

## Requirements

Have ffmpeg installed on your system
`sudo apt install ffmpeg`

Have at least 500M memory free (for the creation of tmpfs)
Ensure that none of your sample files exceed 500M (or increase tmpfs size otherwise!)

## fix_samples.sh

### Platforms

- Linux (Debian bookworm)

### Want a tidy sample library?

- Get rid of "UNSUPPORTED" messages in the Synthstrom Deluge file browser
- Place this script in the root directory of the SD Card
- Consider a backup before running any write commands
- Supported audio file extensions: .wav
- Will convert to 16bit/44100Hz. Set in-script variable to force resampling, which is sometimes needed

### Use cases

- Fix samples
`sh fix_samples.sh ./Loops/Downloads/`

### Options
