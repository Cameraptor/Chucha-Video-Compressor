#!/usr/bin/env bash
# ============================================================================
#  Chucha Video Compressor — macOS
#  Double-click this file in Finder to launch.
#  Same 2-pass x264 engine as the Windows version.
#
#  Author: Voogie | Cameraptor | cameraptor.com/voogie
# ============================================================================
set -euo pipefail

# --- Colors ----------------------------------------------------------------
R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'; C='\033[0;36m'
DIM='\033[2m'; B='\033[1m'; NC='\033[0m'

# --- Banner ----------------------------------------------------------------
clear
echo ""
echo -e "${DIM}C H U C H A${NC}"
echo -e "${B}VIDEO COMPRESSOR${NC}  ${DIM}(macOS)${NC}"
echo -e "${DIM}────────────────────────────────────────${NC}"
echo ""

# --- FFmpeg detection & install --------------------------------------------
find_ffmpeg() {
    local candidates=(
        "$(command -v ffmpeg 2>/dev/null || true)"
        "/opt/homebrew/bin/ffmpeg"
        "/usr/local/bin/ffmpeg"
        "/opt/local/bin/ffmpeg"
    )
    for c in "${candidates[@]}"; do
        [[ -n "$c" && -x "$c" ]] && { echo "$c"; return 0; }
    done
    return 1
}

find_ffprobe() {
    local dir
    dir="$(dirname "$FFMPEG")"
    local candidates=(
        "$dir/ffprobe"
        "$(command -v ffprobe 2>/dev/null || true)"
        "/opt/homebrew/bin/ffprobe"
        "/usr/local/bin/ffprobe"
    )
    for c in "${candidates[@]}"; do
        [[ -n "$c" && -x "$c" ]] && { echo "$c"; return 0; }
    done
    return 1
}

FFMPEG=""
FFPROBE=""

if FFMPEG=$(find_ffmpeg); then
    echo -e "${G}FFmpeg found:${NC} $FFMPEG"
else
    echo -e "${Y}FFmpeg not found. Installing via Homebrew...${NC}"
    if ! command -v brew &>/dev/null; then
        echo -e "${R}Homebrew not installed.${NC}"
        echo "Install Homebrew first: https://brew.sh"
        echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        echo ""
        echo "Then run this script again."
        echo ""
        read -n1 -rsp "Press any key to exit..."
        exit 1
    fi
    brew install ffmpeg
    if FFMPEG=$(find_ffmpeg); then
        echo -e "${G}FFmpeg installed:${NC} $FFMPEG"
    else
        echo -e "${R}FFmpeg installation failed.${NC}"
        read -n1 -rsp "Press any key to exit..."
        exit 1
    fi
fi

if FFPROBE=$(find_ffprobe); then
    echo -e "${G}FFprobe found:${NC} $FFPROBE"
else
    echo -e "${R}ffprobe not found next to ffmpeg.${NC}"
    read -n1 -rsp "Press any key to exit..."
    exit 1
fi

echo ""

# --- Settings via osascript dialogs ----------------------------------------
ask_text() {
    local prompt="$1" default="$2"
    osascript -e "set T to text returned of (display dialog \"$prompt\" default answer \"$default\" with title \"Chucha Video Compressor\")" 2>/dev/null || echo "$default"
}

ask_choice() {
    local prompt="$1"; shift
    local items=""
    for item in "$@"; do
        [[ -n "$items" ]] && items="$items, "
        items="$items\"$item\""
    done
    osascript -e "choose from list {$items} with prompt \"$prompt\" with title \"Chucha Video Compressor\" default items {\"$1\"}" 2>/dev/null || echo "$1"
}

ask_folder() {
    osascript -e 'set F to POSIX path of (choose folder with prompt "Select folder with video files")' 2>/dev/null || echo ""
}

MAX_RES=$(ask_text "Max resolution (long side in pixels):" "1270")
MAX_SIZE_MB=$(ask_text "Max file size in MB:" "1.5")
FORMAT=$(ask_choice "Output format:" "MP4" "MOV")
OUTPUT_MODE=$(ask_choice "Output mode:" "Compressed subfolder" "Alongside original")
SOURCE_FOLDER=$(ask_folder)

# Validate
if [[ -z "$SOURCE_FOLDER" || ! -d "$SOURCE_FOLDER" ]]; then
    echo -e "${R}No folder selected. Exiting.${NC}"
    read -n1 -rsp "Press any key to exit..."
    exit 1
fi

# Remove trailing slash
SOURCE_FOLDER="${SOURCE_FOLDER%/}"

# Validate numbers
if ! [[ "$MAX_RES" =~ ^[0-9]+$ ]] || (( MAX_RES < 100 )); then
    echo -e "${R}Invalid resolution: $MAX_RES${NC}"
    read -n1 -rsp "Press any key to exit..."
    exit 1
fi

if ! [[ "$MAX_SIZE_MB" =~ ^[0-9]+\.?[0-9]*$ ]] || (( $(echo "$MAX_SIZE_MB <= 0" | bc -l) )); then
    echo -e "${R}Invalid file size: $MAX_SIZE_MB${NC}"
    read -n1 -rsp "Press any key to exit..."
    exit 1
fi

EXT="mp4"
[[ "$FORMAT" == "MOV" ]] && EXT="mov"

echo -e "${DIM}────────────────────────────────────────${NC}"
echo -e "  Folder     : ${B}$SOURCE_FOLDER${NC}"
echo -e "  Resolution : ${B}${MAX_RES}px${NC}"
echo -e "  Max size   : ${B}${MAX_SIZE_MB} MB${NC}"
echo -e "  Format     : ${B}$FORMAT${NC}"
echo -e "  Output     : ${B}$OUTPUT_MODE${NC}"
echo -e "${DIM}────────────────────────────────────────${NC}"
echo ""

# --- Discover video files --------------------------------------------------
VIDEO_EXTS=(-iname "*.mp4" -o -iname "*.mov" -o -iname "*.avi" -o -iname "*.webm" -o -iname "*.mkv" -o -iname "*.mxf" -o -iname "*.m4v" -o -iname "*.wmv")

mapfile -t FILES < <(find "$SOURCE_FOLDER" -type f \( "${VIDEO_EXTS[@]}" \) ! -path "*/Compressed/*" | sort)

if [[ ${#FILES[@]} -eq 0 ]]; then
    echo -e "${R}No video files found in the selected folder.${NC}"
    read -n1 -rsp "Press any key to exit..."
    exit 1
fi

echo -e "Found ${B}${#FILES[@]}${NC} video file(s)"
echo ""

# --- Helper functions ------------------------------------------------------
get_duration() {
    local dur
    dur=$("$FFPROBE" -v quiet -show_entries format=duration -of csv=p=0 "$1" 2>/dev/null | tr -d '[:space:]')
    if [[ -n "$dur" ]] && (( $(echo "$dur > 0" | bc -l) )); then
        echo "$dur"
    else
        echo "10"
    fi
}

has_audio() {
    local result
    result=$("$FFPROBE" -v quiet -select_streams a:0 -show_entries stream=index -of csv=p=0 "$1" 2>/dev/null | tr -d '[:space:]')
    [[ "$result" =~ [0-9] ]]
}

format_time() {
    local secs="${1%.*}"
    printf "%02d:%02d" $(( secs / 60 )) $(( secs % 60 ))
}

# --- Pre-flight analysis ---------------------------------------------------
echo -e "${DIM}Pre-flight analysis...${NC}"

WARNINGS=()
for f in "${FILES[@]}"; do
    dur=$(get_duration "$f")
    if has_audio "$f"; then abr=96; else abr=0; fi
    # min size = (80 kbps video + audio) * duration / 8 / 1024 * 1.08 overhead
    min_mb=$(echo "scale=2; (80 + $abr) * $dur / 8.0 / 1024.0 * 1.08" | bc -l)
    if (( $(echo "$min_mb > $MAX_SIZE_MB" | bc -l) )); then
        fname=$(basename "$f")
        dur_int=${dur%.*}
        WARNINGS+=("  *  $fname  --  min ~${min_mb} MB  (${dur_int}s)")
    fi
done

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    echo ""
    echo -e "${Y}WARNING: ${#WARNINGS[@]} file(s) cannot fit within ${MAX_SIZE_MB} MB:${NC}"
    for w in "${WARNINGS[@]}"; do
        echo -e "${Y}$w${NC}"
    done
    echo ""
    echo "These files will be compressed as small as possible"
    echo "but will likely exceed your size limit."
    echo ""
    read -rp "Continue anyway? (y/N) " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${R}Aborted.${NC}"
        read -n1 -rsp "Press any key to exit..."
        exit 0
    fi
fi

echo ""

# --- Compress function -----------------------------------------------------
compress_video() {
    local src="$1" out="$2"
    local duration abr audio_budget_kb total_budget_kb video_budget_kb vbr_kbps
    local scale pass_log progress_file exit_code

    duration=$(get_duration "$src")
    [[ $(echo "$duration <= 0" | bc -l) -eq 1 ]] && duration=10

    if has_audio "$src"; then abr=96; else abr=0; fi

    total_budget_kb=$(echo "scale=0; $MAX_SIZE_MB * 1024 * 0.92 / 1" | bc)
    audio_budget_kb=$(echo "scale=0; $abr * $duration / 8.0 / 1" | bc)
    video_budget_kb=$(( total_budget_kb - audio_budget_kb ))
    (( video_budget_kb < 50 )) && video_budget_kb=50
    vbr_kbps=$(echo "scale=0; $video_budget_kb * 8.0 / $duration / 1" | bc)
    (( vbr_kbps < 80 )) && vbr_kbps=80

    scale="scale='if(gte(iw,ih),${MAX_RES},-2)':'if(gte(iw,ih),-2,${MAX_RES})'"

    # Create output directory
    local out_dir
    out_dir=$(dirname "$out")
    mkdir -p "$out_dir"

    # Explicit passlogfile in temp
    pass_log=$(mktemp -t ffpass_XXXXXXXX)

    local audio_args=()
    if (( abr > 0 )); then
        audio_args=(-c:a aac -b:a "${abr}k")
    else
        audio_args=(-an)
    fi

    # Pass 1 — analysis
    echo -ne "    ${DIM}Pass 1/2 — analyzing...${NC}\r"
    "$FFMPEG" -y -i "$src" -vf "$scale" \
        -c:v libx264 -b:v "${vbr_kbps}k" \
        -x264-params mbtree=0 \
        -passlogfile "$pass_log" \
        -pass 1 -an -f null /dev/null 2>/dev/null
    exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        rm -f "${pass_log}"* 2>/dev/null
        return 1
    fi

    # Pass 2 — encoding with progress
    local dur_fmt
    dur_fmt=$(format_time "$duration")

    "$FFMPEG" -y -i "$src" -vf "$scale" \
        -c:v libx264 -b:v "${vbr_kbps}k" \
        -x264-params mbtree=0 \
        -passlogfile "$pass_log" \
        -pass 2 -preset slow \
        "${audio_args[@]}" \
        -movflags +faststart \
        "$out" 2>&1 | while IFS= read -r line; do
            if [[ "$line" =~ ^frame= ]]; then
                # Parse time from ffmpeg output
                if [[ "$line" =~ time=([0-9]+):([0-9]+):([0-9]+)\.([0-9]+) ]]; then
                    local h="${BASH_REMATCH[1]}" m="${BASH_REMATCH[2]}" s="${BASH_REMATCH[3]}"
                    local cur_secs=$(( 10#$h * 3600 + 10#$m * 60 + 10#$s ))
                    local dur_secs=${duration%.*}
                    (( dur_secs == 0 )) && dur_secs=1
                    local pct=$(( cur_secs * 100 / dur_secs ))
                    (( pct > 99 )) && pct=99
                    local cur_fmt
                    cur_fmt=$(format_time "$cur_secs")
                    echo -ne "    Pass 2/2  ${cur_fmt} / ${dur_fmt}  (${pct}%)   \r"
                fi
            fi
        done
    exit_code=${PIPESTATUS[0]}

    # Cleanup pass log
    rm -f "${pass_log}"* 2>/dev/null

    echo -ne "                                              \r"

    return $exit_code
}

# --- Main loop -------------------------------------------------------------
DONE=0
FAILED=0
TOTAL=${#FILES[@]}

for (( i=0; i<TOTAL; i++ )); do
    f="${FILES[$i]}"
    num=$(( i + 1 ))
    fname=$(basename "$f")

    echo -e "${C}[$num/$TOTAL]${NC}  $fname"

    # Build output path
    if [[ "$OUTPUT_MODE" == "Compressed subfolder" ]]; then
        # Relative path from source folder
        rel="${f#"$SOURCE_FOLDER"/}"
        out_path="$SOURCE_FOLDER/Compressed/$rel"
    else
        base="${fname%.*}"
        dir=$(dirname "$f")
        out_path="$dir/${base}_compressed.${EXT}"
    fi

    # Change extension to target format
    out_path="${out_path%.*}.${EXT}"

    if compress_video "$f" "$out_path"; then
        if [[ -f "$out_path" ]]; then
            size_kb=$(( $(stat -f%z "$out_path" 2>/dev/null || stat --printf="%s" "$out_path" 2>/dev/null) / 1024 ))
            echo -e "    ${G}[ok]${NC}  ${size_kb} KB -> $out_path"
            (( DONE++ ))
        else
            echo -e "    ${R}[x]${NC}  No output file"
            (( FAILED++ ))
        fi
    else
        echo -e "    ${R}[x]${NC}  Encoding error"
        (( FAILED++ ))
    fi

    echo ""
done

# --- Summary ---------------------------------------------------------------
echo -e "${DIM}────────────────────────────────────────${NC}"
if (( FAILED > 0 )); then
    echo -e "${Y}Done: $DONE successful, $FAILED errors${NC}"
else
    echo -e "${G}Done: $DONE successful${NC}"
fi
echo -e "${DIM}────────────────────────────────────────${NC}"
echo ""

# Notification
osascript -e "display notification \"$DONE files compressed\" with title \"Chucha Video Compressor\" sound name \"Glass\"" 2>/dev/null || true

read -n1 -rsp "Press any key to exit..."
echo ""
