import threading
import subprocess
from ttkbootstrap import *
from Modules.LogOutput import Log, LL
from UIConfig import Function


class PS1Loader(threading.Thread):
    def __init__(self,in_file):
                 # selector_list,
                 # reloader_push,
                 # commiter_push,
                 # in_processbar,
                 # in_text_label,
                 # refresh_label,
                 # another_lists
        threading.Thread.__init__(self)
        self.file = in_file
        self.flag = False
        self.data = []
        self.logs = Log(
            "GPULoader",
            "",
            "",
            sub_files=None
        ).log
        # self.selector_list = selector_list
        # self.reloader_push = reloader_push
        # self.commiter_push = commiter_push
        # self.in_processbar = in_processbar
        # self.in_text_label = in_text_label
        # self.refresh_label = refresh_label
        # self.another_lists = another_lists

    def run(self):
        prompts = "GPULoader"
        command = 'powershell .\\%s'%self.file
        # self.selector_list.config(state=tk.DISABLED)
        # self.reloader_push.config(state=tk.DISABLED)
        # self.commiter_push.config(state=tk.DISABLED)
        # self.in_processbar.step(20)
        self.logs("执行获取命令: %s" % command, prompts, LL.D)
        process = subprocess.run(command, shell=True, text=True, capture_output=True)
        self.data = process.stdout
        # self.another_lists['values'] = self.data
        # self.selector_list['values'] = self.data
        # self.selector_list.config(state=tk.NORMAL)
        # self.reloader_push.config(state=tk.NORMAL)
        # self.commiter_push.config(state=tk.NORMAL)
        # self.in_processbar['mode']='determinate'
        # self.in_processbar.stop()
        # self.in_processbar['value'] = 100
        # self.in_text_label.set("")
        # if len(self.data) > 0:
        #     self.selector_list.current(0)
        #     self.another_lists.current(0)
        # self.refresh_label()
        self.flag = True
