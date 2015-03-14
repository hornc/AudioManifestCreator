# Audio Manifest Creator

This app searches the current and one level of subdirectories for audio files (currently .WAV and .MP3) and audio file manifests in .CSV format.

If a directory contains audio files but no manifest file, the script will generate a blank .CSV manifest with:
* sample name
* duration
* datetime recorded
* sample size
* sample rate
* channels
* and empty fields for a description and location recorded (to be filled out manually later)

The script will also generate one HTML index file lising all the samples found in the various subdirectories, the current data from the corresponding manifest files, a link to the CSV manifest, and link each sample so it can be previewed via an embedded player in a webbrowser.

The CSV manifest once generated is intended to be manually updated to permanently store notes about the samples. The HTML index will updated and overwritten each time the script is run. It is merely a view to the data stored in the subdirectories and should not be edited manually. The csv manifests are intended to be the source for all data about the audio files -- the html index merely collects and formats that data. If audio file descriptions are to be updated, changes should be made in the csv and this script run again to recreate and overwrite the html.

Based on two scripts I wrote in 2009 / 2010 to manage, preview, and capture the notes on many field recordings I made over the years on my Edirol R-09H and other devices.

**USAGE**

  `ruby create_manifests.rb <target dir>`

`sample_info.rb`
Analyzes an audio file and provides information about its length and format. Currently supports .wav and .mp3

**TODO**

* Remove logic from manifest_index.html.erb
* Add support for parsing Mpeg4 audio, .ogg, .au
