from tkinter import ttk
from ttkbootstrap import *


class HintEntry(ttk.Entry):
    def __init__(self, parent, hint, **kw):
        super().__init__(parent, **kw)
        # ttk.Entry.__init__(self, parent, **kw)
        self.placeholder = hint
        self.default_fg_color = "gray"
        self.bind("<FocusIn>", self.foc_in)
        self.bind("<FocusOut>", self.foc_out)
        self.put_placeholder()

    def put_placeholder(self):
        self.insert(0, self.placeholder)
        # self['fg'] = self.default_fg_color

    def foc_in(self, *args):
        self['show'] = '*'
        self.delete('0', 'end')
        # self['fg'] = self.default_fg_color

    def foc_out(self, *args):
        if not self.get():
            self.put_placeholder()
            self['show'] = ''
