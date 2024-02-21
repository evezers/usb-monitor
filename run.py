#!/bin/python3
from pathlib import Path
from vunit import VUnit, VUnitCLI
from subprocess import call
from sys import argv

import os

from dotenv import load_dotenv

load_dotenv(os.path.join(os.path.dirname(argv[0]), ".env"))

cli = VUnitCLI()
args = cli.parse_args()

if len(args.test_patterns) == 1 and args.test_patterns[0] != "*":
    argv.append("--gtkwave-args=\"--save=waves/" + args.test_patterns[0] + ".gtkw\"")
else:
    argv.append("--gtkwave-args=\"--save=waves/wave.gtkw\"")

args = cli.parse_args()

def post_run(results):
    results.merge_coverage(file_name="vunit_out/coverage_data")
    if vu.get_simulator_name() == "ghdl":
        os.makedirs("vunit_out/coverage_html", exist_ok=True)
        call(["gcovr", "vunit_out/coverage_data", "-s",
               "--html-details", "vunit_out/coverage_html/index.html",
               "--txt", "vunit_out/coverage.txt",
               "--cobertura", "vunit_out/coverage.xml"
               ])
    if vu.get_simulator_name() == "modelsim":
        call([os.environ["VUNIT_MODELSIM_PATH"] + "/vcover", "report", "-details", "vunit_out/coverage_data", "-html", "-output", "vunit_out/coverage_html"])
        call([os.environ["VUNIT_MODELSIM_PATH"] + "/vcover", "report", "-details", "vunit_out/coverage_data", "-output", "vunit_out/coverage.txt"])

# Create VUnit instance by parsing command line arguments
vu = VUnit.from_args(args=args, compile_builtins=False)

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

# Add waveform automatically when running in GUI mode.
for tb in lib.get_test_benches():
    tb.set_sim_option("modelsim.init_file.gui", "waves/" + tb.name +"_wave.do")

lib.set_sim_option("modelsim.vsim_flags.gui", ["-wlfnocollapse"])

if os.environ.get("ENABLE_COVERAGE") == "true":
    lib.set_sim_option("enable_coverage", True)

    lib.set_compile_option("rivierapro.vcom_flags", ["-coverage", "bs"])
    lib.set_compile_option("rivierapro.vlog_flags", ["-coverage", "bs"])
    lib.set_compile_option("modelsim.vcom_flags", ["+cover=bs"])
    lib.set_compile_option("modelsim.vlog_flags", ["+cover=bs"])
    lib.set_compile_option("enable_coverage", True)

    # Run vunit function
    vu.main(post_run=post_run)
else:
    # Run vunit function
    vu.main()
