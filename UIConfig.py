import tkinter.filedialog

import ttkbootstrap as ttk
from functools import partial


class Function:
    @staticmethod
    def selectFile(in_type):
        file_path = tkinter.filedialog.askopenfilename(filetypes=in_type)
        return file_path

    @staticmethod
    def selectPath():
        file_path = tkinter.filedialog.askdirectory()
        return file_path


class UIConfig:
    line = 6  # 每个页面内允许放置的单元列数量
    page = {  # 每个页面元素详细排列内容和方式
        # 示例 *******************************

        # ************************************
        "gpv_init": {
            "vmx_name": {
                "entry": ttk.Entry,
                "start": None,
                "width": 60,
                "lines": 4,
                "color": "info",
                "addon": {
                    "auto": {
                        "entry": ttk.Checkbutton,
                        "start": None,
                        "width": 7,
                        "lines": 1,
                        "color": "success",
                    }
                }
            },
            "iso_file": {
                "entry": ttk.Entry,
                "start": None,
                "width": 60,
                "lines": 4,
                "color": "info",
                "addon": {
                    "open": {
                        "entry": ttk.Button,
                        "start": Function.selectPath,
                        "width": 7,
                        "lines": 1,
                        "color": "info",
                    }
                }
            },
            "vhd_path": {
                "entry": ttk.Entry,
                "start": None,
                "width": 60,
                "lines": 4,
                "color": "info",
                "addon": {
                    "open": {
                        "entry": ttk.Button,
                        "start": Function.selectPath,
                        "width": 7,
                        "lines": 1,
                        "color": "info",
                    }
                }
            },
            "ver_name": {
                "entry": ttk.Combobox,
                "start": None,
                "width": 7,
                "lines": 1,
                "color": "info",
                "value": [6],
                "addon": {}
            },
            "vhd_type": {
                "entry": ttk.Combobox,
                "start": None,
                "width": 7,
                "lines": 1,
                "color": "info",
                "value": ["VHDX", "VHD"],
                "addon": {}
            },
            "use_boot": {
                "entry": ttk.Combobox,
                "start": None,
                "width": 7,
                "lines": 1,
                "color": "info",
                "value": ["UEFI"],
                "addon": {}
            },
            "vhd_size": {
                "entry": ttk.Combobox,
                "start": None,
                "width": 7,
                "lines": 1,
                "color": "info",
                "value": ["20GB", "32GB", "64GB", "128GB"],
                "addon": {}
            },
            "mem_size": {
                "entry": ttk.Combobox,
                "start": None,
                "width": 7,
                "lines": 1,
                "value": ["4GB", "8GB", "16GB", "32GB", "64GB"],
                "color": "info",
                "addon": {}
            },
            "cpu_size": {
                "entry": ttk.Combobox,
                "start": None,
                "width": 7,
                "lines": 1,
                "color": "info",
                "value": [2, 4, 6, 8,
                          10, 12, 14, 16,
                          18, 20, 24, 32],
                "addon": {}
            },
            "gpu_name": {
                "entry": ttk.Combobox,
                "start": None,
                "width": 23,
                "lines": 2,
                "color": "info",
                "addon": {
                    "open": {
                        "entry": ttk.Button,
                        "start": Function.selectPath,
                        "width": 7,
                        "lines": 1,
                        "color": "secondary",
                    }
                }
            },
            "gpu_size": {
                "entry": ttk.Combobox,
                "start": None,
                "width": 7,
                "lines": 1,
                "color": "info",
                "value": [10, 20, 30, 40,
                          50, 60, 70, 80,
                          90, 95, 100, 5],
                "addon": {}
            },
            "par_name": {
                "entry": ttk.Entry,
                "start": None,
                "width": 25,
                "lines": 2,
                "color": "secondary",
                "addon": {}
            },
            "par_pass": {
                "entry": ttk.Entry,
                "start": None,
                "width": 26,
                "lines": 2,
                "color": "secondary",
                "addon": {}
            },
            "win_name": {
                "entry": ttk.Entry,
                "start": None,
                "width": 25,
                "lines": 2,
                "color": "secondary",
                "addon": {}
            },
            "win_pass": {
                "entry": ttk.Entry,
                "start": None,
                "width": 26,
                "lines": 2,
                "color": "secondary",
                "addon": {}
            },
            "bar_deal": {
                "entry": ttk.Progressbar,
                "start": None,
                "width": 400,
                "lines": 4,
                "color": "success-striped",
                "addon": {
                    "text": {
                        "entry": ttk.Label,
                        "start": None,
                        "width": 1,
                        "lines": 1,
                        "color": "light",
                    },
                    "exec": {
                        "entry": ttk.Button,
                        "start": None,
                        "width": 7,
                        "lines": 1,
                        "color": "primary",
                    }
                }
            },
        },
        "gpv_conf": {
            "not_good": {
                "entry": ttk.Label,
                "start": None,
                "width": None,
                "lines": 1,
                "color": "info",
                "addon": {}
            },
        },
        "dda_conf": {
            "not_good": {
                "entry": ttk.Label,
                "start": None,
                "width": None,
                "lines": 1,
                "color": "info",
                "addon": {}
            },
        },
        "about_us": {
            "not_good": {
                "entry": ttk.Label,
                "start": None,
                "width": None,
                "lines": 1,
                "color": "info",
                "addon": {}
            },
        },
    }
