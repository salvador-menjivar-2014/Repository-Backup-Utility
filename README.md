# Google Cloud Source Repository Backup Utility

This repository contains a robust Bash script designed to create complete, portable backups of repositories hosted on Google Cloud Source Repositories (CSR).

It is engineered to be resilient, successfully backing up repositories even if they have server-side configuration issues, such as a misconfigured or broken default branch.

## The Problem This Solves

Standard backup methods like `git clone --mirror` can fail if the source repository has a broken `HEAD` reference (a pointer to its default branch). The `--mirror` command, being a perfect replica, faithfully copies this broken reference, resulting in a backup that is difficult or impossible to restore using standard `git clone` commands.

This script was developed to overcome this specific challenge, ensuring a reliable backup can be created from any repository, regardless of its `HEAD` configuration.

## How It Works: The "Git Bundle" Method

Instead of creating a mirrored directory structure, this script uses the `git bundle` command. This approach has several key advantages:

1.  **Resilience:** It performs a standard `git clone`, which successfully downloads all repository data even if the default branch is misconfigured.
2.  **Portability:** It packages the entire repository—every commit, branch, and tag—into a **single, self-contained binary file** (a `.bundle`).
3.  **Reliability:** This `.bundle` file is a complete, valid Git repository that can be cloned reliably, as it does not depend on the original server's broken configuration.

The script automates this process for multiple repositories across multiple GCP projects.

## Features

- **Multi-Project & Multi-Repo:** Easily configure lists of repositories from different GCP projects.
- **Robust Error Handling:** Uses `set -e` and `set -u` to stop immediately on any command failure, preventing partial or corrupt uploads.
- **Clean and Safe:** Operates in a temporary, timestamped directory and cleans up all local files upon completion.
- **Efficient Uploads:** Uses `gsutil -m rsync` for parallel, efficient, and reliable uploads to Google Cloud Storage.

## How to Use

1.  **Prerequisites:**
    -   Google Cloud SDK (`gcloud`, `gsutil`) installed and authenticated.
    -   Git installed.
    -   Permissions to read from the source repositories and write to the target GCS bucket.

2.  **Configuration:**
    -   Open the `backup_csr_repositories.sh` script.
    -   Update the `TARGET_BUCKET` variable with the name of your GCS bucket.
    -   Update the `PROJECT_1`, `REPOS_1`, `PROJECT_2`, `REPOS_2`, etc., variables with your specific GCP project IDs and repository names.

3.  **Execution:**
    -   Make the script executable:
        ```bash
        chmod +x backup_csr_repositories.sh
        ```
    -   Run the script:
        ```bash
        ./backup_csr_repositories.sh
        ```

## How to Restore from a Backup

Restoring from a `.bundle` file is simple and reliable.

1.  **Download the bundle file from GCS:**
    ```bash
    gsutil cp gs://[YOUR-GCS-BUCKET-NAME]/code-bundle/repository-name-1.bundle .
    ```

2.  **Clone the bundle file:**
    This unpacks the bundle into a normal, working Git directory.
    ```bash
    git clone repository-name-1.bundle my-restored-repo
    ```

3.  **Access your code:**
    ```bash
    cd my-restored-repo
    git branch -a
    git checkout main
    ls
    ```
