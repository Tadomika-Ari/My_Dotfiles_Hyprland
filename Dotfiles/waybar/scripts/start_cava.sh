#!/bin/bash
# Crée le FIFO si nécessaire
[ ! -p /tmp/cava_fifo ] && mkfifo /tmp/cava_fifo

# Lance Cava vers le FIFO
cava --raw -p > /tmp/cava_fifo &

# Lance Waybar
waybar &
