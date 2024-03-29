#!/bin/bash

LAST_COMMIT_INFO=$(curl -s "https://api.github.com/repos/forcedotcom/salesforcedx-vscode/commits?sha=develop&path=packages%2Fsalesforcedx-vscode-apex%2Fout%2Fapex-jorje-lsp.jar&page=1&per_page=1")
LAST_COMMIT_DATE=$(echo "$LAST_COMMIT_INFO" | jq -r '.[0].commit.committer.date')
LAST_COMMIT_SHA=$(echo "$LAST_COMMIT_INFO" | jq -r '.[0].sha')

VERSION=${LAST_COMMIT_DATE%T*}-${LAST_COMMIT_SHA:0:6}

URL=https://raw.githubusercontent.com/forcedotcom/salesforcedx-vscode/${LAST_COMMIT_SHA}/packages/salesforcedx-vscode-apex/out/apex-jorje-lsp.jar
FILENAME=apex-jorje-lsp-${VERSION}.jar
FILENAME_MINIMIZED=apex-jorje-lsp-min-${VERSION}.jar

REPOPATH=$(dirname "$0")

function deleteoldrepo() {
    git rm -r "${REPOPATH}"/apex/apex-jorje-lsp-min/*
}

function install() {
    mvn install:install-file -Dfile="${FILENAME_MINIMIZED}" \
                             -DgroupId=com.github.nawforce \
                             -DartifactId=apex-jorje \
                             -Dversion="${VERSION}" \
                             -Dpackaging=jar \
                             -DlocalRepositoryPath="${REPOPATH}"
    git add ${REPOPATH}
}

function download() {
    curl -o "$FILENAME" "$URL"
}


function minimize() {
    unzip -d temp "${FILENAME}"
    pushd temp || exit 1
    find . -not -path "." \
        -and -not -path ".." \
        -and -not -path "./apex" \
        -and -not -path "./apex/*" \
        -and -not -path "./StandardApex*" \
        -and -not -path "./messages*" \
        -and -not -path "./com" \
        -and -not -path "./com/google" \
        -and -not -path "./com/google/common*" \
        -print0 | xargs -0 rm -rf
    popd || exit 1
    jar cvf "${FILENAME_MINIMIZED}" -C temp/ .
    rm -rf temp
}

function dont_minimize() {
    cp "${FILENAME}" "${FILENAME_MINIMIZED}"
}

function cleanup() {
    rm "${FILENAME}"
    rm "${FILENAME_MINIMIZED}"
}

function updateversion() {
    sed -i -e "s/\(<apex\.jorje\.version>\).*\(<\/apex\.jorje\.version>\)/\1${VERSION}\2/" $(dirname $0)/../pom.xml
    git add $(dirname $0)/../pom.xml
}

download
dont_minimize
deleteoldrepo
install
updateversion
cleanup
