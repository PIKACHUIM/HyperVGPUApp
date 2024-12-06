import os
import json
import subprocess

import pyglet
import locale
import tkinter
import ttkbootstrap as ttk
from ttkbootstrap import *

from UIConfig import UIConfig


class VGPUTool:
    def __init__(self):
        # 创建窗口 ------------------------------------------------------------
        self.text = None
        self.view = {}
        self.root = tk.Tk()
        self.head = ttk.Style()
        self.root.geometry("660x510")
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
        self.components()
        self.getGPUCard()
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
            tab_apis = self.page[tab_name]
            com_list = UIConfig.page[tab_name]
            com_line = com_cols = 0
            wid = (ttk.Entry, ttk.Combobox, ttk.Button, ttk.Label)
            com = (ttk.Button, ttk.Checkbutton)
            lst = ttk.Combobox
            for com_name in com_list:
                com_data = com_list[com_name]
                c = com_data
                add_data = com_data['addon']
                e = com_data['entry']
                tmp_data = {
                    "label": ttk.Label(tab_apis, bootstyle=com_data['color'],
                                       text=self.i18nString(com_name) + ": ") \
                        if e in (ttk.Entry, ttk.Combobox) else None,
                    "entry": com_data["entry"](
                        tab_apis, bootstyle=com_data['color'] or "info",
                        command=c['start'] if 'start' in c and e in com else None,
                        width=c['width'] if 'width' in c and e in wid else None,
                        length=c['width'] if 'width' in c and e not in wid else None,
                        values=c['value'] if 'value' in c and e == lst else None,
                        text=self.i18nString(com_name) if e == ttk.Label else None
                    ),
                    "addon": {
                        add_name: add_data[add_name]['entry'](
                            tab_apis, bootstyle=add_data[add_name]['color'],
                            text=self.i18nString(com_name + "_" + add_name),
                            width=add_data[add_name]['width'] \
                                if 'width' in add_data[add_name] else None,
                            command=add_data[add_name]['start'] \
                                if 'start' in add_data[add_name] else None,
                        )
                        for add_name in add_data
                    }
                }
                if e == lst and len(tmp_data["entry"]['values']) > 0:
                    tmp_data["entry"].current(0)
                if tmp_data["label"] is not None:
                    com_cols += 1
                    tmp_data["label"].grid(padx=10, row=com_line, column=com_cols)
                tmp_data["entry"].grid(pady=10, row=com_line, column=com_cols + 1,
                                       columnspan=com_data['lines'], padx=10, sticky=W, )
                for add_name in tmp_data['addon']:
                    now_data = tmp_data['addon'][add_name]
                    now_data.grid(column=com_cols + 1 + com_data['lines'],
                                  row=com_line, padx=10, pady=10, sticky=W,
                                  columnspan=add_data[add_name]['lines'], )
                    com_cols += add_data[add_name]['lines']
                com_cols += com_data['lines']
                if com_cols >= UIConfig.line - 1:
                    com_cols = 0
                    com_line += 1
                self.view[com_name] = tmp_data
            # 添加标签 ------------------------------------------------------------
            self.main.add(tab_apis, text=self.i18nString(tab_name))
        self.main.pack(padx=10, pady=10, fill=tk.BOTH, expand=True)

    def getGPUCard(self):
        # command = 'Start-Process powershell -Verb RunAs -ArgumentList "-file",".\PreCheck.ps1"'
        # command = ('powershell "$Devices = (Get-WmiObject -Class "Msvm_PartitionableGpu" -ComputerName $env:COMPUTERNAME -Namespace "ROOT\\virtualization\\v2").name\n'
        #            'Foreach ($GPU in $Devices) {\n'
        #            '$GPUParse = $GPU.Split(\'#\')[1]\n'
        #            'Get-WmiObject Win32_PNPSignedDriver | where {($_.HardwareID -eq "PCI\\$GPUParse")} | select DeviceName -ExpandProperty DeviceName\n'
        #            '}\n\n"')
        command = 'powershell .\\PreCheck.ps1'
        print(command)
        process = subprocess.run(command, shell=True, text=True, capture_output=True)
        outputs = process.stdout
        print(outputs)


if __name__ == "__main__":
    app = VGPUTool()
