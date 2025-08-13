#!/usr/bin/env bash
set -euo pipefail
# r36s-fn-select-fix.sh v1
#
# Purpose
# -------
# Fix/normalize FN (hotkey) and SELECT button mappings across:
#   - EmulationStation (es_input.cfg)
#   - RetroArch & RetroArch32 user configs (retroarch.cfg)
#   - RetroArch & RetroArch32 autoconfigs for controllers
#
# What it does
# ------------
# - Ensures EmulationStation has SELECT=<SELECT_ID> and HOTKEYENABLE=<FN_ID>
#   (inserts the hotkey line if missing).
# - Sets RetroArch/RetroArch32 to:
#     input_enable_hotkey_btn = "<FN_ID>"
#     input_player1_select_btn = "<SELECT_ID>"
#     input_menu_toggle_btn = "<MENU_ID>"   # enables FN + <MENU_ID> combo for menu
#     input_menu_toggle_gamepad_combo = "0" # disables default Select+X style combos
# - Updates controller autoconfigs in:
#     /usr/share/retroarch*/autoconfig/udev
#     ~/.config/retroarch*/autoconfig        (if present)
# - Creates timestamped backups under ~/backup_inputs_YYYYmmdd-HHMMSS
# - Optional: backs up & clears RetroArch overrides (--clean-overrides)
#
# Defaults (override via flags):
#   --fn-id N       (default 12)
#   --select-id M   (default 16)
#   --menu-id K     (default 2)  # X button in your setup
#   --clean-overrides (optional)
#
# Usage examples
#   ./r36s-fn-select-fix.sh
#   ./r36s-fn-select-fix.sh --fn-id 12 --select-id 16 --menu-id 2
#   sudo ./r36s-fn-select-fix.sh         # required to edit /usr/share autoconfigs
#   ./r36s-fn-select-fix.sh --clean-overrides
#
# Notes
# -----
# - Run once as your normal user (to fix user configs), then again with sudo
#   (to fix /usr/share/* autoconfigs), then reboot.
# - Keep this script in your repo and re-run after firmware updates or
#   controller changes.

FN_ID="12"
SELECT_ID="16"
MENU_ID="2"
CLEAN_OVERRIDES=0

# ------------- Parse CLI flags -------------
while [[ $# -gt 0 ]]; do
  case "$1" in
      --fn-id)
        if [[ -z ${2-} || ! $2 =~ ^[0-9]{1,2}$ ]]; then
          echo "--fn-id requires a numeric argument of up to two digits" >&2
          exit 1
        fi
        FN_ID="$2"
        shift 2
        ;;
      --select-id)
        if [[ -z ${2-} || ! $2 =~ ^[0-9]{1,2}$ ]]; then
          echo "--select-id requires a numeric argument of up to two digits" >&2
          exit 1
        fi
        SELECT_ID="$2"
        shift 2
        ;;
      --menu-id)
        if [[ -z ${2-} || ! $2 =~ ^[0-9]{1,2}$ ]]; then
          echo "--menu-id requires a numeric argument of up to two digits" >&2
          exit 1
        fi
        MENU_ID="$2"
        shift 2
        ;;
    --clean-overrides) CLEAN_OVERRIDES=1; shift;;
    -h|--help)
      cat <<USAGE
Usage: $0 [--fn-id N] [--select-id M] [--menu-id K] [--clean-overrides]
Defaults: FN=12, SELECT=16, MENU=2
Run once as user, then again with sudo, then reboot.
USAGE
      exit 0;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1;;
  esac
done

echo "==> Using IDs: FN=${FN_ID}  SELECT=${SELECT_ID}  MENU=${MENU_ID}"

# ------------- Resolve target user/home (works under sudo) -------------
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
if [[ -z "${TARGET_HOME}" ]]; then
  echo "Failed to resolve home for user: ${TARGET_USER}" >&2
  exit 1
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${TARGET_HOME}/backup_inputs_${STAMP}"
mkdir -p "${BACKUP_DIR}"

# ------------- EmulationStation fix -------------
# Adjust SELECT and HOTKEYENABLE in es_input.cfg.
fix_es_cfg() {
  local cfg="$1"
  [[ -f "$cfg" ]] || return 1

  cp -v "$cfg" "${BACKUP_DIR}/$(basename "$cfg").bak"

  # Ensure SELECT has the desired ID.
  if grep -q 'name="select"' "$cfg"; then
    sed -E -i \
      "s#(<input[^>]*name=\"select\"[^>]*id=\")([0-9]+)(\"[^>]*>)#\1${SELECT_ID}\3#g" \
      "$cfg" || true
  fi

  # Ensure HOTKEYENABLE exists with the desired ID; insert if missing.
  if grep -q 'name="hotkeyenable"' "$cfg"; then
    sed -E -i \
      "s#(<input[^>]*name=\"hotkeyenable\"[^>]*id=\")([0-9]+)(\"[^>]*>)#\1${FN_ID}\3#g" \
      "$cfg" || true
  else
    sed -i \
      '/name="select"/a \                <input name="hotkeyenable" type="button" id="'"${FN_ID}"'" value="1" />' \
      "$cfg"
  fi

  echo "→ EmulationStation updated: $cfg"
}

ES_USER_CFG="${TARGET_HOME}/.emulationstation/es_input.cfg"
ES_SYS_CFG="/etc/emulationstation/es_input.cfg"

if ! fix_es_cfg "$ES_USER_CFG"; then
  if [[ -f "$ES_SYS_CFG" ]]; then
    if [[ $EUID -eq 0 ]]; then
      fix_es_cfg "$ES_SYS_CFG"
    else
      echo "NOTE: System es_input.cfg found. Re-run with sudo to update: $ES_SYS_CFG"
    fi
  else
    echo "NOTE: es_input.cfg not found. In EmulationStation, run:"
    echo "      Start → Controller Settings → Configure Input"
  fi
fi

# ------------- RetroArch autoconfigs (controllers) -------------
# Edit autoconfigs in common locations for RetroArch and RetroArch32.
declare -a AUTOCONFIG_DIRS=(
  "/usr/share/retroarch/autoconfig/udev"
  "/usr/share/retroarch32/autoconfig/udev"
  "${TARGET_HOME}/.config/retroarch/autoconfig"
  "${TARGET_HOME}/.config/retroarch32/autoconfig"
)

for dir in "${AUTOCONFIG_DIRS[@]}"; do
  [[ -d "$dir" ]] || continue
  echo "Scanning autoconfigs in: $dir"

  while IFS= read -r -d '' cfg; do
    # Editing /usr/share requires root.
    if [[ "$dir" == /usr/share/* && $EUID -ne 0 ]]; then
      echo "  (sudo required) $cfg"
      continue
    fi

    # Only touch files that define both keys.
    if grep -q '^input_select_btn' "$cfg" && grep -q '^input_enable_hotkey_btn' "$cfg"; then
      subbk="${BACKUP_DIR}${dir}"
      mkdir -p "$subbk"
      cp -v "$cfg" "$subbk/$(basename "$cfg").bak"

      sed -E -i \
        -e "s#^(input_select_btn\s*=\s*)\"[^\"]*\"#\1\"${SELECT_ID}\"#g" \
        -e "s#^(input_enable_hotkey_btn\s*=\s*)\"[^\"]*\"#\1\"${FN_ID}\"#g" \
        "$cfg"

      # Ensure explicit menu button and disable combo.
      if grep -q '^input_menu_toggle_btn' "$cfg"; then
        sed -E -i 's#^(input_menu_toggle_btn\s*=\s*)\"[^\"]*\"#\1"'"${MENU_ID}"'"#g' "$cfg"
      else
        echo 'input_menu_toggle_btn = "'"${MENU_ID}"'"' >> "$cfg"
      fi

      if grep -q '^input_menu_toggle_gamepad_combo' "$cfg"; then
        sed -E -i 's#^(input_menu_toggle_gamepad_combo\s*=\s*)\"?[0-9]+\"?#\10#' "$cfg"
      else
        echo 'input_menu_toggle_gamepad_combo = "0"' >> "$cfg"
      fi

      echo "  → Autoconfig updated: $cfg"
    fi
  done < <(find "$dir" -maxdepth 1 -type f -name '*.cfg' -print0 2>/dev/null)
done

# ------------- RetroArch user configs -------------
# Force FN hotkey, P1 Select, explicit menu button, disable menu combo.
fix_user_retroarch_cfg() {
  local cfg="$1"
  [[ -f "$cfg" ]] || return 0

  cp -v "$cfg" "${BACKUP_DIR}/$(basename "$cfg").bak"

  # Hotkey enable
  if grep -q '^input_enable_hotkey_btn' "$cfg"; then
    sed -E -i "s#^(input_enable_hotkey_btn\s*=\s*)\"[^\"]*\"#\1\"${FN_ID}\"#g" "$cfg"
  else
    echo "input_enable_hotkey_btn = \"${FN_ID}\"" >> "$cfg"
  fi

  # Player 1 Select
  if grep -q '^input_player1_select_btn' "$cfg"; then
    sed -E -i "s#^(input_player1_select_btn\s*=\s*)\"[^\"]*\"#\1\"${SELECT_ID}\"#g" "$cfg"
  else
    echo "input_player1_select_btn = \"${SELECT_ID}\"" >> "$cfg"
  fi

  # Menu toggle button (for FN + MENU_ID)
  if grep -q '^input_menu_toggle_btn' "$cfg"; then
    sed -E -i 's#^(input_menu_toggle_btn\s*=\s*)\"[^\"]*\"#\1"'"${MENU_ID}"'"#g' "$cfg"
  else
    echo 'input_menu_toggle_btn = "'"${MENU_ID}"'"' >> "$cfg"
  fi

  # Disable built-in menu combo
  if grep -q '^input_menu_toggle_gamepad_combo' "$cfg"; then
    sed -E -i 's#^(input_menu_toggle_gamepad_combo\s*=\s*)\"?[0-9]+\"?#\10#' "$cfg"
  else
    echo 'input_menu_toggle_gamepad_combo = "0"' >> "$cfg"
  fi

  echo "→ RetroArch config updated: $cfg"
}

fix_user_retroarch_cfg "${TARGET_HOME}/.config/retroarch/retroarch.cfg"
fix_user_retroarch_cfg "${TARGET_HOME}/.config/retroarch32/retroarch.cfg"

# ------------- Optional: clean overrides -------------
if [[ $CLEAN_OVERRIDES -eq 1 ]]; then
  OVR_DIR="${TARGET_HOME}/.config/retroarch/config"
  if [[ -d "$OVR_DIR" ]]; then
    BK_OVR="${BACKUP_DIR}/retroarch_overrides_$(date +%H%M%S)"
    echo "Backing up overrides to: ${BK_OVR}"
    mkdir -p "$BK_OVR"
    cp -r "$OVR_DIR"/. "$BK_OVR"/
    rm -rf "${OVR_DIR:?}/"*
    echo "→ Overrides cleaned."
  else
    echo "(No RetroArch overrides found to clean)"
  fi
fi

echo "------------------------------------------------------"
echo "Backups stored in: ${BACKUP_DIR}"
if [[ $EUID -ne 0 ]]; then
  echo "If you saw '(sudo required)' for /usr/share paths, re-run with sudo:"
  echo "  sudo $0 --fn-id ${FN_ID} --select-id ${SELECT_ID} --menu-id ${MENU_ID}"
fi
echo "Reboot EmulationStation or the device when done (recommended):  sudo reboot"
