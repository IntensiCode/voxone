#!/usr/bin/env bash
(
  cd assets/audio/voice.src
  for f in $(ls -1 *.mp3)
  do
    #ffmpeg -y -i $f -ar 11025 -ac 1 ../voice/${f%mp3}ogg
    echo "Processing $f"
    sox $f ../voice/${f%mp3}ogg rate 11k channels 1 flanger 2 speed 0.9 reverb chorus 0.7 0.9 55 0.4 0.25 2 -t phaser 0.8 0.74 3 0.4 0.5 -t treble 0.8
  done
)
