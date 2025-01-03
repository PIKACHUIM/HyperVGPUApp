import sys
import os
from cx_Freeze import setup, Executable

# ADD FILES
add_files = [
    ("./Modules/", "lib/PSSParsing/"),
    ("./Configs/", ""),
    ("./DDATool/", ""),
    ("./Scripts/", ""),
    ("./UpdatePV.ps1", ""),
    ("./CheckDDA.ps1", ""),
    ("./CheckGPU.ps1", ""),
    ("./CreateVM.ps1", ""),
    ("./CreateVM.ps1", ""),
    ("./DDATools.exe", ""),

    ("./UpdateDS.ps1", ""),
    ("./README.md", ""),
    ("./LICENSE", ""),

]
# TARGET
target = Executable(
    script="VGPUTool.py",
    # base="Win32GUI",
    icon="Configs/HyperVCreated.ico",
    uac_admin=True
)

# SETUP CX FREEZE
setup(
    name="Hyper-V GPU Virtualization Manage Tool",
    version="0.1.2024.1206",
    description="Hyper-V GPU Virtualization Manage Tool",
    author="Pikachu Ren",
    options={
        'build_exe': {
            'include_files': add_files,
            'include_path': [],
            'includes': [],
            "packages": [
                "ttkbootstrap.utility",
                "ttkbootstrap",
            ],
            # "include_symbols": True,
            "include_msvcr": True,
            "excludes": []
        },

    },
    executables=[target],
)
