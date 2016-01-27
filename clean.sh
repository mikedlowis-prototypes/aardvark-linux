#!/bin/sh
. ./config.sh
echo rm -r "$AL_ROOT"
rm -rf "$AL_ROOT"
echo rm -r "$AL_SOURCES"
rm -rf "$AL_SOURCES"
