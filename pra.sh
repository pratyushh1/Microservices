#!/bin/bash

# Set variables
RELEASE_BRANCH="release/25.03.100"
TARGET_BRANCH="master"
GITHUB_TOKEN='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'

# Navigate to Jenkins workspace where the repo is already checked out
cd $WORKSPACE || exit 1

# Ensure we are on the latest commit
git fetch origin ${TARGET_BRANCH}
git fetch origin ${RELEASE_BRANCH}

# Checkout master branch
git checkout ${TARGET_BRANCH} || { echo "❌ Failed to checkout master"; exit 1; }

# Merge the release branch into master
git merge --no-ff origin/${RELEASE_BRANCH} -m "Merging ${RELEASE_BRANCH} into ${TARGET_BRANCH}"
MERGE_STATUS=$?

if [ $MERGE_STATUS -ne 0 ]; then
    echo "⚠️ Merge conflict detected! Creating a Merge Request instead..."
    
    # Abort merge to keep repo clean
    git merge --abort

    # Create a pull request via GitHub API
    PR_RESPONSE=$(curl -s -X POST -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        https://api.github.com/repos/pratyushh1/Microservices/pulls \
        -d "{
            \"title\": \"Merge ${RELEASE_BRANCH} into ${TARGET_BRANCH}\",
            \"head\": \"${RELEASE_BRANCH}\",
            \"base\": \"${TARGET_BRANCH}\",
            \"body\": \"Auto-created MR because merge failed due to conflicts.\"
        }")

    PR_URL=$(echo $PR_RESPONSE | grep -o '"html_url": "[^"]*' | cut -d '"' -f 4)

    if [ -z "$PR_URL" ]; then
        echo "❌ Failed to create a Merge Request. Please check manually!"
        exit 1
    else
        echo "✅ Merge Request created successfully: $PR_URL"
    fi
else
    # Push the merged changes if merge was successful
    git push origin ${TARGET_BRANCH} || { echo "❌ Failed to push merged changes!"; exit 1; }
    echo "✅ Successfully merged ${RELEASE_BRANCH} into ${TARGET_BRANCH} and pushed to remote!"
fi
