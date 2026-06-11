
#!/bin/bash

# ==============================================================================
# Script Name:  setup_project.sh
# Description:  Automated project factory deployment script featuring robust 
#               input validation, stream editing, and a transactional trap cleanup.
# ==============================================================================

# Global variable to track the directory target path for the cleanup function
TARGET_DIR=""
INPUT_SUFFIX=""

# ------------------------------------------------------------------------------
# FUNCTION: cleanup_interrupt
# Triggered exclusively on SIGINT (Ctrl+C). Archives partial state and purges data.
# ------------------------------------------------------------------------------
cleanup_interrupt() {
    echo -e "\n\n[!] CRITICAL: Script execution interrupted by user (SIGINT)."
    
    if [ -n "$TARGET_DIR" ] && [ -d "$TARGET_DIR" ]; then
        ARCHIVE_NAME="attendance_tracker_${INPUT_SUFFIX}_archive.tar.gz"
        echo "[*] Archiving incomplete project state to: ${ARCHIVE_NAME}..."
        
        # Tar and zip the target workspace directory safely
        tar -czf "$ARCHIVE_NAME" "$TARGET_DIR" 2>/dev/null
        
        echo "[*] Cleaning up workspace. Removing partial directory..."
        rm -rf "$TARGET_DIR"
        echo "[+] Workspace sanitized successfully."
    else
        echo "[*] No active directories to clean up."
    fi
    exit 130
}

# Attach the signal handler to SIGINT
trap cleanup_interrupt SIGINT

# ------------------------------------------------------------------------------
# PHASE 1: User Input & Suffix Selection
# ------------------------------------------------------------------------------
echo "=== Student Attendance Tracker Deployment Agent ==="
read -p "Enter a unique identifier for your project workspace suffix: " USER_INPUT

# Sanitize input: Ensure it is not empty and contains no breaking characters
if [ -z "$USER_INPUT" ]; then
    echo "[Error] Project suffix cannot be empty. Aborting deployment."
    exit 1
fi

INPUT_SUFFIX="$USER_INPUT"
TARGET_DIR="attendance_tracker_${INPUT_SUFFIX}"

# Robust error checking for existing directory structures
if [ -d "$TARGET_DIR" ]; then
    echo "[Error] A directory named '$TARGET_DIR' already exists."
    read -p "Would you like to overwrite it? (y/N): " OVERWRITE
    if [[ "$OVERWRITE" =~ ^[Yy]$ ]]; then
        echo "[*] Purging pre-existing directory..."
        rm -rf "$TARGET_DIR"
    else
        echo "[Action Cancelled] Terminating deployment to preserve existing data."
        exit 1
    fi
fi

# ------------------------------------------------------------------------------
# PHASE 2: Directory Architecture Generation
# ------------------------------------------------------------------------------
echo "[*] Creating project architecture for: $TARGET_DIR..."
if mkdir -p "$TARGET_DIR/Helpers" && mkdir -p "$TARGET_DIR/reports"; then
    echo "[+] Directories successfully instantiated."
else
    echo "[Error] Critical Failure: Permissions denied or directory creation failed."
    exit 1
fi

# ------------------------------------------------------------------------------
# PHASE 3: Inline File Production (Sourcing code templates)
# ------------------------------------------------------------------------------
echo "[*] Populating baseline application architecture files..."

# Write config.json
cat << 'EOF' >"$TARGET_DIR/Helpers/config.json"
{
    "thresholds": {
        "warning": 75,
        "failure": 50
    },
    "run_mode": "live",
    "total_sessions": 15
} 
 
EOF

# Write assets.csv
cat << 'EOF' > "$TARGET_DIR/Helpers/assets.csv"
Email,Names,Attendance Count,Absence Count
alice@example.com,Alice Johnson,14,1
bob@example.com,Bob Smith,7,8
charlie@example.com,Charlie Davis,4,11
diana@example.com,Diana Prince,15,0
EOF

# Write reports.log
cat << 'EOF' > "$TARGET_DIR/reports/reports.log"
--- Attendance Report Run: 2026-02-06 18:10:01.468726 ---
[2026-02-06 18:10:01.469363] ALERT SENT TO bob@example.com: URGENT: Bob Smith, your attendance is 46.7%. You will fail this class.
[2026-02-06 18:10:01.469424] ALERT SENT TO charlie@example.com: URGENT: Charlie Davis, your attendance is 26.7%. You will fail this class.
EOF

# Write attendance_checker.py
cat << 'EOF' > "$TARGET_DIR/attendance_checker.py"
import csv
import json
import os
from datetime import datetime

def run_attendance_check():
    # 1. Load Config
    with open('Helpers/config.json', 'r') as f:
        config = json.load(f)
    
    # 2. Archive old reports.log if it exists
    if os.path.exists('reports/reports.log'):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        os.rename('reports/reports.log', f'reports/reports_{timestamp}.log.archive')

    # 3. Process Data
    with open('Helpers/assets.csv', mode='r') as f, open('reports/reports.log', 'w') as log:
        reader = csv.DictReader(f)
        total_sessions = config['total_sessions']
        
        log.write(f"--- Attendance Report Run: {datetime.now()} ---\n")
        
        for row in reader:
            name = row['Names']
            email = row['Email']
            attended = int(row['Attendance Count'])
            
            # Simple Math: (Attended / Total) * 100
            attendance_pct = (attended / total_sessions) * 100
            
            message = ""
            if attendance_pct < config['thresholds']['failure']:
                message = f"URGENT: {name}, your attendance is {attendance_pct:.1f}%. You will fail this class."
            elif attendance_pct < config['thresholds']['warning']:
                message = f"WARNING: {name}, your attendance is {attendance_pct:.1f}%. Please be careful."
            
            if message:
                if config['run_mode'] == "live":
                    log.write(f"[{datetime.now()}] ALERT SENT TO {email}: {message}\n")
                    print(f"Logged alert for {name}")
                else:
                    print(f"[DRY RUN] Email to {email}: {message}")

if __name__ == "__main__":
    run_attendance_check()
EOF

# Make python file executable
chmod +x "$TARGET_DIR/attendance_checker.py"
echo "[+] Application source files built successfully."

# ------------------------------------------------------------------------------
# PHASE 4: Dynamic Configuration via Stream Editing (sed)
# ------------------------------------------------------------------------------
echo -e "\n=== Configuration Settings Adjustment ==="
read -p "Do you want to update the default attendance thresholds? (y/N): " UPDATE_CONF

if [[ "$UPDATE_CONF" =~ ^[Yy]$ ]]; then
    # Prompt and Validate Warning Threshold
    read -p "Enter new Warning threshold percentage (default 75): " WARN_INPUT
    WARN_INPUT=${WARN_INPUT:-75} # Fallback to default if blank
    
    if [[ ! "$WARN_INPUT" =~ ^[0-9]+$ ]] || [ "$WARN_INPUT" -lt 0 ] || [ "$WARN_INPUT" -gt 100 ]; then
        echo "[Error] Invalid input: Threshold must be an integer between 0 and 100. Aborting."
        exit 1
    fi

    # Prompt and Validate Failure Threshold
    read -p "Enter new Failure threshold percentage (default 50): " FAIL_INPUT
    FAIL_INPUT=${FAIL_INPUT:-50} # Fallback to default if blank
    
    if [[ ! "$FAIL_INPUT" =~ ^[0-9]+$ ]] || [ "$FAIL_INPUT" -lt 0 ] || [ "$FAIL_INPUT" -gt 100 ]; then
        echo "[Error] Invalid input: Threshold must be an integer between 0 and 100. Aborting."
        exit 1
    fi

    # Execute safe, platform-agnostic in-place edits using sed
    # Handles both Linux and macOS sed variants via a clean substitution swap
    if sed --version >/dev/null 2>&1; then
        # GNU Sed (Linux standard)
        sed -i "s/\"warning_threshold\": [0-9]*/\"warning_threshold\": $WARN_INPUT/g" "$TARGET_DIR/Helpers/config.json"
        sed -i "s/\"failure_threshold\": [0-9]*/\"failure_threshold\": $FAIL_INPUT/g" "$TARGET_DIR/Helpers/config.json"
    else
        # BSD Sed (macOS standard)
        sed -i '' "s/\"warning_threshold\": [0-9]*/\"warning_threshold\": $WARN_INPUT/g" "$TARGET_DIR/Helpers/config.json"
        sed -i '' "s/\"failure_threshold\": [0-9]*/\"failure_threshold\": $FAIL_INPUT/g" "$TARGET_DIR/Helpers/config.json"
    fi
    echo "[+] Configuration updated successfully inside config.json."
else
    echo "[*] Retaining baseline default warning thresholds."
fi

# ------------------------------------------------------------------------------
# PHASE 5: Environment Validation & Health Check
# ------------------------------------------------------------------------------
echo -e "\n=== System Environment Health Check ==="

# Rule Requirement Check: verify python3 availability
if command -v python3 >/dev/null 2>&1; then
    PY_VERSION=$(python3 --version)
    echo "[SUCCESS] Environment validated: $PY_VERSION is available on this host."
else
    echo "[WARNING] Critical dependency 'python3' was not found in your system PATH."
    echo "          Please install Python3 to execute the internal application logic."
fi

# Assert structure validation match
if [ -f "$TARGET_DIR/attendance_checker.py" ] && \
   [ -f "$TARGET_DIR/Helpers/config.json" ] && \
   [ -f "$TARGET_DIR/Helpers/assets.csv" ] && \
   [ -f "$TARGET_DIR/reports/reports.log" ]; then
    echo "[SUCCESS] Structural Integrity Verification: Pass. Architecture matches specification."
else
    echo "[CRITICAL] Structural Integrity Verification: Fail. Missing output assets."
    exit 1
fi

echo -e "\n[Deployment Complete] Project 'workspace: $TARGET_DIR' setup successfully.\n"
