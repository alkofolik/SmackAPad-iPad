#!/bin/bash
DEVICE="9CC875DA-5EDB-4032-94FF-1D802565DBB5"
DIR="docs/design/2026-11-07-button-system/screenshots"
mkdir -p "$DIR"

capture_one() {
    local screen=$1
    local mode=$2
    local orient=$3
    local out="$DIR/${screen}_${orient}_${mode}.png"
    local tmp="$DIR/tmp_${screen}_${orient}_${mode}.png"

    xcrun simctl terminate $DEVICE cz.kju.SmackAPad 2>/dev/null
    local extra=""
    if [ "$orient" = "landscape" ]; then extra="-landscape"; fi
    if [ "$screen" = "home" ]; then
        xcrun simctl launch $DEVICE cz.kju.SmackAPad -$mode $extra >/dev/null 2>&1
    else
        xcrun simctl launch $DEVICE cz.kju.SmackAPad -$screen -$mode $extra >/dev/null 2>&1
    fi
    sleep 2.8
    if [ "$orient" = "landscape" ]; then
        xcrun simctl io $DEVICE screenshot "$tmp" >/dev/null 2>&1
        sips -r 270 "$tmp" --out "$out" >/dev/null 2>&1
        rm -f "$tmp"
    else
        xcrun simctl io $DEVICE screenshot "$out" >/dev/null 2>&1
    fi
    local size=$(ls -lh "$out" | awk '{print $5}')
    echo "OK: $screen $orient $mode ($size)"
}

# Core screens covering every button kind in light and dark, landscape and portrait
for s in library practice training today controller purchases settings calibration; do
    for m in light dark; do
        for o in landscape portrait; do
            capture_one $s $m $o
        done
    done
done

echo "High-resolution before capture complete!"
