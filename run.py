#!/bin/python3
from pathlib import Path
from vunit import VUnit
from subprocess import call
from sys import argv

import os

from dotenv import load_dotenv

load_dotenv()

argv.append("--gtkwave-args=\"--save=waves/wave.gtkw\"")

def post_run(results):
    if vu.get_simulator_name() != "ghdl":
        results.merge_coverage(file_name="vunit_out/coverage_data")
        if vu.get_simulator_name() == "ghdl":
            call(["gcovr", "vunit_out/coverage_data"])
        if vu.get_simulator_name() == "modelsim":
            call([os.environ["VUNIT_MODELSIM_PATH"] + "/vcover", "report", "-details", "vunit_out/coverage_data", "-html"])
            call([os.environ["VUNIT_MODELSIM_PATH"] + "/vcover", "report", "-details", "vunit_out/coverage_data", "-output", "vunit_out/coverage.txt"])

# Create VUnit instance by parsing command line arguments
vu = VUnit.from_argv(compile_builtins=False)

# Optionally add VUnit's builtin HDL utilities for checking, logging, communication...
# See http://vunit.github.io/hdl_libraries.html.
vu.add_vhdl_builtins()
# or
# vu.add_verilog_builtins()

# Add OSVVM support
vu.add_osvvm()

# Create library 'lib'
lib = vu.add_library("lib")

# Add all files ending in .vhd in current working directory to library
lib.add_source_files("hdl/*.vhdl")

if vu.get_simulator_name() != "ghdl":
    lib.set_sim_option("enable_coverage", True)

    lib.set_compile_option("rivierapro.vcom_flags", ["-coverage", "bs"])
    lib.set_compile_option("rivierapro.vlog_flags", ["-coverage", "bs"])
    lib.set_compile_option("modelsim.vcom_flags", ["+cover=bs"])
    lib.set_compile_option("modelsim.vlog_flags", ["+cover=bs"])
    lib.set_compile_option("enable_coverage", True)

# Add waveform automatically when running in GUI mode.
for tb in lib.get_test_benches():
    tb.set_sim_option("modelsim.init_file.gui", "waves/" + tb.name +"_wave.do")
    
# Run vunit function
vu.main(post_run=post_run)
