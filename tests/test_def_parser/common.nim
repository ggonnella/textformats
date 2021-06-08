import os, streams
import yaml/dom
const specdir = currentSourcePath.parentDir().parentDir() & "/testdata/spec/"

proc get_datatypes*(filename: string): YamlNode =
  let
    filestream = newFileStream(specdir & filename, fmRead)
    yamldoc = load_dom(filestream)
  yamldoc.root["datatypes"]
