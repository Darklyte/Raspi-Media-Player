# Raspi-Media-Player

This project was built as an advanced version of the [Pi Zero Simpsons Shuffler](http://stephencoyle.net/the-pi-zero-simpsons-shuffler/). It provides a simple interface for selecting movies within a series or playing random episodes from the series. It was conceived as a player for 30 Rock with a Raspberry Pi Zero, but can be easily modified to work with any or multiple series. 

# Installation

Save the file to the root directory of your device. run it with ./selector.sh

# Configurations

For this script to work, simply launch selector.sh. Any media should be stored in the ./media directory

The default script uses ./media/30 Rock. to modify this, change the last line of the script to the default directory of series.

If you are doing multiple series, or storing a single series directly in the ./media directory, edit line 101 and remove '/media'.

## File system requirements

* Each season in the series should be labled 'season xx', with two digits for the season number and 'season' in all lower case.
* Each episode should begin with 'episode xx', with two digits for the episode and 'episode' in lower case
* Ensure that the files are encoded in h.264, ideally. Raspberry Pi's hardware cannot decode h.264.
* Files must be mp4, mkv, avi, or mpg. The script disregards all other file extensions.
