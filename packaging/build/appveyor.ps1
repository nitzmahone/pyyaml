# TODO: get version number from setup.py
# Update-AppveyorBuild -Version $dynamic_version

Get-Location
# TODO: get pyyaml-tied libyaml version from branch SoT
$libyaml_refspec = "0.2.1"
git clone -b $libyaml_refspec https://github.com/yaml/libyaml.git
mkdir build_output
cd build_output
cmake.exe ..\libyaml -DBUILD_SHARED_LIBS=ON
cmake.exe --build . --config Release --clean-first
# TODO: run libyaml tests
cd ..
C:\%PYTHON_VER%\python.exe -m pip install wheel
C:\%PYTHON_VER%\python.exe -m pip install cython
C:\%PYTHON_VER%\python.exe setup.py --with-libyaml build_ext -I .\libyaml\include -L .\%PYTHON_VER%\build;.\%PYTHON_VER%\build\Release build test bdist_wininst bdist_wheel
