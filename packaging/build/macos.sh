#!/bin/bash

set -eux

/usr/bin/python3 -V
/usr/bin/python3 -m pip install -U --user cibuildwheel
PYYAML_FORCE_CYTHON=1 PYYAML_FORCE_LIBYAML=1 CIBW_BEFORE_BUILD='pip install cython' /usr/bin/python3 -m cibuildwheel --platform macos .
mkdir -p dist
mv wheelhouse/* dist/
ls -1 dist/

#PYYAML_FORCE_CYTHON=1 PYYAML_FORCE_LIBYAML=1 CIBW_SKIP='pp* cp35*' CIBW_BUILD_VERBOSITY=1 CIBW_BEFORE_BUILD='pip install cython'
