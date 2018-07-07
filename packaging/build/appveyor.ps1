# TODO: get version number from setup.py
# Update-AppveyorBuild -Version $dynamic_version

# patch 7.0/7.1 vcvars SDK bits up to work with distutils query
#Set-Content -Path 'C:\Program Files (x86)\Microsoft Visual Studio 9.0\VC\bin\amd64\vcvarsamd64.bat' '@CALL "C:\Program Files (x86)\Microsoft Visual Studio 9.0\VC\bin\vcvars64.bat"'
#Set-Content -Path 'C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\bin\amd64\vcvars64.bat' '@CALL "C:\Program Files\Microsoft SDKs\Windows\v7.1\Bin\SetEnv.cmd" /Release /x64'


# patch VS9 x64 CMake config

regedit.exe /s FixVS9CMake.reg
Copy-Item -Path "C:\Program Files (x86)\Microsoft Visual Studio 9.0\VC\vcpackages\AMD64.VCPlatform.config" -Destination "C:\Program Files (x86)\Microsoft Visual Studio 9.0\VC\vcpackages\AMD64.VCPlatform.Express.config"
Copy-Item -Path "C:\Program Files (x86)\Microsoft Visual Studio 9.0\VC\vcpackages\Itanium.VCPlatform.config" -Destination "C:\Program Files (x86)\Microsoft Visual Studio 9.0\VC\vcpackages\Itanium.VCPlatform.Express.config"

# TODO: get pyyaml-tied libyaml version from branch SoT
$libyaml_refspec = "0.1.7"
git clone -b $libyaml_refspec https://github.com/yaml/libyaml.git
#mkdir build_output
#cd build_output

# TODO: build libyaml using the same SDK/CRT as the associated Python version
#cmake.exe ..\libyaml -DBUILD_SHARED_LIBS=ON
#cmake.exe --build . --config Release

# TODO: run libyaml tests
#cd ..
#& C:\$env:PYTHON_VER\python.exe -m pip install wheel
#& C:\$env:PYTHON_VER\python.exe -m pip install cython
#& C:\$env:PYTHON_VER\python.exe setup.py --with-libyaml build_ext -I .\libyaml\include -L .\build_output\Release build test bdist_wininst bdist_wheel
