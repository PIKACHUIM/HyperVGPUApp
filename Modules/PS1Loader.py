import threading
import subprocess
from Modules.LogOutput import Log, LL


class PS1Loader(threading.Thread):
    def __init__(self, in_file, in_type="file"):
        threading.Thread.__init__(self)
        self.file = in_file
        self.type = in_type
        self.flag = False
        self.data = []
        self.logs = Log(
            "GPULoader",
            "",
            "").log

    def run(self):
        prompts = "GPULoader"
        if self.type == "file":
            command = 'powershell .\\%s' % self.file
        else:
            command = self.file
        self.logs("执行获取命令: %s" % command, prompts, LL.D)
        process = subprocess.run(command, shell=True, text=True, capture_output=True)
        self.data = process.stdout
        print(process.stderr)
        self.flag = True

    @staticmethod
    def cmd(in_cmds: str, in_logs: Log.log, execute="powershell") -> str:
        prompts = "GPULoader"
        command = '%s \"%s\"' % (execute, in_cmds.replace("\"", "\'"))
        in_logs("执行指定命令: %s" % command, prompts, LL.D)
        process = subprocess.run(command, shell=True, text=True,
                                 # executable="powershell.exe",
                                 capture_output=True)
        print(process.stderr)
        return process.stdout
