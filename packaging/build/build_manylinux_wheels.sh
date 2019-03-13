pushd .

cd ..

git clone $LIBYAML_REPO_URL libyaml
cd libyaml
git reset --hard $LIBYAML_REFSPEC --

./bootstrap
./configure

make

popd
# now back in pyyaml checkout

# docker pull quay.io/pypa/manylinux1_x86_64
# run below in container for each python in /opt/python/cpXX*/bin/python

${python} -m pip install cython --upgrade
# nuke everything but the wheelhouse dir if present; that's our output
git clean -fdx -e wheelhouse
${python} setup.py --with-libyaml build_ext -f -I ../libyaml/include -L ../libyaml/src/.libs test bdist_wheel
# patch up the wheel and embed the native library
LD_LIBRARY_PATH=$(readlink -f ../libyaml)/src/.libs auditwheel repair dist/*
