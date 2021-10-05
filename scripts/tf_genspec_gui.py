#!/usr/bin/env python3
#
# TextFormats GUI
#
from tkinter import *
from tkinter import ttk, filedialog, messagebox
import os.path
from textformats import Specification
import tempfile
import traceback
from idlelib.tooltip import Hovertip

root = Tk()
root.title("TextFormats Specification Generator")
lf1 = ttk.Labelframe(root, padding="3 3 12 12", text="Wizard")
lf1.grid(column=0, row=0, sticky=(N, W, E, S))
lf2 = ttk.Labelframe(root, padding="3 3 12 12", text="Specification")
lf2.grid(column=1, row=0, sticky=(N, W, E, S))
root.columnconfigure(0, weight=1)
root.columnconfigure(1, weight=1)
root.rowconfigure(0, weight=1)

spec = Text(lf2, width=40, height=50, wrap = "none")
spec.config(state="disabled")
ys = ttk.Scrollbar(lf2, orient = 'vertical', command = spec.yview)
xs = ttk.Scrollbar(lf2, orient = 'horizontal', command = spec.xview)
spec['yscrollcommand'] = ys.set
spec['xscrollcommand'] = xs.set
spec.grid(column = 0, row = 0, sticky = 'nwes')
xs.grid(column = 0, row = 1, sticky = 'we', pady=10)
ys.grid(column = 1, row = 0, sticky = 'ns')

wiz0 = Frame(lf1, width=400, height=50)

default_file_suffix = ".tf.yaml"

def on_specname_change(var, indx, mode):
  filename.set(specname.get() + default_file_suffix)
  namespace.set(specname.get())
  return

specname_frame = ttk.Frame(wiz0)
specname = StringVar()
specname.trace_add("write", on_specname_change)
specname_label=ttk.Label(specname_frame, text="Format name:")
specname_label.grid(column=0, row=0, padx=10)
specname_entry=ttk.Entry(specname_frame, textvariable=specname)
specname_entry.grid(column=1, row=0)
specname_frame.pack(side="top", fill="x")

filename_frame = ttk.Frame(wiz0)
filename_help="Filename (by default, the format name with the suffix "+\
              f"{default_file_suffix})"
Hovertip(filename_frame, filename_help, 500)
filename = StringVar()
filename.set(default_file_suffix)
filename_label=ttk.Label(filename_frame, text="File name:")
filename_label.grid(column=0, row=1, padx=10)
filename_entry=ttk.Entry(filename_frame, textvariable=filename)
filename_entry.grid(column=1, row=1)
filename_frame.pack(side="top", fill="x", pady=10)

namespace_frame = ttk.Frame(wiz0)
namespace = StringVar()
namespace_help="Namespace (by default, the same string as the format name)\n"+\
    "The namespace is used as a prefix (<ns>::) to the datatype names, when the\n"+\
    "specification is imported in other specifications."
Hovertip(namespace_frame, namespace_help, 500)
namespace_label=ttk.Label(namespace_frame, text="Namespace:")
namespace_label.grid(column=0, row=1, padx=10)
namespace_entry=ttk.Entry(namespace_frame, textvariable=namespace)
namespace_entry.grid(column=1, row=1)
namespace_frame.pack(side="top", fill="x")

def on_scope_change(var, indx, mode):
  scopeval = scope.get()
  maindt_name.set(scopeval)
  if scopeval == "unit":
    scope_unitsize_entry.config(state="enabled")
  else:
    scope_unitsize_entry.config(state="disabled")
  return

scope_frame = ttk.Frame(wiz0)
scope = StringVar()
scope_label=ttk.Label(wiz0, text="Scope of main datatype:")
scope_help="Select the scope of the main datatype definition\n\n" +\
           "Possible values:\n"+\
           "- 'line': a single line of the file\n"+\
           "- 'unit': an unit consisting of a fixed number of lines\n"+\
           "- 'section': part of a file (parsed greedily)\n"+\
           "- 'file': entire file (default value)"
Hovertip(scope_label, scope_help, 500)
Hovertip(scope_frame, scope_help, 500)
scope_label.pack(side="top", fill="x", pady=(10,0))
scope_line=ttk.Radiobutton(scope_frame, text="line", value="line", variable=scope).grid(column=0, row=1)
scope_unit=ttk.Radiobutton(scope_frame, text="unit", value="unit",
    variable=scope).grid(column=1, row=1)
scope_frame.pack(side="top", fill="x", pady=0)
scope_unitsize_label = ttk.Label(scope_frame, text="(")
scope_unitsize_label.grid(column=3, row=1)
scope_unitsize = StringVar()
scope_unitsize.set(2)
scope_unitsize_entry = ttk.Entry(scope_frame, textvariable=scope_unitsize,
    width=3)
scope_unitsize_entry.grid(column=4, row=1)
scope_unitsize_entry.config(state="disabled")
scope_unitsize_label2 = ttk.Label(scope_frame, text="lines)")
scope_unitsize_label2.grid(column=5, row=1)
scope_sep2 = ttk.Separator(scope_frame)
scope_sep2.grid(column=6, row=1, padx=5)
scope_section=ttk.Radiobutton(scope_frame, text="section", variable=scope,
    value="section").grid(column=7, row=1)
scope_file=ttk.Radiobutton(scope_frame, text="file", variable=scope,
    value="file").grid(column=8, row=1)
scope.set("file")

maindt_name_frame = ttk.Frame(wiz0)
maindt_name_help = "Name of the main datatype\n"+\
                   "By default, it is named after its scope."
Hovertip(maindt_name_frame, maindt_name_help, 500)
maindt_name = StringVar()
maindt_name_label=ttk.Label(maindt_name_frame, text="Name of main datatype:")
maindt_name_label.grid(column=0, row=1, padx=10)
maindt_name_entry=ttk.Entry(maindt_name_frame, textvariable=maindt_name)
maindt_name_entry.grid(column=1, row=1)
maindt_name_frame.pack(side="top", fill="x", pady=10)
maindt_name.set("file")

scope.trace_add("write", on_scope_change)

wiz0.pack(fill="both", expand=True)


root.mainloop()
