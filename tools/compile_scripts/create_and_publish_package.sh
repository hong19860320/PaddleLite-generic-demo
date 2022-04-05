#!/bin/bash
set -e

source settings.sh

cd $ROOT_DIR/.. && tar -czvf PaddleLite-generic-demo.tar.gz --exclude=".git" --exclude="tools/compile_scripts/src" --exclude="tools/compile_scripts/sdk" --exclude="tools/compile_scripts/settings.sh" --exclude="*.nb" --exclude="assets/models/*" --exclude="log.txt" PaddleLite-generic-demo

echo "all done."
