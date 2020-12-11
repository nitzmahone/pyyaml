#!/bin/bash

set -eux

# FIXME: externalize the libyaml build for each container/arch as an ephemeral artifact
#./packaging/build/libyaml.sh

# PyYAML supports Python 2.7, 3.6-3.8
#for tag in $(echo $PYTHON_TAGS | tr ":" " "); do
#  PYBIN="/opt/python/${tag}/bin"
#  "${PYBIN}/python" -m pip install setuptools build==0.1.0 Cython auditwheel
#  "${PYBIN}/python" -m build \
#    --verbose \
#    --no-deps \
#    --global-option '--with-libyaml' \
#    --global-option "build_ext" \
#    -w wheelhouse .
#done

PYBIN="/opt/python/${PYTHON_TAG}/bin"

# modern tools don't allow us to pass eg, --with-libyaml, so we force it via env
export PYYAML_FORCE_CYTHON=1
export PYYAML_FORCE_LIBYAML=1

# we're using a private build of libyaml, so set paths to favor that instead of whatever's laying around
export C_INCLUDE_PATH=libyaml/include:${C_INCLUDE_PATH:-}
export LIBRARY_PATH=libyaml/src/.libs:${LIBRARY_PATH:-}
export LD_LIBRARY_PATH=libyaml/src/.libs:${LD_LIBRARY_PATH:-}

# install deps
echo "::group::installing build deps"
# FIXME: installing Cython here won't be necessary once we fix tests, since the build is PEP517 and declares its own deps
"${PYBIN}/python" -m pip install build==0.1.0 Cython
echo "::endgroup::"

if [[ ${PYYAML_RUN_TESTS:-1} -eq 1 ]]; then
  echo "::group::running test suite"
  # FIXME: split tests out for easier direct execution w/o Makefile
  # run full test suite
  make testall PYTHON="${PYBIN}/python"
  echo "::endgroup::"
else
  echo "skipping test suite..."
fi

if [[ ${PYYAML_BUILD_WHEELS:-0} -eq 1 ]]; then
  echo "::group::building wheels"
  "${PYBIN}/python" -m build -w -o tempwheel .
  echo "::endgroup::"

  echo "::group::validating wheels"
  # FIXME: smoke-test individual wheels by name/platform (no wildcard)
  for whl in tempwheel/*.whl; do
    auditwheel repair --plat "${AW_PLAT}" "$whl" -w dist/
  done

  ls -1 dist/

  echo "::endgroup::"
else
  echo "skipping wheel build..."
fi
