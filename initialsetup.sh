#!/bin/bash
# /opt/rj-project/scripts/InitialSetup.sh

MAIN_DIR="/opt/rj-project/scripts"
REF_SCRIPTS_SUBDIR="reference_scripts" # Adjusted relative path
REF_SCRIPTS_DIR="$MAIN_DIR/$REF_SCRIPTS_SUBDIR"
ERROR_SUBDIR="files/error" # Adjusted relative path
ERROR_DIR="$MAIN_DIR/$ERROR_SUBDIR"

# Apply execute permissions recursively to all .sh files under reference_scripts
find "$REF_SCRIPTS_DIR" -type f -name '*.sh' -exec chmod +x {} \;

# Define service scripts for create_services.sh
service_scripts=("rj-audit.sh" "rj-control.sh" "rj-update.sh")

# Execute child scripts, passing the main directory, ref scripts subdir, and error dir
"$REF_SCRIPTS_DIR/create_services.sh" "$MAIN_DIR" "$REF_SCRIPTS_SUBDIR" "$ERROR_DIR" "${service_scripts[@]}"
"$REF_SCRIPTS_DIR/security_defaults.sh" "$MAIN_DIR" "$REF_SCRIPTS_SUBDIR" "$ERROR_DIR"
"$REF_SCRIPTS_DIR/docker_config.sh" "$MAIN_DIR" "$REF_SCRIPTS_SUBDIR" "$ERROR_DIR"
"$REF_SCRIPTS_DIR/monitoring_defaults.sh" "$MAIN_DIR" "$REF_SCRIPTS_SUBDIR" "$ERROR_DIR"

# Function to check the exit status of a command and report an error
report_error() {
  local command_name="$1"
  local exit_code="$2"
  if [[ "$exit_code" -ne 0 ]]; then
    echo "Error: Command '$command_name' failed with exit code $exit_code." >> "$ERROR_DIR/initial_setup_errors.txt"
  fi
}

# Execute child scripts and report errors
"$REF_SCRIPTS_DIR/create_services.sh" "$MAIN_DIR" "$REF_SCRIPTS_SUBDIR" "$ERROR_DIR" "${service_scripts[@]}"
report_error "create_services.sh" "$?"

"$REF_SCRIPTS_DIR/security_defaults.sh" "$MAIN_DIR" "$REF_SCRIPTS_SUBDIR" "$ERROR_DIR"
report_error "security_defaults.sh" "$?"

"$REF_SCRIPTS_DIR/docker_config.sh" "$MAIN_DIR" "$REF_SCRIPTS_SUBDIR" "$ERROR_DIR"
report_error "docker_config.sh" "$?"

"$REF_SCRIPTS_DIR/monitoring_defaults.sh" "$MAIN_DIR" "$REF_SCRIPTS_SUBDIR" "$ERROR_DIR"
report_error "monitoring_defaults.sh" "$?"

exit 0