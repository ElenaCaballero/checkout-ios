#!/bin/bash

# Git Hook for SwiftLint 
# Runs at every commit and checks for an error.
# For the test, you can run `git commit` with an empty` commit message`

export PATH=/usr/local/bin:$PATH

LINT=""

# If SwiftLint installed globally
if [[ -e "$(which swiftlint)" ]]; then
	LINT=$(which swiftlint)
# If SwiftLint installed via CocoaPods
elif [[ -e "Pods/SwiftLint/swiftlint" ]]; then
	LINT="Pods/SwiftLint/swiftlint"
else
	echo "SwiftLint does not exist, download from https://github.com/realm/SwiftLint"
	exit 1
fi

RESULT=$($LINT lint --quiet --config .swiftlint.yml)

if [ "$RESULT" == '' ]; then
	printf "SwiftLint Finished.\n"
else
	echo ""
	printf "SwiftLint Failed. Please check below:\n"

	while read -r line; do
		FILEPATH=$(echo $line | cut -d : -f 1)
		L=$(echo $line | cut -d : -f 2)
		C=$(echo $line | cut -d : -f 3)
		TYPE=$(echo $line | cut -d : -f 4 | cut -c 2-)
		MESSAGE=$(echo $line | cut -d : -f 5 | cut -c 2-)
		DESCRIPTION=$(echo $line | cut -d : -f 6 | cut -c 2-)
		printf "\n $TYPE\n"
		printf "    $FILEPATH:$L:$C\n"
		printf "    $MESSAGE - $DESCRIPTION\n"
	done <<< "$RESULT"

	printf "\nCOMMIT ABORTED. Please fix them before commiting.\n"

	exit 1
fi