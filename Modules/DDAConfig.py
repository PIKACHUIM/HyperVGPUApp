from Modules.DDADevice import DDAData, DT
from Modules.LogOutput import Log, LL
from Modules.PS1Loader import PS1Loader

ps1_cmd = {
    "get_gpu_path": "Get-VMGpuPartitionAdapter -VMName \"%s\" | ForEach-Object {$_.InstancePath,$_.MinPartitionCompute}",
    "get_gpu_name": "Get-CimInstance  -ClassName Win32_PnPEntity | ForEach-Object {$_.DeviceID+\"|||\"+$_.Name}",
    "get_mem_size": "Get-VM -Name \"%s\" | ForEach-Object {$_.LowMemoryMappedIoSpace,$_.HighMemoryMappedIoSpace}",
    "get_dda_list": "Get-VMAssignableDevice -VMName \"%s\" | ForEach-Object {$_.LocationPath+\"|||\"+$_.InstanceID}",
    "del_gpu_name": "Remove-VMGpuPartitionAdapter -VMName \"%s\"",
    "add_gpu_name": "Add-VMGpuPartitionAdapter -VMName \"%s\" -InstancePath \"%s\"",
    "set_mem_size": "Set-VM -%s %dMB -VMName \"%s\"",
    "drivers_copy": "Add-VMGpuPartitionAdapterFiles -GPUName $GPUName -DriveLetter $windowsDrive",
    "set_gpu_size": [
        "Set-VMGpuPartitionAdapter -VMName \"%s\" -MinPartitionVRAM ([math]::round($(1000000000 / %d))) -MaxPartitionVRAM ([math]::round($(1000000000 / %d))) -OptimalPartitionVRAM ([math]::round($(1000000000 / %d)))",
        "Set-VMGPUPartitionAdapter -VMName \"%s\" -MinPartitionEncode ([math]::round($(18446744073709551615 / %d))) -MaxPartitionEncode ([math]::round($(18446744073709551615 / %d))) -OptimalPartitionEncode ([math]::round($(18446744073709551615 / %d)))",
        "Set-VMGpuPartitionAdapter -VMName \"%s\" -MinPartitionDecode ([math]::round($(1000000000 / %d))) -MaxPartitionDecode ([math]::round($(1000000000 / %d))) -OptimalPartitionDecode ([math]::round($(1000000000 / %d)))",
        "Set-VMGpuPartitionAdapter -VMName \"%s\" -MinPartitionCompute ([math]::round($(1000000000 / %d))) -MaxPartitionCompute ([math]::round($(1000000000 / %d))) -OptimalPartitionCompute ([math]::round($(1000000000 / %d)))",
    ],
    "no_mount_dda": "Dismount-VMHostAssignableDevice -Force -LocationPath \"%s\"",
    "ok_mount_dda": "Mount-VMHostAssignableDevice -Force -LocationPath \"%s\"",
    "add_dda_name": "Add-VMAssignableDevice -LocationPath \"%s\" -VMName \"%s\"",
    "del_dda_name": "Remove-VMAssignableDevice -LocationPath \"%s\" -VMName \"%s\"",
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
        update_cmd = (ps1_cmd['get_gpu_name'])
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
        update_cmd = (ps1_cmd['get_mem_size'] % self.vmx_name)
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

    def del_gpu_name(self):
        self.log_apis("移除显卡分配: %s" % self.vmx_name)
        update_cmd = (ps1_cmd['del_gpu_name'] % self.vmx_name)
        result_cmd = PS1Loader.cmd(update_cmd, self.log_apis)
        self.log_apis("删除显卡结果: %s" % result_cmd)

    def add_gpu_name(self, gpu_path):
        self.log_apis("添加显卡分配: %s" % gpu_path)
        update_cmd = (ps1_cmd['add_gpu_name'] % (self.vmx_name, gpu_path))
        result_cmd = PS1Loader.cmd(update_cmd, self.log_apis)
        self.log_apis("添加显卡结果: %s" % result_cmd)
        self.add_gpu_file()

    def add_gpu_file(self):
        self.log_apis("更新显卡驱动: %s-%s" % (self.vmx_name, self.gpu_name))
        result_cmd = PS1Loader("UpdateVM.ps1 %s %s" % (self.vmx_name, self.gpu_name))
        result_cmd.setDaemon(True)
        result_cmd.start()

    def set_gpu_size(self, gpu_size):
        self.log_apis("修改动态分配: Min %s" % gpu_size)
        gpu_size = int(100 / gpu_size)
        for execute_cmd in ps1_cmd['set_gpu_size']:
            update_cmd = (execute_cmd % (self.vmx_name, gpu_size,
                                         gpu_size, gpu_size))
            result_cmd = PS1Loader.cmd(update_cmd, self.log_apis)
            self.log_apis("修改分配结果: %s" % result_cmd)

    def set_mem_size(self, mem_size, var_name):
        self.log_apis("设置映射内存: %s=%sMB" % var_name, mem_size)
        update_cmd = (ps1_cmd['set_mem_size'] % (var_name, mem_size, self.vmx_name))
        result_cmd = PS1Loader.cmd(update_cmd, self.log_apis)
        self.log_apis("设置内存结果: %s" % result_cmd)

    def add_dda_pass(self, dda_name):
        self.log_apis("卸载当前显卡: %s" % dda_name)
        update_cmd = (ps1_cmd['no_mount_dda'] % dda_name)
        result_cmd = PS1Loader.cmd(update_cmd, self.log_apis)
        self.log_apis("卸载当前显卡结果: %s" % result_cmd)
        self.log_apis("分配当前显卡: %s" % self.vmx_name)
        update_cmd = (ps1_cmd['add_dda_name'] % (dda_name, self.vmx_name))
        result_cmd = PS1Loader.cmd(update_cmd, self.log_apis)
        self.log_apis("分配显卡结果: %s" % result_cmd)

    def del_dda_pass(self, dda_name):
        self.log_apis("删除当前显卡: %s" % self.vmx_name)
        update_cmd = (ps1_cmd['del_dda_name'] % (dda_name, self.vmx_name))
        result_cmd = PS1Loader.cmd(update_cmd, self.log_apis)
        self.log_apis("删除显卡结果: %s" % result_cmd)
        self.log_apis("加载当前显卡: %s" % dda_name)
        update_cmd = (ps1_cmd['ok_mount_dda'] % dda_name)
        result_cmd = PS1Loader.cmd(update_cmd, self.log_apis)
        self.log_apis("加载当前显卡结果: %s" % result_cmd)

