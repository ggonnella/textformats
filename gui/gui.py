#!/usr/bin/env python3
#
# TextFormats GUI
#
from tkinter import *
from tkinter import ttk, filedialog
import os.path
from textformats import Specification
import tempfile

root = Tk()
root.title("TextFormats decoder")
lf1 = ttk.Labelframe(root, padding="3 3 12 12", text="Encoded")
lf1.grid(column=0, row=0, sticky=(N, W, E, S))
lf2 = ttk.Labelframe(root, padding="3 3 12 12", text="Specification")
lf2.grid(column=1, row=0, sticky=(N, W, E, S))
lf3 = ttk.Labelframe(root, padding="3 3 12 12", text="Decoded")
lf3.grid(column=2, row=0, sticky=(N, W, E, S))
root.columnconfigure(1, weight=1)
root.columnconfigure(2, weight=1)
root.columnconfigure(0, weight=1)
root.rowconfigure(0, weight=1)

def load_encoded():
  filepath = filedialog.askopenfile()
  if not filepath:
    return
  t1.delete(1.0, END)
  text = filepath.read()
  t1.insert(END, text)
  lf1.config(text=f"Encoded = {os.path.basename(filepath.name)}")

def save_encoded():
  filepath = filedialog.asksaveasfilename()
  if not filepath:
    return
  text = t1.get(1.0, END)
  with open(filepath, "w") as output_file:
    output_file.write(text)
  lf1.config(text=f"Encoded = {os.path.basename(filepath)}")

def load_decoded():
  filepath = filedialog.askopenfile()
  if not filepath:
    return
  t3.delete(1.0, END)
  text = filepath.read()
  t3.insert(END, text)
  lf3.config(text=f"Decoded = {os.path.basename(filepath.name)}")

def save_decoded():
  filepath = filedialog.asksaveasfilename()
  if not filepath:
    return
  text = t3.get(1.0, END)
  with open(filepath, "w") as output_file:
    output_file.write(text)
  lf3.config(text=f"Decoded = {os.path.basename(filepath)}")

def load_spec():
  filepath = filedialog.askopenfile()
  if not filepath:
    return
  t2.delete(1.0, END)
  text = filepath.read()
  t2.insert(END, text)
  lf2.config(text=f"Specification = {os.path.basename(filepath.name)}")

def save_spec():
  filepath = filedialog.asksaveasfilename()
  if not filepath:
    return
  text = t2.get(1.0, END)
  with open(filepath, "w") as output_file:
    output_file.write(text)
  lf2.config(text=f"Specification = {os.path.basename(filepath)}")


def run_decode():
  specfile = tempfile.NamedTemporaryFile()
  spectext = t2.get(1.0, END)
  specfile.write(spectext.encode("UTF8"))
  specfile.flush()
  spec = Specification(specfile.name)
  specfile.close()
  ddef = spec["default"]
  encoded = t1.get(1.0, END).rstrip()
  decoded = ddef.decode(encoded, True)
  t3.delete(1.0, END)
  t3.insert(END, decoded)

def run_encode():
  specfile = tempfile.NamedTemporaryFile()
  spectext = t2.get(1.0, END)
  specfile.write(spectext.encode("UTF8"))
  specfile.flush()
  spec = Specification(specfile.name)
  specfile.close()
  ddef = spec["default"]
  decoded = t3.get(1.0, END).rstrip()
  encoded = ddef.encode(decoded, True)
  t1.delete(1.0, END)
  t1.insert(END, encoded)

bls1 = ttk.Frame(lf1)
bls1.grid(column=0, row=0, pady=10)
b_l1 = ttk.Button(bls1, text="Open...", command=load_encoded)
b_s1 = ttk.Button(bls1, text="Save as...", command=save_encoded)
b_l1.grid(column=0, row=0, padx=10)
b_s1.grid(column=1, row=0)
t1 = Text(lf1, width=40, height=50, wrap = "none")
ys1 = ttk.Scrollbar(lf1, orient = 'vertical', command = t1.yview)
xs1 = ttk.Scrollbar(lf1, orient = 'horizontal', command = t1.xview)
t1['yscrollcommand'] = ys1.set
t1['xscrollcommand'] = xs1.set
t1.insert('end', "111lorem ipsum...\n...\n...")
t1.grid(column = 0, row = 1, sticky = 'nwes')
xs1.grid(column = 0, row = 2, sticky = 'we')
ys1.grid(column = 1, row = 1, sticky = 'ns')

bls2 = ttk.Frame(lf2)
bls2.grid(column=0, row=0, pady=10)
b_l2 = ttk.Button(bls2, text="Open...", command=load_spec)
b_s2 = ttk.Button(bls2, text="Save as...", command=save_spec)
b_l2.grid(column=0, row=0, padx=10)
b_s2.grid(column=1, row=0)
t2 = Text(lf2, width=40, height=45, wrap = "none")
ys2 = ttk.Scrollbar(lf2, orient = 'vertical', command = t2.yview)
xs2 = ttk.Scrollbar(lf2, orient = 'horizontal', command = t2.xview)
t2['yscrollcommand'] = ys2.set
t2['xscrollcommand'] = xs2.set
t2.insert('end', "222lorem ipsum...\n...\n...")
t2.grid(column = 0, row = 1, sticky = 'nwes')
xs2.grid(column = 0, row = 2, sticky = 'we', pady=10)
ys2.grid(column = 1, row = 1, sticky = 'ns')
b_d = ttk.Button(lf2, text="---.Decode.-->", command=run_decode)
b_e = ttk.Button(lf2, text="<--.Encode.---", command=run_encode)
b_d.grid(column=0, row=3, pady=10)
b_e.grid(column=0, row=4)

bls3 = ttk.Frame(lf3)
bls3.grid(column=0, row=0, pady=10)
b_l3 = ttk.Button(bls3, text="Open...", command=load_decoded)
b_s3 = ttk.Button(bls3, text="Save as...", command=save_decoded)
b_l3.grid(column=0, row=0, padx=10)
b_s3.grid(column=1, row=0)
t3 = Text(lf3, width=40, height=50, wrap = "none")
ys3 = ttk.Scrollbar(lf3, orient = 'vertical', command = t3.yview)
xs3 = ttk.Scrollbar(lf3, orient = 'horizontal', command = t3.xview)
t3['yscrollcommand'] = ys3.set
t3['xscrollcommand'] = xs3.set
t3.insert('end', "333lorem ipsum...\n...\n...")
t3.grid(column = 0, row = 1, sticky = 'nwes')
xs3.grid(column = 0, row = 2, sticky = 'we')
ys3.grid(column = 1, row = 1, sticky = 'ns')

root.mainloop()

