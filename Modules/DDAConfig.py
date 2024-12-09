from Modules.LogOutput import Log, LL
from Modules.PS1Loader import PS1Loader

ps1_cmd = {
    "get_gpu_path": "Get-VMGpuPartitionAdapter -VMName \"%s\" | ForEach-Object {$_.InstancePath,$_.MinPartitionCompute}",
    "get_gpu_name": "Get-CimInstance  -ClassName Win32_PnPEntity | ForEach-Object {$_.DeviceID+\"|||\"+$_.Name}",
    "get_mem_size": "Get-VM -Name \"%s\" | ForEach-Object {$_.LowMemoryMappedIoSpace,$_.HighMemoryMappedIoSpace}",
    "get_dda_list":"Get-VMAssignableDevice -VMName \"%s\" | ForEach-Object {$_.LocationPath+\"|||\"+$_.InstanceID}"
}


class PCIConfig:
    def __init__(self, in_logs: Log.log, in_name=""):
        self.log_apis = in_logs
        self.vmx_name = in_name
        self.gpu_path = ""
        self.gpu_name = ""
        self.gpu_size = 0
        self.min_size = 0
        self.max_size = 0
        self.map_uuid_name = {}
        self.dda_path_uuid = {}

    def get_all_data(self):
        if len(self.vmx_name) > 0:
            self.get_gpu_path()
        self.get_gpu_name()
        if len(self.vmx_name) > 0:
            self.get_mem_size()
            self.get_dda_list()

    def get_gpu_path(self):
        update_cmd = ("Get-VMGpuPartitionAdapter -VMName \"%s\" "
                      "| ForEach-Object {$_.InstancePath,$_.MinPartitionCompute}") % self.vmx_name
        result_cmd = PS1Loader.cmd(update_cmd, self.log_apis).split("\n")
        if len(result_cmd) < 2:
            return False
        self.gpu_path = result_cmd[0]
        self.gpu_size = result_cmd[1]
        if len(self.gpu_path) <= 0:
            return False
        if len(self.gpu_size) <= 0:
            self.gpu_size = 0
        else:
            self.gpu_size = int(100 / 1000000000 * int(self.gpu_size))
        self.log_apis("当前显卡路径: %s" % self.gpu_path)
        self.log_apis("当前显卡比例: %s" % self.gpu_size)
        return True

    def get_gpu_name(self):
        device_str = ""
        if len(self.gpu_path) > 0:
            device_str = self.gpu_path.replace("\\\\?\\", "")
            device_str = device_str.split("#{")[0].replace("#", "\\")
            self.log_apis("当前显卡实例: %s" % device_str)
        update_cmd = ("Get-CimInstance  -ClassName Win32_PnPEntity "
                      "| ForEach-Object {$_.DeviceID+\"|||\"+$_.Name}")
        result_cmd = PS1Loader.cmd(update_cmd, self.log_apis).split("\n")
        self.map_uuid_name = {}
        self.gpu_name = ""
        for i in result_cmd:
            if len(i) <= 0:
                continue
            map_list = i.split("|||")
            if len(map_list) < 2:
                continue
            self.map_uuid_name[map_list[0].lower()] = map_list[1]
            if len(self.gpu_path) <= 0:
                continue
            if map_list[0].lower().find(device_str.lower()) >= 0:
                self.gpu_name = map_list[1]
                self.log_apis("当前显卡名称: %s" % self.gpu_name)
        return True

    def get_mem_size(self):
        update_cmd = ("Get-VM -Name \"%s\" "
                      "| ForEach-Object {$_.LowMemoryMappedIoSpace,"
                      "$_.HighMemoryMappedIoSpace}" % self.vmx_name)
        result_cmd = PS1Loader.cmd(update_cmd, self.log_apis).split("\n")
        if len(result_cmd) < 2:
            return False
        self.min_size = int(int(result_cmd[0]) / 1024 / 1024)
        self.max_size = int(int(result_cmd[1]) / 1024 / 1024)
        self.log_apis("最低内存映射: %s" % self.min_size)
        self.log_apis("最高内存映射: %s" % self.max_size)
        return True

    def get_dda_list(self):
        update_cmd = ("Get-VMAssignableDevice -VMName \"%s\" "
                      "|  ForEach-Object {$_.LocationPath+\"|||\"+$_.InstanceID}" % self.vmx_name)
        result_cmd = PS1Loader.cmd(update_cmd, self.log_apis).split("\n")
        for i in result_cmd:
            if len(i) > 0:
                map_list = i.split("|||")
                if len(map_list) >= 2:
                    self.dda_path_uuid[map_list[0]] = map_list[1].lower()
                    self.log_apis("已经直通地址: %s" % map_list[0])
                    if map_list[1].lower() in self.map_uuid_name:
                        self.log_apis("已经直通名称: %s" % self.map_uuid_name[map_list[1].lower()])
                    else:
                        print(map_list[1].lower(), self.map_uuid_name)

    @staticmethod
    def del_dda_list():
        pass

    def add_pci_pass(self, pci_name):
        pass

    def del_pci_pass(self, pci_name):
        pass

    def set_gpu_size(self, pci_name):
        pass

    def set_mem_size(self, pci_name):
        pass

    def set_gpu_name(self, pci_name):
        pass
