#!/bin/bash
# /opt/rj-project/scripts/reference_scripts/create_services.sh (cloud-config, JSON config)

# Assuming execution via cloud-init as root

# --- Check for required arguments ---
if [[ $# -lt 4 ]]; then
  echo "Usage: $0 <main_dir> <ref_scripts_subdir> <error_dir> <script_filename> [script_filename ...]"
  exit 1
fi

# --- Assign passed arguments ---
MAIN_DIR="$1"
REF_SCRIPTS_SUBDIR="$2"
ERROR_DIR_PASSED="$3"
shift 3 # Remove the first three arguments

# Define the full reference scripts directory
REF_SCRIPTS_DIR="$MAIN_DIR/$REF_SCRIPTS_SUBDIR"

# Updated JSON filename using the passed MAIN_DIR
JSON_CONFIG_FILE="$MAIN_DIR/reference_json/services_settings.json" # Assuming reference_json is now directly under MAIN_DIR
SYSTEMD_DIR="/etc/systemd/system"

# --- Dependency Checks ---
if ! command -v jq &> /dev/null; then
  echo "Warning: jq is not installed. Attempting to install..." >&2
  if command -v apt-get &> /dev/null; then
    sudo apt-get update > /dev/null 2>&1
    sudo apt-get install -y jq > /dev/null 2>&1
    if ! command -v jq &> /dev/null; then
      echo "Error: Failed to install jq using apt-get. Please ensure it can be installed." >&2
      exit 1
    fi
  elif command -v yum &> /dev/null; then
    echo "Warning: jq is not installed. Attempting to install using yum..." >&2
    sudo yum install -y jq > /dev/null 2>&1
    if ! command -v jq &> /dev/null; then
      echo "Error: Failed to install jq using yum. Please ensure it can be installed." >&2
      exit 1
    fi
  else
    echo "Error: jq is not installed, and no supported package manager (apt-get or yum) found for automatic installation." >&2
    exit 1
  fi
fi

# --- Read settings from JSON (with defaults using //) ---
# Use || { ... ; exit 1; } to stop script if jq fails (e.g., invalid JSON) and log error
unit_desc_template=$(jq -r '.Unit.Description // "Service for %SCRIPT_BASENAME%"' "$JSON_CONFIG_FILE") || { echo "Error parsing Unit.Description from JSON." >> "$ERROR_DIR_PASSED/create_services.txt"; exit 1; }
unit_after=$(jq -r '.Unit.After // "multi-user.target"' "$JSON_CONFIG_FILE") || { echo "Error parsing Unit.After from JSON." >> "$ERROR_DIR_PASSED/create_services.txt"; exit 1; }
service_restart=$(jq -r '.Service.Restart // "no"' "$JSON_CONFIG_FILE") || { echo "Error parsing Service.Restart from JSON." >> "$ERROR_DIR_PASSED/create_services.txt"; exit 1; }
service_restart_sec=$(jq -r '.Service.RestartSec // ""' "$JSON_CONFIG_FILE") || { echo "Error parsing Service.RestartSec from JSON." >> "$ERROR_DIR_PASSED/create_services.txt"; exit 1; } # Default empty
install_wantedby=$(jq -r '.Install.WantedBy // "multi-user.target"' "$JSON_CONFIG_FILE") || { echo "Error parsing Install.WantedBy from JSON." >> "$ERROR_DIR_PASSED/create_services.txt"; exit 1; }

services_to_enable=()

# Create service files
for script_filename in "$@"; do
  script_basename=$(basename "$script_filename")
  if [[ "$script_basename" == *.sh ]]; then
    subdirectory_name="${script_basename%.sh}"
    # Construct the working directory using passed variables
    script_working_dir="$MAIN_DIR/$REF_SCRIPTS_SUBDIR/services/${subdirectory_name}"
    # Construct the full script path using the working directory
    full_script_path="${script_working_dir}/${script_basename}"

    if [[ -f "$full_script_path" ]]; then
      service_name="${script_basename%.sh}.service"
      service_file_path="${SYSTEMD_DIR}/${service_name}"

      # --- Substitute placeholders ---
      current_unit_description="${unit_desc_template//%SCRIPT_BASENAME%/$script_basename}"

      # --- Create Unit File using variables ---
      cat > "$service_file_path" << EOF
[Unit]
Description=${current_unit_description}
After=${unit_after}

[Service]
WorkingDirectory=${script_working_dir}
ExecStart=${full_script_path} "$ERROR_DIR_PASSED"
Restart=${service_restart}
$( [[ -n "$service_restart_sec" ]] && echo "RestartSec=${service_restart_sec}" )

[Install]
WantedBy=${install_wantedby}
EOF
      chmod 644 "$service_file_path"
      services_to_enable+=("$service_name")
    else
      echo "Warning: Script not found at $full_script_path. Skipping service creation for $script_basename." >&2
    fi
  fi
done

# Reload and enable all processed services at once
if [[ ${#services_to_enable[@]} -gt 0 ]]; then
  systemctl daemon-reload
  systemctl enable "${services_to_enable[@]}" > /dev/null 2>&1
fi

exit 0