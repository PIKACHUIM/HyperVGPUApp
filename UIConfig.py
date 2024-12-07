import tkinter
import tkinter.filedialog
import ttkbootstrap as ttk

from Modules.HintEntry import HintEntry
from Modules.LogOutput import Log, LL


class Function:
    @staticmethod
    def selectFile(in_apis, in_type):
        file_path = tkinter.filedialog.askopenfilename(filetypes=in_type)

        in_apis.delete(0, tkinter.END)
        in_apis.insert(0, file_path)
        return file_path

    @staticmethod
    def selectPath(in_apis):
        file_path = tkinter.filedialog.askdirectory()
        in_apis.delete(0, tkinter.END)
        in_apis.insert(0, file_path)
        return file_path

    @staticmethod
    def splitLists(in_data, in_logs, in_name, prompts=""):
        outputs = in_data.split("\n")
        results = []
        for gpu_name in outputs:
            if len(gpu_name) > 0:
                in_logs("返回%s列表: %s" %
                        (in_name, gpu_name), prompts, LL.S_)
                results.append(gpu_name)
        return results


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
                "saves": ttk.StringVar,
                "addon": {}
            },
            "aur_boot": {
                "entry": ttk.Checkbutton,
                "start": None,
                "lines": 1,
                "color": "primary",
                "saves": ttk.BooleanVar,
                "addon": {}
            },
            "iso_file": {
                "entry": ttk.Entry,
                "start": None,
                "width": 60,
                "lines": 4,
                "color": "info",
                "saves": ttk.StringVar,
                "addon": {
                    "open": {
                        "entry": ttk.Button,
                        "start": None,
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
                "saves": ttk.StringVar,
                "addon": {
                    "open": {
                        "entry": ttk.Button,
                        "start": None,
                        "width": 7,
                        "lines": 1,
                        "color": "info",
                    }
                }
            },
            "net_name": {
                "entry": ttk.Combobox,
                "start": None,
                "width": 58,
                "lines": 4,
                "color": "info",
                "saves": ttk.StringVar,
                "addon": {
                    "open": {
                        "entry": ttk.Button,
                        "start": None,
                        "width": 7,
                        "lines": 1,
                        "color": "primary",
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
                "saves": ttk.IntVar,
                "addon": {}
            },
            "vhd_type": {
                "entry": ttk.Combobox,
                "start": None,
                "width": 7,
                "lines": 1,
                "color": "info",
                "value": ["VHDX", "VHD"],
                "saves": ttk.StringVar,
                "addon": {}
            },
            "use_boot": {
                "entry": ttk.Combobox,
                "start": None,
                "width": 7,
                "lines": 1,
                "color": "info",
                "value": ["UEFI"],
                "saves": ttk.StringVar,
                "addon": {}
            },
            "vhd_size": {
                "entry": ttk.Combobox,
                "start": None,
                "width": 7,
                "lines": 1,
                "color": "info",
                "value": ["20GB", "32GB", "64GB", "128GB"],
                "saves": ttk.StringVar,
                "index": 1,
                "addon": {}
            },
            "mem_size": {
                "entry": ttk.Combobox,
                "start": None,
                "width": 7,
                "lines": 1,
                "value": ["4GB", "8GB", "16GB", "32GB", "64GB"],
                "saves": ttk.StringVar,
                "color": "info",
                "index": 1,
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
                "index": 2,
                "saves": ttk.IntVar,
                "addon": {}
            },
            "gpu_name": {
                "entry": ttk.Combobox,
                "start": None,
                "width": 23,
                "lines": 2,
                "color": "info",
                "saves": tkinter.StringVar,
                "addon": {
                    "open": {
                        "entry": ttk.Button,
                        "start": None,
                        "width": 7,
                        "lines": 1,
                        "color": "primary",
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
                "saves": ttk.IntVar,
                "index": 4,
                "addon": {}
            },
            "par_name": {
                "entry": ttk.Entry,
                "start": None,
                "width": 25,
                "lines": 2,
                "color": "secondary",
                "saves": ttk.StringVar,
                "addon": {}
            },
            "par_pass": {
                "entry": ttk.Entry,
                "start": None,
                "width": 26,
                "lines": 2,
                "color": "secondary",
                "saves": ttk.StringVar,
                "addon": {}
            },
            "win_name": {
                "entry": ttk.Entry,
                "start": None,
                "width": 25,
                "lines": 2,
                "color": "secondary",
                "saves": ttk.StringVar,
                "addon": {}
            },
            "win_pass": {
                "entry": ttk.Entry,
                "start": None,
                "width": 26,
                "lines": 2,
                "color": "secondary",
                "saves": ttk.StringVar,
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
                        "width": 14,
                        "lines": 1,
                        "saves": ttk.StringVar,
                        "color": "default",
                    },
                    "exec": {
                        "entry": ttk.Button,
                        "start": None,
                        "width": 7,
                        "lines": 1,
                        "color": "success",
                    }
                }
            },
        },
        "gpv_conf": {
            "vmx_list": {
                "entry": ttk.Combobox,
                "start": None,
                "width": 10,
                "lines": 1,
                "color": "info",
                "saves": ttk.StringVar,
                "addon": {
                    # "open": {
                    #     "entry": ttk.Button,
                    #     "start": None,
                    #     "width": 7,
                    #     "lines": 1,
                    #     "color": "primary",
                    # }
                }
            },
            "low_size": {
                "entry": ttk.Combobox,
                "start": None,
                "width": 7,
                "lines": 1,
                "color": "info",
                "saves": ttk.StringVar,
                "value": [64, 128, 256, 512,
                          1024, 2048, 4096],
                "index": 4,
                "addon": {}
            },
            "max_size": {
                "entry": ttk.Combobox,
                "start": None,
                "width": 7,
                "lines": 1,
                "color": "info",
                "saves": ttk.StringVar,
                "value": [512, 1024, 2048,
                          4096, 8192, 16384,
                          32768, 65536],
                "index": 4,
                "addon": {}
            },
            "gpu_name": {
                "loads": "gpv_init"
            },
            "gpu_size": {
                "loads": "gpv_init"
            },
            "currents": {
                "entry": ttk.Treeview,
                "start": None,
                "lines": 6,
                "color": "info",
                "highs": 6,
                "table": {
                    "dda_flag": 50,
                    "pci_path": 150,
                    "pci_name": 200,
                    "pci_text": 200,
                },
                "addon": {},
            },
            "add_pcie": {
                "entry": ttk.Button,
                "start": None,
                "lines": 1,
                "width": 7,
                "color": "info",
                "addon": {}
            },
            "pci_type": {
                "label": False,
                "entry": HintEntry,
                "start": None,
                "lines": 1,
                "width": 12,
                "color": "info",
                "saves": ttk.StringVar,
                "addon": {}
            },
            "pci_name": {
                "label": False,
                "entry": HintEntry,
                "start": None,
                "lines": 1,
                "width": 12,
                "color": "info",
                "saves": ttk.StringVar,
                "addon": {}
            },
            "pci_save": {
                "entry": ttk.Button,
                "start": None,
                "lines": 1,
                "width": 7,
                "color": "info",
                "addon": {}
            },
            "pci_load": {
                "entry": ttk.Button,
                "start": None,
                "lines": 1,
                "width": 10,
                "color": "primary",
                "addon": {}
            },
            "del_pcie": {
                "entry": ttk.Button,
                "start": None,
                "lines": 1,
                "width": 7,
                "color": "warning",
                "addon": {}
            },
            "disabled": {
                "entry": ttk.Treeview,
                "start": None,
                "lines": 6,
                "color": "primary",
                "highs": 6,
                "table": {
                    "dda_flag": 40,
                    "pci_path": 200,
                    "pci_name": 250,
                    "pci_text": 110,
                },
                "addon": {}
            },
            "pci_exit": {
                "entry": ttk.Button,
                "start": None,
                "lines": 1,
                "width": 7,
                "color": "danger",
                "addon": {}
            },
            "pci_deal": {
                "entry": ttk.Progressbar,
                "start": None,
                "width": 220,
                "lines": 2,
                "color": "success-striped",
                "addon": {
                    "text": {
                        "entry": ttk.Label,
                        "start": None,
                        "width": 7,
                        "lines": 1,
                        "saves": ttk.StringVar,
                        "color": "danger",
                    },
                }
            },
            "dda_tool": {
                "entry": ttk.Button,
                "start": None,
                "lines": 1,
                "width": 10,
                "color": "dark",
                "addon": {}
            },
            "pci_push": {
                "entry": ttk.Button,
                "start": None,
                "lines": 1,
                "width": 7,
                "color": "success",
                "addon": {}
            },
        },
        # "dda_conf": {
        #     "not_good": {
        #         "entry": ttk.Label,
        #         "start": None,
        #         "width": None,
        #         "lines": 1,
        #         "color": "info",
        #         "addon": {}
        #     },
        # },
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
