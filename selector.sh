#!/bin/bash

# Selector.sh
# Written by Michael McElrath
# 2017-01-26
# Description:
#   Allows the user to select from a list of movie files
#   within a directory. Also lists subdirectories.
#   Used to navigate and play movies with the option of 
#   Playing movies randomly.

# Provides the user with a list of all media files 
# and subfolders in the chosen directory. User may
# Select a file to play, a directory to open, or
# have the program play files randomly.
# $1 is the directory to start in.
function select_file() {
	# Clear old file list.
	unset files
	# Show specific variables
	number_of_seasons=7
	# Reset Variables
	quote=$(shuf -n 1 quotes.txt)
	i=2						# Name of item (Starts at 1 for random item)
	items=1					# Number for array
	width=20  				# necessary width of window
	height=7				# necessary height of window
	# Add random episode at the top
	files[0]=0
	files[1]="Random Episode"
	# Look at each file in the directory. If it is an mp4 or directory, add it to the array
	for f in "$1"/*; do			
		if [[ -d $f || ${f: -4} == ".mp4" || ${f: -4} == ".mkv" || ${f: -4} == ".avi" || ${f: -4} == ".mpg"]]; then
			#Chop off the parent directory to make it pretty
			title=$(basename "$f")
			# Chop off the extension to make it pretty
			if [[ ${f: -4} == ".mp4" ]]; then				
				title="${title%.*}"
			fi
			# If the name is long, increase the whiptail width
			if  [[ "${#title}" -gt $width ]]; then	
				width=${#f}							
			fi
			# Add label and title to the array.
			files[i]=$items 						# Even number = item count 
			files[i+1]="${title}"					# Odd number = item name
			((i+=2))								# Next item name is 2 spaces up
			((items++))								# Increase number by 1
		fi
	done
	# Add final option to go back
	files[i]=$items
	files[i+1]="Back"
	# Increase width a bit, for buffer
	((width+=2))
	# Adjust item list to sensible numbers
	((items=${items}+2))
	# But not too big.
	if [[ "$items" -gt 15 ]]; then
		items=15
	fi
	# Make the holding height a bigger
	((height=${items}+8))
	# Display the whiptail dialog! Save the result to 'selection'
	# This selection is just the item index.
	selection=$(whiptail --backtitle "$quote" --title "Select an Action" \
		--menu "Studio 6H" ${height} ${width} ${items} "${files[@]}" 3>&2 2>&1 1>&3-)
	if [[ $? = 0 ]]; then
		# Convert the item index to the actual title
		((selection=2*selection+1))
		selection=${files[${selection}]}
	else
		# Don't exit immediately. Just back up.
		selection="Back"
	fi
	# See what to do with the selection. Pass the whole path, and the pretty name.
	check_file "${1}/${selection}" "${selection}" 
		
}


# Check the selection 
# If it a directory, move to that directory.
# If it is a video, play the video
# If it is the option to play random, play a random video
# IF it is back, go to the parent directory
# If we are in the root directory, exit the script
function check_file() {
	# Collate Information
	filename=$(find "$(dirname "$1")" -name "$2".*)
	dir="$(dirname "$1")"	
	parentdir="$(dirname "$dir")"
	# If directory, Move down a directory
	if [[ -d $1 ]]; then
		# Store the season, convert to integer
		season=$(basename "$1")
		season=($season)
		season=$((10#${season[1]}))
		select_file "${1}"
	# If it is "back" move to parent directory
	elif [[ $2 = "Back" ]]; then
		unset season
		if [[ "${parentdir}" = "${PWD}/Media" ]]; then  	# Prevents leaving 30 Rock directory. Remove "/Media"  if multiple shows.
			# Cleanup
			clear
			exit 
		else
			select_file "$parentdir"
		fi
	# If it is a file, make use of it.
	# Set play mode to "ordered."
	elif [[ -f $filename ]]; then
		# Store episode number
		episode=($2)
		episode=$((10#${episode[1]}))
		play_mode="ordered"
		queue_next "$play_mode" "$filename"
	# We're playing random episodes.
	elif [[ $2 = "Random Episode" ]]; then
		if [[ $season ]]; then
			play_mode="shuffle"
		else
			play_mode="shuffleall"
		fi
		find_random "$play_mode" "$dir"
	# Otherwise its not valid. Exit.
	else
		echo "$1 is not valid"
		exit 1
	fi
}

## Find a random movie. 
# $1 is working directory
# $2 is defined if we should use the parent directory (Shuffling all)
function find_random() {
	workingdir=("$2"/*)
	movie=${workingdir[RANDOM % ${#workingdir[@]}]}
	# Keep going until we find a movie
	while [[ ${movie: -4} != ".mp4" && ${movie: -4} != ".mkv" && ${movie: -4} != ".avi" && ${movie: -4} != ".mpg"]]; do
		# If it is a directory, we have to go deeper.
		if [[ -d "$movie" ]]; then
			# Store the season, convert to integer
			season=$(basename "$movie")
			season=($season)
			season=$((10#${season[1]}))
			find_random $1 "$movie"
		fi
		movie=${workingdir[RANDOM % ${#workingdir[@]}]}
	done
	# Play movie. Pass along working directory, and if we're shuffling all as well.
	queue_next "$1" "$movie"
}
# Play the movie with custom keybindings and using audio through
# HDMI. when the movie is finished, play another movie using
# The given play method.
# $1 is the play mode (ordered, shuffle, or shuffleall)
# $2 is movie path
function play_movie() {
	# Play Currently selected movie.
	omxplayer -d --key-config /home/pi/omxkeys.txt -o hdmi "$2"
	# Find next movie. 
	find_next "$1" "$2"
}
# Find the next movie. 
# $1 is the play mode
# $2 is the current movie path.
function find_next() {
	# Looking for a random movie
	if [[ "$1" == "shuffle" || "$1" == "shuffleall" ]]; then
		find_random $1 "$dir"
	# Not looking for a random episode, so play the next one.
	else
		# Choose next episode
		((episode++))
		# If we are below episode 9, we need to add a leading zero.
		# Also, we are sure there is another episode (at least 10 per season)
		if [[ "${episode}" -lt 10 ]]; then
			nextepisode=$(find "$dir" -name "Episode 0"$episode""*.*)
		# If we are at episode 9 or after, we don't need a leading zero.
		else
			nextepisode=$(find "$dir" -name "Episode "$episode""*.*)
		fi
		# If that next episode doesn't exist, go to episode 01 of the next season
		if [[ ! $nextepisode ]]; then
			((episode=1))
			((season++))
			if [[ "${season}" -lt 10 ]]; then
				nextepisode=$(find "${parentdir}/Season 0${season}/" -name "Episode 01"*.*)
			else
				nextepisode=$(find "${parentdir}/Season ${season}/" -name "Episode 01"*.*)
			
			if [[ ! $nextepisode ]]; then
				# No more episodes :(
				read -n 1 -t 5 -s -p "No more episodes. Maybe start from the beginning?" input
				select_file "$parentdir"
			fi
		fi
	fi
	queue_next $1 "$nextepisode"
}

# Displays a 10-second count until the next movie is played.
# While counting down, the user may proceed immediately with 
# Spacebar or Enter. Alternatively, they may cancel and return
# to selection by pressing any other key.
function queue_next() {
	timer=10
	unset output
	friendly_name "$2"
	# Clean the screen and actively count down to the playing of the next movie.
	while [[ $timer -gt 0 && -z $output ]]; do
		clear
		echo "Up Next: Season $season, $fname"
		echo "Playing in $timer seconds. Press 'A' or 'Select' to play now."
		read -n 1 -t 1 -s -p "Press any other key to cancel." input
		if [[ $? == 0 ]]; then
			if [[ $input == '' ]]; then
				output="play"
			else
				output="stop"
			fi
			# I know this is bad, but I want it to be responsive.
			break
		fi
	((timer--))
	done
	echo ""
	if [[ "$output" == "stop" ]]; then
		echo "Play cancelled, back to selection"
		select_file "$dir"
	else
		echo "Starting movie, one moment..."
		play_movie $1 "$2"
	fi
}
# removes the PATH and file extension of a file.
function friendly_name() {
	fname=$(basename "$1")
	fname="${fname%.*}"
}

# Actual script that is run when this script is launched. 
# Starts by selecting file in the 30 rock directory.
select_file "${PWD}/Media/30 Rock"
