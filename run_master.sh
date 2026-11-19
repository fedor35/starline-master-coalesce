#!/bin/sh
# Запуск StarLine Master с прослойкой склейки чтений (нужна для прошивки через CP2102 на Linux)
DIR=$(dirname "$(readlink -f "$0")")
MASTER=${MASTER:-$HOME/starline-master}
pkill -x StarLine-Master 2>/dev/null; sleep 1
cd "$MASTER" && LD_PRELOAD="$DIR/coalesce_read.so" exec ./StarLine-Master.sh "$@"
