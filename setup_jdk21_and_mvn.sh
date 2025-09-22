# Check if sdk command is available
echo "[INFO] Checking if 'sdk' command is available..."
if ! command -v sdk >/dev/null 2>&1; then
  echo "[ERROR] 'sdk' command not found after SDKMAN load. Exiting."
  exit 1
fi
echo "[INFO] 'sdk' command is available."
#!/bin/bash

set -eo pipefail

echo "[INFO] Script started."
# Install SDKMAN if not already installed in either $HOME or /usr/local
if [ ! -d "$HOME/.sdkman" ] && [ ! -d "/usr/local/sdkman" ]; then
  echo "[INFO] Installing SDKMAN..."
  curl -fsSL "https://get.sdkman.io" | bash
else
  echo "[INFO] SDKMAN already installed."
fi
echo "[INFO] SDKMAN install check complete."



# Load SDKMAN into the current shell session (try $HOME, then /usr/local)
echo "[INFO] Loading SDKMAN into current shell session..."
if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
  export SDKMAN_DIR="$HOME/.sdkman"
  source "$HOME/.sdkman/bin/sdkman-init.sh"
elif [ -s "/usr/local/sdkman/bin/sdkman-init.sh" ]; then
  export SDKMAN_DIR="/usr/local/sdkman"
  source "/usr/local/sdkman/bin/sdkman-init.sh"
else
  echo "[ERROR] SDKMAN init script not found. Exiting."
  exit 1
fi
# Ensure sdk is in PATH
export PATH="$SDKMAN_DIR/bin:$PATH"
echo "[INFO] SDKMAN loaded."





# Find the latest Java 21 Temurin version (robust to SDKMAN output changes)
echo "[INFO] Finding latest Java 21 Temurin identifier..."
echo "[DEBUG] Raw output of 'sdk list java':"
sdk list java
echo "[DEBUG] End of 'sdk list java' output."
LATEST_JAVA21_TEM=$(sdk list java | \
  grep -E '\|\s*21(\.[0-9]+)*\.\d+-tem\s*\|' | \
  grep -vE '\|\s*(fx|ea|rc|open|j9|graalvm)' | \
  awk -F '|' '{
    for (i=1; i<=NF; i++) {
      if ($i ~ /tem$/) {
        gsub(/^[ \t]+|[ \t]+$/, "", $i);
        print $i;
      }
    }
  }' | sort -V | tail -1)
echo "[INFO] Latest Java 21 Temurin identifier: $LATEST_JAVA21_TEM"
if [ -z "$LATEST_JAVA21_TEM" ]; then
  echo "[ERROR] Could not determine latest Java 21 Temurin identifier from SDKMAN output." >&2
  exit 1
fi
echo "[INFO] Java identifier check complete."


# Install and set as default, auto-confirming prompts
echo "[INFO] Installing Java $LATEST_JAVA21_TEM..."
sdk install java "$LATEST_JAVA21_TEM" -y
sdk default java "$LATEST_JAVA21_TEM"
echo "[INFO] Java $LATEST_JAVA21_TEM installed and set as default."
echo "[INFO] Java install complete."


# Print Java version for verification
echo "[INFO] Java version after install:"
java -version
echo "[INFO] Java version check complete."


# Run Maven install (ensure Maven exists; batch mode for CI/IDE logs)
echo "[INFO] Checking for Maven installation..."
if ! command -v mvn >/dev/null 2>&1; then
  echo "[INFO] Installing Maven..."
  sdk install maven -y
else
  echo "[INFO] Maven already installed."
fi
echo "[INFO] Maven install check complete."
echo "[INFO] Running Maven build..."
mvn -B -ntp install
echo "[INFO] Maven build complete."
