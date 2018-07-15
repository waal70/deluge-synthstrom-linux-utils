#! /bin/sh

#### 
# Uses afconvert instead of ffmpeg
####


# hack to handle spaces in filenames
IFS='
'
set -f

# globals
ARG1_runmode="$1"
if [ "$ARG1_runmode" = "" ]; then
	ARG1_runmode="help" 
fi
af16bit44hz="LEI16@44100"
af8bit44hz="UI8@44100"
# Deluge records 44hz/24bit
af24bit44hz="LEI24@44100"
af32bit44hz="LEI32@44100"
af64bit44hz="LEF64@44100"
# default: 16 bit is usually enough
targetFormat="LEI16@44100"

lB="-----------------"
minSampleRate=44100
totalIncrease=0
count=0
convCount=0
skippedCount=0 
rootDirSet="0"


libcheck() {
	if ! [ -x "$(command -v afinfo)" ]; then
		echo 'Error: afinfo is not installed.'
	   	exit 1
	fi
	if ! [ -x "$(command -v afconvert)" ]; then
		echo 'Error: afconvert is not installed.'  
	  	exit 1
	fi
} 
isRootDir() {
	if  ! [ -d "${PWD}/SAMPLES/RESAMPLE" ]; then
		echo "Note: If you want to process all files, place script in root directory of SD card."
		echo "$lB"
	else 
		cd "${PWD}/SAMPLES" || exit
		rootDirSet="1"
	fi
}
clean(){
	if [ "$rootDirSet" = "0" ]; then
		echo "Exit. Safety measure. You gotta be in the Deluge root directory." 
		exit 1
	fi

	total=0
	echo "Listing non-audio samples by extension."
	echo "Allowed file extensions: .wav, .aif, .aiff"
	
	for f in $(find ./ -type f -not -iname '*.wav' -and -not -iname '*.aif' -and -not -iname '*.aiff'); do
		echo "$lB"

		size=$(stat -f%z "$f") 
		size=$(($size / 1024))
		displayPath="$(echo "$f" | sed -E 's/\.\/\///g')"

		total=$((size+total))
		echo "/${displayPath} | $size KB "
		if [ "$ARG1_runmode" = "clean-fix" ]; then
			rm "$f"
			echo "Deleted."
		fi
	done

	echo "$lB"
	echo "Testing audio files."
	for f in $(find ./ -type f -iname '*.wav' -or -iname '*.aif' -or -iname '*.aiff'); do

		size=$(stat -f%z "$f") 
		size=$(($size / 1024))
		displayPath="$(echo "$f" | sed -E 's/\.\/\///g')"

		isValid="1"
		{  
	    	afInfo="$(afinfo "$f")"
	    	# Regular afinfo output containts a file type
	    	checkOutput="$(echo "$afInfo" | grep -o 'File type ID:')"
			if [ "$checkOutput" = "" ]; then
				isValid="0"
				echo "$afInfo"
			fi
	    	
		} || {  
			isValid="0"
		}

		if [ "$isValid" = "0" ]; then
			echo "$lB"
	 		echo "Error. Invalid audio file."
		 	total=$((size+total))
			echo "/${displayPath} | $size KB "
			if [ "$ARG1_runmode" = "clean-fix" ]; then
				rm "$f"
				echo "Deleted."
			fi	
		fi
	done

	totalMb=$(($total / 1024))
	echo "$lB"
	echo "Total disk space usage: $total KB | $totalMb MB"
	echo "Execute script with clean-fix to remove all listed files."
}


convert(){
	for f in $(find ./ -type f -iname '*.wav'); do
		count=$((count+1))
		displayPath="$(echo "$f" | sed -E 's/\.\/\///g')"

		{  
		    afInfo="$(afinfo "$f")"

		} || {  
			echo "$lB"
		 	echo "Error. Invalid file. Skip $displayPath"
			skippedCount=$((skippedCount+1))
			continue 
		}

		dataFormat="$(echo "$afInfo" | grep -o 'Data format: .*')"
		bitDepthInfo="$(echo "$afInfo" | grep -o 'source bit depth: I.*')"
		sampleRate="$(echo "$dataFormat"| grep -o '[0-9]\{3,7\} Hz' | grep -o '[0-9]\{3,7\}' )"
		bitDepth="$(echo "$bitDepthInfo"| grep -o '[0-9]\{1,2\}')"
		fishyMp3="$(echo "$dataFormat"| grep -o 'mp3')"
		fishyBits="$(echo "$dataFormat" | grep -o ' 0 bits')"

		if [[ $sampleRate -lt $minSampleRate || $fishyMp3 != "" || $fishyBits != "" ]]; then
			size=$(stat -f%z "$f") 
			sizeBefore=$(($size / 1024)) 

			echo "$lB"
			echo "/${displayPath} | $sizeBefore KB | $sampleRate Hz"
	 
			if [ "$fishyMp3" != "" ]; then
				echo "Fishy MP3 Codec detected:"
				echo "$(echo "$dataFormat" | sed -e 's/ //g')"  
			fi

			if [ "$fishyBits" != "" ]; then
				echo "Fishy bits/channel detected:"
				echo "$(echo "$dataFormat" | sed -e 's/ //g')" 
			fi

			if [ "$ARG1_runmode" = "fix" ]; then
				convCount=$((convCount+1))
				if [ "$bitDepth" = "16" ]; then
					targetFormat="$af16bit44hz"
				elif [ "$bitDepth" = "8" ]; then
					targetFormat="$af8bit44hz"
				elif [ "$bitDepth" = "24" ]; then
					targetFormat="$af24bit44hz"
				elif [ "$bitDepth" = "32" ]; then
					targetFormat="$af32bit44hz"	
				elif [ "$bitDepth" = "64" ]; then
					targetFormat="$af64bit44hz"
				else
					targetFormat="$af16bit44hz"	
					bitDepth="16"
				fi

		    	afconvert -o "$f" -f 'WAVE' -d "$targetFormat" "$f"
		  		size=$(stat -f%z "$f") 
				size=$(($size / 1024))
				increase=$((size-sizeBefore))
				totalIncrease=$((increase+totalIncrease))

		  		echo "=> Converted $bitDepth bits | 44100 Hz | $size KB"
		   else 
		   		echo "=> Conversion candidate"
		   fi
		fi
	    
	done

	echo "$lB"
	echo "$convCount of $count files converted, $skippedCount skipped."
	totalIncreaseMb=$(($totalIncrease / 1024))
	echo "Total disk space usage: $totalIncrease KB | $totalIncreaseMb MB"
	echo "$lB"
}



welcome() {
	echo "${lB}DELUGE SAMPLE FIXER${lB}"
	libcheck
	isRootDir
	if [ "$ARG1_runmode" = "discover" ]; then 
		echo 'DISCOVER UNSUPPORTED SAMPLES'
		convert
	elif [ "$ARG1_runmode" = "fix" ]; then
		echo 'FIX UNSUPPORTED SAMPLES'
		convert
	elif [ "$ARG1_runmode" = "clean" ]; then 
		echo 'DISCOVER NON-AUDIO SAMPLES'
		clean
	elif [ "$ARG1_runmode" = "clean-fix" ]; then
		echo 'REMOVE NON-AUDIO SAMPLES'		
		clean	
	else 
		echo 'HELP'
cat << EOF
Some helper tools for the Synthstrom Deluge.
Consider a backup before using this script.

<discover>
 	Lists WAV samples Synthstrom Deluge might not be able to load.
 	Targets all samples with a sample rate below 44Hz. Or having other oddities.
 	Run 'sh script.sh fix' if the list looks reasonable. 
<fix>
 	Fix samples. Discovered WAV files get converted to 44Hz. No backup.
 	Source bit depth is retained (24, 16 or 8), defaults to 16. 
 	Backup your data before using this function. Data will be overwritten. 
<clean>
 	Lists non audio files. 
<clean-fix>
 	Clears non audio files. No backup.  	
 	Run 'sh script.sh clean-fix' if the list looks reasonable.
EOF
	fi
}


welcome 

 
exit 1