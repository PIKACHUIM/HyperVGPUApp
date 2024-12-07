import os
import json
import time
from functools import partial

import pyglet
import locale
import tkinter
import threading
import subprocess
import ttkbootstrap as ttk
from ttkbootstrap import *

from Modules.GPUCreate import GPUCreate
from Modules.PS1Loader import PS1Loader
from Modules.HintEntry import HintEntry
from Modules.LogOutput import Log, LL
from UIConfig import UIConfig, Function


class VGPUTool:
    def __init__(self):
        # 创建窗口 ------------------------------------------------------------
        self.text = None
        self.view = {}
        self.root = tk.Tk()
        self.head = ttk.Style()
        self.root.geometry("665x550")
        self.area = locale.getdefaultlocale()[0]
        self.readConfig()
        self.root.title(self.i18nString("app_name"))
        self.root.iconbitmap("Configs/HyperVCreated.ico")
        # 字体设置 ------------------------------------------------------------
        self.font = tkinter.font.Font(family="MapleMono SC NF", size=12)
        self.head.configure("TNotebook.Tab", font=self.font)
        self.head.configure("TFrame", font=self.font)
        self.head.configure("TLabel", font=self.font)
        # 界面配置 ============================================================
        self.main = ttk.Notebook(self.root)
        self.page = {i: ttk.Frame(self.root) for i in UIConfig.page}
        self.logs = Log("GPULoader",
                        "", "", sub_files=None).log
        self.components()
        self.update_gpu()
        self.update_dev()
        self.update_net()
        self.config_exe()
        self.config_txt()
        self.update_vmx()

        # self.result_get()
        self.view["gpv_conf"]['pci_deal']['entry']['mode'] = 'indeterminate'
        self.view["gpv_conf"]['pci_deal']['entry'].start(20)
        self.root.mainloop()

    # 读取配置文件 ################################################################
    def readConfig(self):
        pyglet.font.add_file("Configs/MapleMonoFont.ttf")
        read_path = "Configs/Localizations/"
        read_name = read_path + "%s.json" % self.area
        if not os.path.exists(read_name):
            read_name = read_path + "en_US.json"
        with open(read_name, encoding="utf8") as read_file:
            self.text = json.loads(read_file.read())

    # 获取本地翻译 ################################################################
    def i18nString(self, in_name):
        if in_name in self.text:
            return self.text[in_name]
        else:
            return in_name

    # 设置页面组件 ################################################################
    def components(self):
        # 添加页面 ================================================================
        for tab_name in self.page:
            # 添加组件 ------------------------------------------------------------
            self.view[tab_name] = {}
            tab_apis = self.page[tab_name]
            com_list = UIConfig.page[tab_name]
            com_line = com_cols = 0
            # 特殊筛选 ------------------------------------------------------------
            lab = (ttk.Entry, ttk.Combobox)
            wid = (ttk.Entry, ttk.Combobox, ttk.Button, ttk.Label, HintEntry)
            # llm = ttk.Progressbar
            # lst = ttk.Combobox
            txt = (ttk.Label, ttk.Checkbutton, ttk.Button)
            var = (ttk.Entry, ttk.Label, ttk.Combobox)
            # 遍历组件 ------------------------------------------------------------
            for com_name in com_list:
                com_data: dict = com_list[com_name]
                if "loads" in com_data:
                    com_data: dict = UIConfig.page[com_data["loads"]][com_name]
                add_data: dict = com_data['addon']
                com_objs = com_data['entry']  # 组件类型对象
                tmp_data = None
                # 新UI组件 =====================================================================================
                if com_name not in self.view[tab_name]:
                    # add_data: dict = com_data['addon']
                    # com_objs = com_data['entry']  # 组件类型对象
                    var_save = com_data['saves']() if 'saves' in com_data else None
                    var_adds = {
                        add_name: add_data[add_name]['saves']() \
                            if 'saves' in add_data[add_name] else None
                        for add_name in add_data
                    }
                    tmp_data = {
                        # 引导标题 =============================================================================
                        "label": ttk.Label(
                            tab_apis, bootstyle=com_data['color'], text=self.i18nString(com_name) + ": ") \
                            if com_objs in lab and ("label" not in com_data or com_data["label"]) else None,
                        # 核心组件 =============================================================================
                        "saves": var_save,
                        "entry": com_data["entry"](
                            tab_apis, bootstyle=com_data['color'] or "info",
                            # command=com_data['start'] if 'start' in com_data and com_objs in com else None,
                            width=com_data['width'] if 'width' in com_data and com_objs in wid else None,
                            length=com_data['width'] if 'width' in com_data and com_objs == ttk.Progressbar else None,
                            values=com_data['value'] if 'value' in com_data and com_objs == ttk.Combobox else None,
                            text=self.i18nString(com_name) if com_objs in txt else None,
                            textvariable=var_save if com_objs in var else None,
                            variable=var_save if com_objs is ttk.Checkbutton else None,
                            height=com_data['highs'] if 'highs' in com_data and com_objs == ttk.Treeview else None,
                            hint=self.i18nString(com_name) if com_objs == HintEntry else None
                        ),
                        # 附件组件 =============================================================================
                        "saved": var_adds,
                        "addon": {
                            add_name: add_data[add_name]['entry'](
                                tab_apis, bootstyle=add_data[add_name]['color'],
                                text=self.i18nString(com_name + "_" + add_name),
                                width=add_data[add_name]['width'] if 'width' in add_data[add_name] else None,
                                textvariable=var_adds[add_name] if add_name in add_data else None,
                                # command=add_data[add_name]['start'] if 'start' in add_data[add_name] else None,
                                height=com_data['highs'] if 'highs' in com_data and com_objs == ttk.Treeview else None,
                            )
                            for add_name in add_data
                        },
                        "units": com_data  # 多个组件复用的时候，存储data去重以便后面grid进行调用
                    }
                    self.view[tab_name][com_name] = tmp_data
                else:
                    print("跳过组件添加: %s-%s" % (tab_name, com_name))
                # 设置列表 =======================================================================================
                if type(com_objs) == type(ttk.Combobox):
                    if 'index' in com_data and 'value' in com_data:
                        if len(com_data['value']) > com_data['index']:
                            tmp_data["entry"].current(com_data['index'])
                    elif 'value' in com_data:
                        if len(com_data['value']) > 0:
                            tmp_data["entry"].current(0)
                # 设置表格 =======================================================================================
                if type(com_objs) == type(ttk.Treeview) and 'table' in com_data:
                    tmp_data["entry"]["columns"] = tuple(com_data['table'].keys())
                    print(tuple(com_data['table'].keys()))
                    tmp_data["entry"].column("#0", width=18)
                    tmp_data["entry"].heading("#0", text="#", anchor='center')
                    count = 0
                    for set_name in com_data['table']:
                        tmp_data["entry"].column(set_name, width=com_data['table'][set_name],
                                                 anchor='center' if count <= 1 else "w")
                        count += 1
                        tmp_data["entry"].heading(
                            set_name, text=self.i18nString(com_name + "_" + set_name), anchor='center')
                # 放置组件 =======================================================================================
                if tmp_data["label"] is not None:
                    com_cols += 1
                    tmp_data["label"].grid(padx=10, row=com_line, column=com_cols)
                tmp_data["entry"].grid(pady=10, row=com_line, column=com_cols + 1,
                                       columnspan=com_data['lines'], padx=10, sticky=W)
                for add_name in tmp_data['addon']:
                    now_data = tmp_data['addon'][add_name]
                    now_data.grid(column=com_cols + 1 + com_data['lines'],
                                  row=com_line, padx=10, pady=10, sticky=W,
                                  columnspan=add_data[add_name]['lines'], )
                    com_cols += add_data[add_name]['lines']
                com_cols += com_data['lines']
                if com_cols >= UIConfig.line:
                    com_cols = 0
                    com_line += 1
            # 添加标签 ------------------------------------------------------------
            self.main.add(tab_apis, text=self.i18nString(tab_name))
        self.main.pack(padx=10, pady=10, fill=tk.BOTH, expand=True)

    def config_exe(self):
        self.view["gpv_init"]['iso_file']['addon']['open'].config(command=partial(
            Function.selectFile, self.view["gpv_init"]['iso_file']['entry'], [("ISO File", ".iso")]))
        self.view["gpv_init"]['vhd_path']['addon']['open'].config(command=partial(
            Function.selectPath, self.view["gpv_init"]['vhd_path']['entry']))
        self.view["gpv_init"]['gpu_name']['addon']['open'].config(command=self.update_gpu)
        self.view["gpv_init"]['bar_deal']['addon']['exec'].config(command=self.submit_gpu)
        self.view["gpv_init"]['net_name']['addon']['open'].config(command=self.update_net)

    def config_txt(self):
        self.view["gpv_init"]['vmx_name']['saves'].trace('w', self.result_get)
        self.view["gpv_init"]['iso_file']['saves'].trace('w', self.result_get)
        self.view["gpv_init"]['vhd_path']['saves'].trace('w', self.result_get)
        self.view["gpv_init"]['gpu_name']['saves'].trace('w', self.result_get)
        self.view["gpv_init"]['aur_boot']['saves'].trace('w', self.result_get)
        self.view["gpv_init"]['win_name']['saves'].trace('w', self.result_get)
        self.view["gpv_init"]['win_pass']['saves'].trace('w', self.result_get)
        self.view["gpv_init"]['aur_boot']['saves'].trace('w', self.result_get)
        self.view["gpv_init"]['aur_boot']['saves'].set(False)
        self.view["gpv_init"]['aur_boot']['entry'].state(['!alternate'])

    def checks_var(self, in_var):
        if len(self.view["gpv_init"][in_var]['saves'].get()) <= 0:
            self.view["gpv_init"][in_var]['entry'].config(bootstyle="danger")
            return False
        else:
            self.view["gpv_init"][in_var]['entry'].config(bootstyle="info")
            return True

    def result_get(self, *args):
        check_flag = True
        check_list = ["vmx_name", "iso_file", "vhd_path", "gpu_name"]
        if self.view["gpv_init"]['aur_boot']['saves'].get():
            check_list.append("win_name")
            check_list.append("win_pass")
        for var_name in check_list:
            check_flag = check_flag and self.checks_var(var_name)
        if check_flag:
            self.view["gpv_init"]['bar_deal']['addon']['exec'].config(state=tk.NORMAL)
        else:
            self.view["gpv_init"]['bar_deal']['addon']['exec'].config(state=tk.DISABLED)

    def update_gpu(self):
        self.view["gpv_init"]['bar_deal']['saved']['text'].set(self.i18nString('gpu_name_load'))
        self.view["gpv_init"]['gpu_name']['addon']['open'].config(state=tk.DISABLED)
        self.view["gpv_init"]['bar_deal']['addon']['exec'].config(state=tk.DISABLED)
        self.view["gpv_init"]['gpu_name']['entry'].config(state=tk.DISABLED)
        self.view["gpv_init"]['bar_deal']['entry']['mode'] = 'indeterminate'
        self.view["gpv_init"]['bar_deal']['entry'].start(20)
        update_thread = PS1Loader("PreCheck.ps1")
        loader_thread = threading.Thread(target=self.update_gpu_bak, args=(update_thread,))
        update_thread.start()
        loader_thread.start()

    def update_dev(self):
        self.view["gpv_conf"]['pci_deal']['saved']['text'].set(self.i18nString('pci_list_load'))
        self.view["gpv_conf"]['add_pcie']['entry'].config(state=tk.DISABLED)
        self.view["gpv_conf"]['pci_save']['entry'].config(state=tk.DISABLED)
        self.view["gpv_conf"]['pci_load']['entry'].config(state=tk.DISABLED)
        self.view["gpv_conf"]['del_pcie']['entry'].config(state=tk.DISABLED)
        self.view["gpv_conf"]['pci_push']['entry'].config(state=tk.DISABLED)
        self.view["gpv_conf"]['pci_deal']['entry']['mode'] = 'indeterminate'
        self.view["gpv_conf"]['pci_deal']['entry'].start(20)
        update_thread = PS1Loader("CheckDDA.ps1")
        loader_thread = threading.Thread(target=self.update_dev_bak, args=(update_thread,))
        update_thread.start()
        loader_thread.start()

    def update_gpu_bak(self, in_proc):
        prompts = "update_gpu"
        while not in_proc.flag:
            time.sleep(0.1)
        self.view["gpv_init"]['gpu_name']['addon']['open'].config(state=tk.NORMAL)
        self.view["gpv_init"]['bar_deal']['addon']['exec'].config(state=tk.NORMAL)
        self.view["gpv_init"]['gpu_name']['entry'].config(state=tk.NORMAL)
        self.view["gpv_init"]['bar_deal']['entry']['mode'] = 'determinate'
        self.view["gpv_init"]['bar_deal']['entry'].stop()
        self.view["gpv_init"]['bar_deal']['entry']['value'] = 100
        self.view["gpv_init"]['bar_deal']['saved']['text'].set("")
        in_data = Function.splitLists(in_proc.data, self.logs, "设备", prompts)
        self.view["gpv_init"]['gpu_name']['entry']['values'] = in_data
        self.view["gpv_conf"]['gpu_name']['entry']['values'] = in_data
        if len(in_data) > 0:
            self.view["gpv_init"]['gpu_name']['entry'].current(0)
            self.view["gpv_conf"]['gpu_name']['entry'].current(0)

    def update_dev_bak(self, in_proc):
        while not in_proc.flag:
            time.sleep(0.1)
        self.view["gpv_conf"]['pci_deal']['saved']['text'].set("")
        self.view["gpv_conf"]['add_pcie']['entry'].config(state=tk.NORMAL)
        self.view["gpv_conf"]['pci_save']['entry'].config(state=tk.NORMAL)
        self.view["gpv_conf"]['pci_load']['entry'].config(state=tk.NORMAL)
        self.view["gpv_conf"]['del_pcie']['entry'].config(state=tk.NORMAL)
        self.view["gpv_conf"]['pci_push']['entry'].config(state=tk.NORMAL)
        self.view["gpv_conf"]['pci_deal']['entry']['mode'] = 'indeterminate'
        self.view["gpv_conf"]['pci_deal']['entry'].start(20)
        tree = self.view["gpv_conf"]['disabled']['entry']
        self.view["gpv_conf"]['disabled']['entry'].delete(*tree.get_children())
        result = {}
        counts = 1
        for dev_line in in_proc.data.split("########")[1:]:
            if dev_line.startswith("\n"):
                dev_line = dev_line[1:]
            if dev_line.endswith("\n"):
                dev_line = dev_line[:-1]
            dev_line = dev_line.split("\n")
            print(dev_line, "\n\n")
            if len(dev_line) >= 1:
                result[dev_line[0]] = {
                    "name": dev_line[0],
                    "text": dev_line[1].split(".")[-1] if len(dev_line) >= 2 else "(None)",
                    "path": dev_line[2] if len(dev_line) >= 3 else "(None)",
                    "flag": "✔️" if len(dev_line) >= 2 and \
                                    dev_line[1].find("Assignment can work") >= 0 else "❌"
                }
                if result[dev_line[0]]["flag"] == "✔️":
                    tree.insert('', counts, values=(
                        result[dev_line[0]]['flag'],
                        result[dev_line[0]]['path'],
                        result[dev_line[0]]['name'],
                        result[dev_line[0]]['text'],
                    ))
                counts += 1

    def update_net(self):
        prompts = "NetLoader"
        command = 'powershell \"Get-VMSwitch | Select-Object -ExpandProperty Name\"'
        self.logs("获取网卡命令: %s" % command, prompts, LL.D)
        process = subprocess.run(command, shell=True, text=True, capture_output=True)
        results = Function.splitLists(process.stdout, self.logs, "网卡", prompts)
        if len(results) > 0:
            self.view["gpv_init"]['net_name']['entry']['values'] = results
            self.view["gpv_init"]['net_name']['entry'].current(0)

    def update_vmx(self):
        prompts = "NetLoader"
        command = 'powershell \"Get-VM | ForEach-Object {$_.Name}\"'
        self.logs("获取虚拟机器: %s" % command, prompts, LL.D)
        process = subprocess.run(command, shell=True, text=True, capture_output=True)
        results = Function.splitLists(process.stdout, self.logs, "网卡", prompts)
        self.view["gpv_conf"]['vmx_list']['entry']['values'] = results
        self.view["gpv_conf"]['vmx_list']['entry'].current(0)
        print(results)

    def submit_gpu(self):
        var_conf = ('$params = @{\n'
                    'VMName = "%s"\n'
                    'SourcePath = "%s"\n'
                    'Edition    = %d\n'
                    'VhdFormat  = "%s"\n'
                    'DiskLayout = "%s"\n'
                    'SizeBytes  = %s\n'
                    'MemoryAmount = %s\n'
                    'CPUCores = %d\n'
                    'NetworkSwitch = "%s"\n'
                    'VHDPath = "%s"\n'
                    'UnattendPath = "$PSScriptRoot"+"\\Scripts\\autounattend.xml"\n'
                    'GPUName = "%s"\n'
                    'GPUResourceAllocationPercentage = %d\n'
                    'Team_ID = "%s"\n'
                    'Key = "%s"\n'
                    'Username = "%s"\n'
                    'Password = "%s"\n'
                    'Autologon = "%s"\n'
                    '}\n\n' % (
                        self.view["gpv_init"]['vmx_name']['saves'].get(),
                        self.view["gpv_init"]['iso_file']['saves'].get(),
                        self.view["gpv_init"]['ver_name']['saves'].get(),
                        self.view["gpv_init"]['vhd_type']['saves'].get(),
                        self.view["gpv_init"]['use_boot']['saves'].get(),
                        self.view["gpv_init"]['vhd_size']['saves'].get(),
                        self.view["gpv_init"]['mem_size']['saves'].get(),
                        self.view["gpv_init"]['cpu_size']['saves'].get(),
                        self.view["gpv_init"]['net_name']['saves'].get(),
                        self.view["gpv_init"]['vhd_path']['saves'].get(),
                        self.view["gpv_init"]['gpu_name']['saves'].get(),
                        self.view["gpv_init"]['gpu_size']['saves'].get(),
                        self.view["gpv_init"]['par_name']['saves'].get(),
                        self.view["gpv_init"]['par_pass']['saves'].get(),
                        self.view["gpv_init"]['win_name']['saves'].get(),
                        self.view["gpv_init"]['win_pass']['saves'].get(),
                        "true" if self.view["gpv_init"]['aur_boot']['saves'].get() else "false",
                    ))
        print(var_conf)
        with open("CreateVM.txt", encoding="utf8") as read_file:
            read_data = read_file.read()
        read_data = var_conf + read_data
        with open("TmpSaves.ps1", 'w', encoding="utf8") as save_file:
            save_file.write(read_data)
        self.view["gpv_init"]['bar_deal']['entry']['mode'] = 'indeterminate'
        self.view["gpv_init"]['bar_deal']['entry'].start(20)
        self.view["gpv_init"]['bar_deal']['addon']['exec'].config(state=tk.DISABLED)
        update_thread = GPUCreate(self.view["gpv_init"]['bar_deal']['entry'],
                                  self.view["gpv_init"]['bar_deal']['addon']['exec'])
        update_thread.start()

    @staticmethod
    def processbar(in_apis, in_time: int = 10):
        in_time *= 10
        for i in range(0, in_time):
            in_apis['value'] = 100 / in_time * i
            time.sleep(0.1)


if __name__ == "__main__":
    app = VGPUTool()
