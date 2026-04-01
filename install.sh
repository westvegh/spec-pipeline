#!/bin/bash
# ============================================================================
# install.sh — Install spec-pipeline into a project
#
# Usage:
#   From the spec-pipeline repo:
#     ./install.sh /path/to/your/project
#
#   Or from your project root:
#     /path/to/spec-pipeline/install.sh .
# ============================================================================

set -uo pipefail

TARGET="${1:?Usage: ./install.sh /path/to/your/project}"

if [ ! -d "$TARGET" ]; then
  echo "Error: $TARGET is not a directory"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Copy pipeline script
cp "$SCRIPT_DIR/process-spec.sh" "$TARGET/process-spec.sh"
chmod +x "$TARGET/process-spec.sh"
echo "  Copied process-spec.sh"

# Copy slash command
mkdir -p "$TARGET/.claude/commands"
cp "$SCRIPT_DIR/.claude/commands/process-spec.md" "$TARGET/.claude/commands/process-spec.md"
echo "  Copied .claude/commands/process-spec.md"

# Add to .gitignore if not already there
if [ -f "$TARGET/.gitignore" ]; then
  if ! grep -q "^\.spec-pipeline/" "$TARGET/.gitignore" 2>/dev/null; then
    echo "" >> "$TARGET/.gitignore"
    echo "# Spec pipeline output" >> "$TARGET/.gitignore"
    echo ".spec-pipeline/" >> "$TARGET/.gitignore"
    echo "  Added .spec-pipeline/ to .gitignore"
  else
    echo "  .gitignore already has .spec-pipeline/"
  fi
else
  echo ".spec-pipeline/" > "$TARGET/.gitignore"
  echo "  Created .gitignore with .spec-pipeline/"
fi

echo ""
echo "  Done. From your project root:"
echo ""
echo "    # Run directly:"
echo "    ./process-spec.sh path/to/spec.md"
echo ""
echo "    # Or via Claude Code slash command:"
echo "    /process-spec path/to/spec.md"
echo ""
