#!/bin/bash

# Input parameters from Jenkins job
RELEASE_BRANCH="$1"
ALL_MICROS="$2"

# Define repo path (assuming all microservices are in a shared folder)
REPO_BASE="github.com/pratyushh1/Microservices"

# Initialize lists
MERGED_MRS=()
NOT_MERGED_MRS=()

# Fetch microservices having the release branch
if [[ "$ALL_MICROS" == "true" ]]; then
    MICROS=($(find "$REPO_BASE" -maxdepth 1 -type d | xargs -I {} basename {}))
else
    # If not "All micros", manually select them (modify logic as needed)
    MICROS=("microservice-1" "microservice-2") # Placeholder: Replace with actual logic
fi

echo "Processing the following microservices: ${MICROS[@]}"

# Loop through each microservice
for MICRO in "${MICROS[@]}"; do
    cd "$REPO_BASE/$MICRO" || continue
    
    # Check if release branch exists in the repo
    if git show-ref --verify --quiet "refs/heads/$RELEASE_BRANCH"; then
        echo "Merging $RELEASE_BRANCH into master for $MICRO"
        
        git checkout master
        git pull origin master
        git merge --no-ff "$RELEASE_BRANCH" -m "Merging $RELEASE_BRANCH into master"
        
        if [[ $? -eq 0 ]]; then
            git push origin master
            echo "✅ Merged $MICRO"
            MERGED_MRS+=("$MICRO")
        else
            echo "❌ Merge conflict in $MICRO. Manual intervention required."
            NOT_MERGED_MRS+=("$MICRO")
            git merge --abort
        fi
    else
        echo "🚫 Release branch $RELEASE_BRANCH not found in $MICRO"
        NOT_MERGED_MRS+=("$MICRO")
    fi
done

# Summary of merged & not merged MRs
echo "----------------------"
echo "✅ Successfully Merged:"
printf '%s\n' "${MERGED_MRS[@]}"

echo "----------------------"
echo "❌ Not Merged (Check manually):"
printf '%s\n' "${NOT_MERGED_MRS[@]}"
