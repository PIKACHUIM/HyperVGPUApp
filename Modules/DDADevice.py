from enum import Enum


class DDAType(Enum):
    FAIL = DEV_FAIL_DDA = 0  # 无法DDA，系统错误
    FREE = DEV_FREE_DDA = 1  # 可以DDA，尚未分配
    WAIT = DEV_WAIT_DDA = 2  # 可以DDA，等待分配
    DONE = DEV_DONE_DDA = 3  # 可以DDA，已经分配
    KILL = DEV_WAIT_DEL = 4  # 可以DDA，等待取消
    INIT = DEV_UNKNOWNS = -1  # 未知的状态，忽略

    @staticmethod
    def str(in_data):
        tp_map = [
            "DEV_UNKNOWNS", "DEV_FAIL_DDA",
            "DEV_FREE_DDA", "DEV_WAIT_DDA",
            "DEV_DONE_DDA", "DEV_WAIT_DEL",
        ]
        return tp_map[in_data.value + 1]


DT = DDAType


class DDAData:
    def __init__(self,
                 name: str = "DEV_NAME_ERR",
                 path: str = "",
                 uuid: str = "",
                 text: str = "",
                 flag: DDAType = DDAType.DEV_UNKNOWNS,
                 ):
        self.flag = flag
        self.name = name
        self.path = path
        self.uuid = uuid
        self.text = text
        self.checkDDA()

    def checkDDA(self):
        if self.flag.value == -1:
            if self.text.find("Assignment can work") >= 0:
                self.flag = DDAType.DEV_FREE_DDA
            else:
                self.flag = DDAType.DEV_FAIL_DDA

        pass

    def getState(self):
        if self.flag.value == 0:
            return "❌"
        elif self.flag.value in (1, 3):
            return "✔️"
        elif self.flag.value in (2, 4):
            return "⏳"
        else:
            return "❓"

    def isFreeDDA(self, in_flag=1):
        return self.flag.value == in_flag

    @staticmethod
    def parsedDDA(in_list):
        pass
