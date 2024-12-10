import threading
import subprocess
from ttkbootstrap import *
from Modules.LogOutput import Log, LL
from UIConfig import Function


class GPUCreate(threading.Thread):
    def __init__(self, in_processbar, start_created):
        threading.Thread.__init__(self)
        self.flag = False
        self.data = {}
        self.logs = Log(
            "GPULoader",
            "",
            "").log
        self.in_processbar = in_processbar
        self.start_created = start_created

    def run(self):
        prompts = "GPUCreate"
        command = "powershell .\TmpSaves.ps1"
        self.logs("执行创建命令: %s" % command, prompts, LL.G)
        process = subprocess.run(command, shell=True, text=True, capture_output=True)
        self.logs("创建执行结果: %s" % process.stdout, prompts, LL.G_)
        self.logs("创建执行错误: %s" % process.stderr, prompts, LL.W)
        self.data = {
            "text": process.stdout,
            "errs": process.stderr
        }
        self.in_processbar['mode'] = 'determinate'
        self.in_processbar.stop()
        self.in_processbar['value'] = 100
        self.start_created.config(state=tk.NORMAL)
        self.flag = True
