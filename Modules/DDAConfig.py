from Modules.DDADevice import DDAData, DT
from Modules.LogOutput import Log, LL
from Modules.PS1Loader import PS1Loader

ps1_cmd = {
    "get_gpu_path": "Get-VMGpuPartitionAdapter -VMName \"%s\" | ForEach-Object {$_.InstancePath,$_.MinPartitionCompute}",
    "get_gpu_name": "Get-CimInstance  -ClassName Win32_PnPEntity | ForEach-Object {$_.DeviceID+\"|||\"+$_.Name}",
    "get_mem_size": "Get-VM -Name \"%s\" | ForEach-Object {$_.LowMemoryMappedIoSpace,$_.HighMemoryMappedIoSpace}",
    "get_dda_list": "Get-VMAssignableDevice -VMName \"%s\" | ForEach-Object {$_.LocationPath+\"|||\"+$_.InstanceID}"
}


class PCIConfig:
    # 初始化数据 =====================================
    def __init__(self, in_logs: Log.log, in_name=""):
        self.log_apis = in_logs  # 传入的Logs日志对象
        self.vmx_name = in_name  # 传入当前虚拟机名称
        self.gpu_path: str = ""  # 分配的显卡设备路径
        self.gpu_name: str = ""  # 分配的显卡友好名称
        self.gpu_size: int = 0  # 分配的GPU占主机比例
        self.min_size: int = 0  # 分配的PCI的最低内存
        self.max_size: int = 0  # 分配的PCI的最高内存
        self.map_uuid_name = {}  # 实例编号->设备名称
        self.dda_path_uuid = {}  # 设备路径->实例编号

    def set_vmx_name(self, in_name):
        self.vmx_name = in_name
        self.gpu_path = ""
        self.gpu_size = 0
        self.min_size = 0
        self.min_size = 0

    # 获取所有数据 ===================================
    def get_all_data(self):
        if len(self.vmx_name) > 0:
            self.get_gpu_path()
        self.get_gpu_name()
        if len(self.vmx_name) > 0:
            self.get_mem_size()
            self.get_dda_list()

    # 获取GPU路径 =======================================================
    def get_gpu_path(self):
        update_cmd = (ps1_cmd["get_gpu_path"]) % self.vmx_name
        result_cmd = PS1Loader.cmd(update_cmd, self.log_apis).split("\n")
        # 读取失败 ------------------------------------------------------
        if len(result_cmd) < 2:
            return False
        self.gpu_path = result_cmd[0]
        self.gpu_size = result_cmd[1]
        # 没有数据 ------------------------------------------------------
        if len(self.gpu_path) <= 0:
            return False
        if len(self.gpu_size) <= 0:
            self.gpu_size = 0
            return True
        else:
            # 获取比例 --------------------------------------------------
            self.gpu_size = int(100 / 1000000000 * int(self.gpu_size))
            # 读取成功 --------------------------------------------------
            self.log_apis("当前显卡路径: %s" % self.gpu_path)
            self.log_apis("当前显卡比例: %s" % self.gpu_size)
            return True

    # 获取GPU名称 =======================================================
    def get_gpu_name(self):
        # 预处理GPU路径 -------------------------------------------------
        device_str = ""
        if len(self.gpu_path) > 0:
            device_str = self.gpu_path.replace("\\\\?\\", "")
            device_str = device_str.split("#{")[0].replace("#", "\\")
            self.log_apis("分配显卡实例: %s" % device_str)
        # 获取所有设备UUID-名称映射关系 ---------------------------------
        update_cmd = ("Get-CimInstance  -ClassName Win32_PnPEntity "
                      "| ForEach-Object {$_.DeviceID+\"|||\"+$_.Name}")
        result_cmd = PS1Loader.cmd(update_cmd, self.log_apis).split("\n")
        # 遍历获取结果 --------------------------------------------------
        self.map_uuid_name = {}
        self.gpu_name = ""
        for i in result_cmd:
            # 读取失败 --------------------------------------------------
            if len(i) <= 0:
                continue
            map_list = i.split("|||")
            # 读取失败 --------------------------------------------------
            if len(map_list) < 2:
                continue
            # 映射关系 --------------------------------------------------
            self.map_uuid_name[map_list[0].lower()] = map_list[1]
            # 没有路径 --------------------------------------------------
            if len(self.gpu_path) <= 0:
                continue
            # 找到设备 --------------------------------------------------
            if map_list[0].lower().find(device_str.lower()) >= 0:
                self.gpu_name = map_list[1]
                self.log_apis("分配显卡名称: %s" % self.gpu_name)
        return True

    # 获取MEM分配 =======================================================
    def get_mem_size(self):
        # 读取内存 ------------------------------------------------------
        update_cmd = ("Get-VM -Name \"%s\" "
                      "| ForEach-Object {$_.LowMemoryMappedIoSpace,"
                      "$_.HighMemoryMappedIoSpace}" % self.vmx_name)
        result_cmd = PS1Loader.cmd(update_cmd, self.log_apis).split("\n")
        # 读取失败 ------------------------------------------------------
        if len(result_cmd) < 2:
            return False
        # 读取成功 ------------------------------------------------------
        self.min_size = int(int(result_cmd[0]) / 1024 / 1024)
        self.max_size = int(int(result_cmd[1]) / 1024 / 1024)
        self.log_apis("最低内存映射: %s" % self.min_size)
        self.log_apis("最高内存映射: %s" % self.max_size)
        return True

    # 获取DDA分配 =======================================================
    def get_dda_list(self):
        self.dda_path_uuid = {}
        update_cmd = (ps1_cmd["get_dda_list"] % self.vmx_name)
        result_cmd = PS1Loader.cmd(update_cmd, self.log_apis).split("\n")
        for i in result_cmd:
            # 读取失败 --------------------------------------------------
            if len(i) <= 0:
                continue
            map_list = i.split("|||")
            # 读取失败 --------------------------------------------------
            if len(map_list) < 2:
                continue
            # 读取成功 --------------------------------------------------
            dda_uuid: str = map_list[1].lower()
            dda_path: str = map_list[0]
            dda_name: str = "DEV_NAME_ERR"
            # self.dda_path_uuid[dda_path] = dda_uuid
            if dda_uuid in self.map_uuid_name:
                dda_name = self.map_uuid_name[dda_uuid]
            dda_data = DDAData(
                name=dda_name,
                path=dda_path,
                uuid=dda_uuid,
                text="",
                flag=DT.DEV_DONE_DDA
            )
            self.dda_path_uuid[dda_path] = dda_data
            self.log_apis("已经直通地址: %s" % dda_path)
            self.log_apis("已经直通名称: %s" % dda_name)

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
