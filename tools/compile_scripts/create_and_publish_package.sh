#!/bin/bash
set -e

readlinkf() {
  perl -MCwd -e 'print Cwd::abs_path shift' "$1";
}

root_dir=$(dirname $(readlinkf "$0/../../../"))

cd $root_dir
tar -czvf PaddleLite-generic-demo.tar.gz --exclude=".git" --exclude="projects" PaddleLite-generic-demo

echo "all done."
