#!/bin/bash
#
# This script creates robust, self-contained .bundle backups of all specified
# Google Cloud Source Repositories. This method is resilient and works even
# for repositories with misconfigured or broken default branches.

# --- Configuration ---
#
# ACTION REQUIRED: Set this variable to the name of your GCS archive bucket.
#
TARGET_BUCKET="gs://[YOUR-GCS-BUCKET-NAME]"

# --- End of Configuration ---


# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error.
set -u

# Ensure gcloud credential helper is configured for Git
# This allows the script to authenticate using your gcloud login.
git config --global credential.https://source.developers.google.com.helper gcloud.sh

# --- Define Repositories to Back Up ---

# Repositories from the first project
PROJECT_1="[YOUR-FIRST-GCP-PROJECT-ID]"
REPOS_1=(
    "repository-name-1"
    "repository-name-2"
)

# Repositories from the second project
PROJECT_2="[YOUR-SECOND-GCP-PROJECT-ID]"
REPOS_2=(
    "repository-name-3"
    "repository-name-4"
)

# --- Script Execution ---

# Create a temporary directory to work in, ensuring a clean run every time.
WORK_DIR="csr-backup-bundle-$(date +%s)"
mkdir "$WORK_DIR"
cd "$WORK_DIR"

echo "Created temporary working directory: $(pwd)"

# --- Process Project 1 ---
echo ""
echo "--- Bundling Project: $PROJECT_1 ---"
for REPO in "${REPOS_1[@]}"; do
    echo "Cloning $REPO for bundling..."
    # A standard clone is used as a temporary step.
    # Warnings about a nonexistent HEAD ref are expected and handled.
    git clone "https://source.developers.google.com/p/$PROJECT_1/r/$REPO"
    
    echo "Creating bundle for $REPO..."
    cd "$REPO"
    # Create a self-contained bundle file containing all branches and history.
    git bundle create "../$REPO.bundle" --all
    cd ..
    
    # Clean up the temporary clone to save space before the next one.
    rm -rf "$REPO"
done

# --- Process Project 2 ---
echo ""
echo "--- Bundling Project: $PROJECT_2 ---"
for REPO in "${REPOS_2[@]}"; do
    echo "Cloning $REPO for bundling..."
    git clone "https://source.developers.google.com/p/$PROJECT_2/r/$REPO"
    
    echo "Creating bundle for $REPO..."
    cd "$REPO"
    git bundle create "../$REPO.bundle" --all
    cd ..

    rm -rf "$REPO"
done

echo ""
echo "--- Uploading all bundle files to $TARGET_BUCKET/code-bundle/ ---"
# Use gsutil rsync for a reliable, parallel upload. rsync will create the
# destination directory if it doesn't exist and efficiently sync the files.
gsutil -m rsync . "$TARGET_BUCKET/code-bundle/"

echo ""
echo "Cleaning up local directory..."
cd ..
rm -rf "$WORK_DIR"

echo "---"
echo "✅ Complete bundle backup is done."
echo "All repositories are now in $TARGET_BUCKET/code-bundle/"
