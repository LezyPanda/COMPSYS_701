To update mif:
- Modify asm_init.asm
- Run asm_to_mif.py

-- Quartus Setup --
open ../GP2/GP2.qpf
Start Compilation
Plug in your FPGA
Tools -> Programmer
Delete all the Devices
Hardware Setup -> Select your FPGA -> close
Auto Detect -> 5CSEMA5 -> ok
Change the File for Device 5CSEMA5 to ../GP2/output files/GP2.sof
Tick Program/Configure for 5CSEMA5
Start

-- Nios II Setup
Quartus -> Eclipse
Open ../GP2/Software
Build Both Projects
Run As -> Nios II Hardware

-- ModelSim Setup --
Setup Quartus Fist
Start Simulation From Quartus
Compile TopLevelTest.vhd
Simulate topleveltest

-- FPGA Control --
KEY0    -> Reset All
KEY1~2  -> Send current SW to corresponding ASP to configure