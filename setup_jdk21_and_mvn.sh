#!/bin/bash
set -eo pipefail
# Install SDKMAN if not already installed
if [ ! -d "$HOME/.sdkman" ]; then
  curl -fsSL "https://get.sdkman.io" | bash
fi


# Load SDKMAN into the current shell session (try $HOME, then /usr/local)
if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
  source "$HOME/.sdkman/bin/sdkman-init.sh"
elif [ -s "/usr/local/sdkman/bin/sdkman-init.sh" ]; then
  source "/usr/local/sdkman/bin/sdkman-init.sh"
else
  echo "SDKMAN init script not found. Exiting."
  exit 1
fi



# Find the latest Java 21 Temurin version
LATEST_JAVA21_TEM=$(
  sdk list java | awk -F '|' '
    /\|\s*Identifier\s*$/ { idcol=NF; next }
    idcol && $idcol ~ /21(\.[0-9]+)+-tem$/ {
      gsub(/^[ \t]+|[ \t]+$/, "", $idcol);
      print $idcol
    }
  ' | sort -V | tail -1
)
if [ -z "$LATEST_JAVA21_TEM" ]; then
  echo "Could not determine latest Java 21 Temurin identifier from SDKMAN output." >&2
  exit 1
fi
if [ -z "$LATEST_JAVA21_TEM" ]; then
  echo "No Java 21 Temurin version found via SDKMAN. Exiting."
  exit 1
fi

# Install and set as default, auto-confirming prompts
sdk install java "$LATEST_JAVA21_TEM" -y
sdk default java "$LATEST_JAVA21_TEM"

# Print Java version for verification
java -version

# Run Maven install
mvn install
