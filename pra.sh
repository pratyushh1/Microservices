#!/bin/bash

# Set variables
REPO_URL="https://github.com/your-org/microservices-repo.git"
RELEASE_BRANCH="release/25.03.100"
TARGET_BRANCH="master"

# Clean workspace to avoid conflicts
rm -rf *

# Clone the repository
git clone --depth 1 --branch ${TARGET_BRANCH} ${REPO_URL} repo
if [ $? -ne 0 ]; then
    echo "❌ Failed to clone repository! Check credentials and repo URL."
    exit 1
fi

cd repo

# Add remote and fetch the release branch
git remote add origin ${REPO_URL}
git fetch origin ${RELEASE_BRANCH}

# Checkout master branch
git checkout ${TARGET_BRANCH}

# Merge the release branch into master
git merge --no-ff origin/${RELEASE_BRANCH} -m "Merging ${RELEASE_BRANCH} into ${TARGET_BRANCH}"
if [ $? -ne 0 ]; then
    echo "❌ Merge conflict! Please resolve manually."
    exit 1
fi

# Push the merged changes to master
git push origin ${TARGET_BRANCH}
if [ $? -ne 0 ]; then
    echo "❌ Failed to push changes to master!"
    exit 1
fi

echo "✅ Successfully merged ${RELEASE_BRANCH} into ${TARGET_BRANCH} and pushed to remote!"
