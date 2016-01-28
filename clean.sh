#!/bin/sh
. ./config.sh
echo rm "$AL_ROOT/sbin"
rm "$AL_ROOT/sbin"
echo rm "$AL_ROOT/usr"
rm "$AL_ROOT/usr"
echo rm -r "$AL_SOURCES"
rm -rf "$AL_SOURCES"
echo rm -r "$AL_ROOT"
rm -rf "$AL_ROOT"
