#!/usr/bin/env bash
set -euo pipefail

GAMES_DIR="/home/fdesi/Games/Retro"
PLAYLIST_DIR="$HOME/.local/share/retroarch/playlists"
SYSTEM_DIR="$HOME/.local/share/retroarch/system"

mkdir -p "$PLAYLIST_DIR" "$SYSTEM_DIR"

# Function to generate playlist for a system
generate_playlist() {
    local folder="$1"
    local playlist_name="$2"
    local core_name="$3"
    
    # Skip if folder doesn't exist
    [ -d "$folder" ] || return 0
    
    local playlist_file="$PLAYLIST_DIR/${playlist_name}.lpl"
    echo "Generating playlist: $playlist_file"
    
    # Start JSON playlist
    printf '{\n' > "$playlist_file"
    printf '  "version": "1.12",\n' >> "$playlist_file"
    printf '  "categories": ["%s"],\n' "$playlist_name" >> "$playlist_file"
    printf '  "items": [\n' >> "$playlist_file"
    
    local first=true
    # Find all ROM files (adjust extensions as needed)
    shopt -s nullglob
    for rom in "$folder"/*.{zip,7z,iso,bin,gen,smd,md,snes,sfc,nes,gbc,gb,gba,n64,v64,z64,chd,cue,pbp}; do
        [[ -f "$rom" ]] || continue
        local rom_name=$(basename "$rom")
        
        if [[ "$first" == "true" ]]; then
            first=false
        else
            printf ',\n' >> "$playlist_file"
        fi
        
        printf '    {\n' >> "$playlist_file"
        printf '      "path": "%s",\n' "$rom" >> "$playlist_file"
        printf '      "label": "%s",\n' "$rom_name" >> "$playlist_file"
        printf '      "core_path": "builtin://%s_libretro.so",\n' "$core_name" >> "$playlist_file"
        printf '      "core_name": "%s",\n' "$core_name" >> "$playlist_file"
        printf '      "crc32": "00000000|crc32"\n' >> "$playlist_file"
        printf '    }' >> "$playlist_file"
    done
    
    printf '\n  ]\n' >> "$playlist_file"
    printf '}\n' >> "$playlist_file"
}

# Generate playlists for each system
generate_playlist "$GAMES_DIR/Arcade - Mame 2003 Plus" "Arcade - MAME" "fbneo" || true
generate_playlist "$GAMES_DIR/Atari - 2600" "Atari - 2600" "stella" || true
generate_playlist "$GAMES_DIR/NEC - TurboGrafx-16" "NEC - TurboGrafx-16" "mednafen_pce_fast" || true
generate_playlist "$GAMES_DIR/NEC - TurboGrafx CD" "NEC - TurboGrafx CD" "mednafen_pce_fast" || true
generate_playlist "$GAMES_DIR/Nintendo - DS" "Nintendo - DS" "desmume" || true
generate_playlist "$GAMES_DIR/Nintendo - Game Boy" "Nintendo - Game Boy" "mgba" || true
generate_playlist "$GAMES_DIR/Nintendo - Game Boy Advance" "Nintendo - Game Boy Advance" "mgba" || true
generate_playlist "$GAMES_DIR/Nintendo - Game Boy Color" "Nintendo - Game Boy Color" "mgba" || true
generate_playlist "$GAMES_DIR/Nintendo - GameCube" "Nintendo - GameCube" "dolphin" || true
generate_playlist "$GAMES_DIR/Nintendo - N64" "Nintendo - Nintendo 64" "mupen64plus_next" || true
generate_playlist "$GAMES_DIR/Nintendo - NES" "Nintendo - NES" "snes9x" || true
generate_playlist "$GAMES_DIR/Nintendo - SNES" "Nintendo - SNES" "snes9x" || true
generate_playlist "$GAMES_DIR/Sega - Dreamcast" "Sega - Dreamcast" "flycast" || true
generate_playlist "$GAMES_DIR/Sega - Game Gear" "Sega - Game Gear" "genesis_plus_gx" || true
generate_playlist "$GAMES_DIR/Sega - Genesis" "Sega - Genesis" "genesis_plus_gx" || true
generate_playlist "$GAMES_DIR/Sega - Master System" "Sega - Master System" "genesis_plus_gx" || true
generate_playlist "$GAMES_DIR/Sega - Saturn" "Sega - Saturn" "mednafen_saturn_hw" || true
generate_playlist "$GAMES_DIR/Sega - Sega CD" "Sega - Sega CD" "genesis_plus_gx" || true
generate_playlist "$GAMES_DIR/SNK - NEO GEO" "SNK - Neo Geo" "fbneo" || true
generate_playlist "$GAMES_DIR/Sony - PS1" "Sony - PlayStation" "beetle_psx_hw" || true
generate_playlist "$GAMES_DIR/Sony - PSP" "Sony - PSP" "ppsspp" || true

echo "Done! Generated playlists in $PLAYLIST_DIR"
echo "To update BIOS files, visit: https://docs.libretro.com/library/bios/"