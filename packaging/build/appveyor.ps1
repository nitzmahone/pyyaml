# TODO: get version number from setup.py
# Update-AppveyorBuild -Version $dynamic_version

If($env:PYTHON_VER -match "^Python37") {
    # ensure py37 is present (current Appveyor VS2015 image doesn't include it)
    If(-not $(Test-Path C:\Python37)) {
        choco.exe install python3 --version=3.7.0 --forcex86 --force --install-arguments="TargetDir=C:\Python37 PrependPath=0"
    }

    If(-not $(Test-Path C:\Python37-x64)) {
        choco.exe install python3 --version=3.7.0 --force --install-arguments="TargetDir=C:\Python37-x64 PrependPath=0"
    }
}

$python_path = Join-Path C:\ $env:PYTHON_VER
$python = Join-Path $python_path python.exe

$python_vs_buildver = & $python -c "from distutils.version import LooseVersion; from distutils.msvc9compiler import get_build_version; print(LooseVersion(str(get_build_version())).version[0])"

$python_cmake_generator = switch($python_vs_buildver) {
    "9" { "Visual Studio 9 2008" }
    "10" { "Visual Studio 10 2010" }
    "14" { "Visual Studio 14 2015" }
    default { throw "Python was built with unknown VS build version: $python_vs_buildver" }
}

$python_arch = & $python -c "from distutils.util import get_platform; print(str(get_platform()))"

if($python_arch -eq 'win-amd64') {
    $python_cmake_generator += " Win64"
    $vcvars_arch = "x64"
}

# patch 7.0/7.1 vcvars SDK bits up to work with distutils query
Set-Content -Path 'C:\Program Files (x86)\Microsoft Visual Studio 9.0\VC\bin\amd64\vcvarsamd64.bat' '@CALL "C:\Program Files (x86)\Microsoft Visual Studio 9.0\VC\bin\vcvars64.bat"'
Set-Content -Path 'C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\bin\amd64\vcvars64.bat' '@CALL "C:\Program Files\Microsoft SDKs\Windows\v7.1\Bin\SetEnv.cmd" /Release /x64'

# patch VS9 x64 CMake config for VS Express
reg.exe import packaging\build\FixVS9CMake.reg
Copy-Item -Path "C:\Program Files (x86)\Microsoft Visual Studio 9.0\VC\vcpackages\AMD64.VCPlatform.config" -Destination "C:\Program Files (x86)\Microsoft Visual Studio 9.0\VC\vcpackages\AMD64.VCPlatform.Express.config" -Force
Copy-Item -Path "C:\Program Files (x86)\Microsoft Visual Studio 9.0\VC\vcpackages\Itanium.VCPlatform.config" -Destination "C:\Program Files (x86)\Microsoft Visual Studio 9.0\VC\vcpackages\Itanium.VCPlatform.Express.config" -Force

# snarf VS vars (paths, etc) for the matching VS version and arch that built this Python
$raw_vars_out = & cmd.exe /c "`"C:\Program Files (x86)\Microsoft Visual Studio $($python_vs_buildver).0\VC\vcvarsall.bat`" $vcvars_arch & set"
foreach($kv in $raw_vars_out) {
    If($kv -match "=") {
        $kv = $kv.Split("=", 2)
        Set-Item -Force "env:$kv[0]" $kv[1]
    }
    Else {
        Write-Output $kv
    }
}

# ensure pip is current (some appveyor pips are not)
& $python -m pip install --upgrade pip

# ensure Cython and wheel are present and up-to-date
& $python -m pip install --upgrade cython wheel

# TODO: get pyyaml-tied libyaml version from branch SoT
$libyaml_refspec = "0.1.7"
git clone -b $libyaml_refspec https://github.com/yaml/libyaml.git

mkdir libyaml\build
cd libyaml\build
cmake.exe -G $python_cmake_generator ..
cmake.exe --build . --config Release

cd ..\..

& $python setup.py --with-libyaml build_ext -I libyaml\include -L libyaml\build\Release -D YAML_DECLARE_STATIC build test bdist_wheel

$artifacts = @(Resolve-Path dist\*.whl)

If($artifacts.Length -eq 1) {
    Push-AppveyorArtifact $artifacts[0]
}
