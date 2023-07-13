#!/bin/bash

# Exit script if any command fails
set -e

# Values errors handler function
function ask_exit {
    echo "Do you want to continue anyway?" >&2
    echo "1. Continue anyway." >&2
    echo "2. Return to the variable entering." >&2
    echo "0. Exit." >&2
    read operation

    case $operation in
    0)
        exit 1
        ;;
    2)
        ($1 "$2")
        ;;
    esac
}

# Validation function for emails (availability and correctness)
function validate_email {
    EMAIL=$1
    NAME=$2

    if [ -z "$EMAIL" ]; then
        echo "$NAME is missing" >&2
        echo "$(ask_exit get "$NAME")"
    else
        if [[ $EMAIL != *?@*?.* ]]; then
            echo "The email '$EMAIL' seems to be in an incorrect format. It should include '@' and a domain name." >&2
            echo "$(ask_exit get "$NAME")"
        fi
    fi
}

# Validation function for just string (availability)
function validate_string {
    STRING=$1
    NAME=$2

    if [ -z "$STRING" ]; then
        echo "$NAME is missing" >&2
        echo "$(ask_exit get "$NAME")"
    fi
}

# CLI params getter handler function
function get {
    STRING=$1

    read -p "Enter the $STRING: " VAR

    if [[ "$STRING" == *"email"* ]]; then
        validate_email "$VAR" "$STRING"
    else
        validate_string "$VAR" "$STRING"
    fi

    echo "$VAR"
}

# Function to change the author of all commits
function change_author {
    NEW_NAME=$(get 'new name')
    NEW_EMAIL=$(get 'new email')

    echo "$NEW_EMAIL"

    git filter-branch -f --env-filter '
    export GIT_COMMITTER_NAME="'"$NEW_NAME"'"
    export GIT_COMMITTER_EMAIL="'"$NEW_EMAIL"'"
    export GIT_AUTHOR_NAME="'"$NEW_NAME"'"
    export GIT_AUTHOR_EMAIL="'"$NEW_EMAIL"'"
    ' --tag-name-filter cat -- --branches --tags
}

# Function to change the author of all commits by specific author
function change_specific_author {
    OLD_EMAIL=$(get 'old email')
    NEW_EMAIL=$(get 'new email')
    NEW_NAME=$(get 'new name')

    git filter-branch -f --env-filter '
    if [ "$GIT_COMMITTER_EMAIL" = "'"$OLD_EMAIL"'" ]
    then
        export GIT_COMMITTER_NAME="'"$NEW_NAME"'"
        export GIT_COMMITTER_EMAIL="'"$NEW_EMAIL"'"
    fi
    if [ "$GIT_AUTHOR_EMAIL" = "'"$OLD_EMAIL"'" ]
    then
        export GIT_AUTHOR_NAME="'"$NEW_NAME"'"
        export GIT_AUTHOR_EMAIL="'"$NEW_EMAIL"'"
    fi
    ' --tag-name-filter cat -- --branches --tags
}

# Function to confirm the operation
function confirm_operation {
    echo "This will rewrite history! Are you sure you want to continue? (y/n)"
    read response
    if [ "$response" != "y" ]; then
        echo "Operation cancelled"
        exit 1
    fi
}

# Function to choose mode of commits author changing
function choose_operation {
    echo "Choose the operation mode:"
    echo "1. Rewrite author of all commits."
    echo "2. Rewrite author of commits with specific author."
    read operation

    case $operation in
    1)
        change_author
        ;;
    2)
        change_specific_author
        ;;
    *)
        echo "Invalid option. Exiting."
        exit 1
        ;;
    esac
}

# Confirm before execution
confirm_operation

# Execute the operation
choose_operation

echo "Author changed successfully!"
