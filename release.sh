#!/bin/sh

cd `dirname ${0}`

repo="https://github.com/bikkelbroeders/TouchBarDemoApp"
name="Touch Bar Demo App"
project="TouchBar.xcodeproj"
app="TouchBarServer"

git diff-index --quiet HEAD --
if [ ${?} -ne 0 ]
then
    echo 1>&2 "Error: uncomitted changes found; please commit, discard or stash them first."
    exit 1
fi

plist=`pwd`"/${app}/Info"
previous_version=`defaults read "${plist}" CFBundleShortVersionString`

version="${1}"
if [ -z "${version}" ]
then
    major=`echo "${previous_version}" | cut -d. -f1`
    minor=`echo "${previous_version}" | cut -d. -f2`
    minor=`echo ${minor}+1 | bc`
    version="${major}.${minor}"
fi

version=`echo ${version} | sed 's/^v//'`

set -e
set -x

# Put new version in the app plist
plutil -replace CFBundleShortVersionString -string "${version}" "${app}/Info.plist"

# Build release archive
xcodebuild -quiet -project "${project}" -archivePath "${app}" -scheme "${app}" archive

# Zip the app
zip=`pwd`"/${app}.zip"
pushd "${app}.xcarchive/Products/Applications" > /dev/null
zip -q -r "${zip}" "${app}.app"
popd > /dev/null

# Store the dSYM for debugging
rm -Rf "Debug/${app}.app.dSYM"
mv "${app}.xcarchive/dSYMs/${app}.app.dSYM" Debug/

# Remove the created archive
rm -Rf "${app}.xcarchive"

# Make a release commit + tag
git add Debug/
git add "${app}/Info.plist"
git commit -q -m "Release v${version}"
git tag "v${version}"

set +x

# Print info
echo
echo "Finished creating release v${version} !"
echo
echo "Changes:"
git log "v${previous_version}..v${version}^" --oneline
echo
echo "To publish this release:"
echo "  git push -u origin master --tags"
echo "  open ${repo}/releases/new?tag=v${version}"
echo "    # use release title '${name} v${version}'"
echo "    # attach ${app}.zip"
echo
echo "To undo this release (only while not yet published!):"
echo "  git tag -d v${version}"
echo "  git reset --hard HEAD^"
echo "  rm ${app}.zip"
