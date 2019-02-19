#!/bin/bash
#tweak OSX display monitors' brightness to a given scheme, increment, or based on the current local time

# I: got edid.name: LG Ultra HD -> lg4k
# I: got edid.name: E2442 -> lg1080
# lg4k sometimes reports 0 when reading brightness
# lg1080 always reports 0 brightness
#
# result=($(ddcctl -d $lg4k -b $1 -c $2 | awk '/current:/ {print $8}'))
# brightness=${result[0]/,/}
# contrast=${result[1]/,/}
# ddcctl -d $lg1080 -b $brightness -c $contrast
	
lg4k="/usr/local/bin/ddcctl -d 1"
lg1080="/usr/local/bin/ddcctl -d 2"
BRIGHTNESS_FILE="/Users/filippo/.brightness"

setDisplays() {
	if [[ $# -lt 1 ]] ; then
    	echo "setDisplay [down|up]"
		exit 1
	fi

	if [[ ! -f $BRIGHTNESS_FILE ]]; then
		echo '70' > $BRIGHTNESS_FILE
	fi
	
	current=$(cat $BRIGHTNESS_FILE)
	if [[ "$1" == "up" ]] ; then
		newBrightness=$((current+10))
	else 
		newBrightness=$((current-10))
	fi

	newBrightness=$(($newBrightness>100?100:$newBrightness))
	newBrightness=$(($newBrightness<0?0:$newBrightness))	

	newContrast=$(echo "15 + $newBrightness * 0.7" | bc)

	if ((  $(echo $newBrightness'<80' | bc -l) )); then
		newContrast=$(echo "23 + $newBrightness * 0.7" | bc)
	fi

	if ((  $(echo $newBrightness'<50' | bc -l) )); then
		newContrast=$(echo "28 + $newBrightness * 0.6" | bc)
	fi

	if ((  $(echo $newBrightness'<20' | bc -l) )); then
		newContrast=$(echo "20 + $newBrightness * 0.5" | bc)
	fi

	$lg4k -b $newBrightness -c $newContrast > /dev/null &
	$lg1080 -b $(echo "$newBrightness * 1" | bc) -c $(echo "$newContrast * 0.5" | bc) > /dev/null &
	echo $newBrightness > /Users/filippo/.brightness
	echo $newBrightness $newContrast
	/Applications/OSDisplay.app/Contents/MacOS/OSDisplay -i brightness -l $newBrightness -d 1.0	> /dev/null 2>/dev/null &
}

case "$1" in
	-b) setDisplays $2;;
	# *)	#no scheme given, match local Hour of Day
	# 	# HoD=$(date +%k) #hour of day
	# 	# let "night = (( $HoD < 7 || $HoD > 18 ))" #daytime is 7a-7p
	# 	# (($night)) && dim || bright
	# 	# ;;
	# 	setDisplays up
	# 	;;
esac
