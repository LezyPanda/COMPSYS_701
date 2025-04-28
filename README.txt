-- ModelSim Setup --
File -> Change Directory -> ../ReCOP (To be sorted)
(If no work directory) -> File -> New Library -> ok
Compile -> compile -> compile all the VHD/VHDL files
Simulate -> Start Simulation.. -> select work/recop_tb2
Add desired signals to Waves
Transcript -> run xxx ns

To Update Memory (mif) just recompile everything and Simulate -> Restart

-- Quartus Setup --
open ../ReCOP (To be sorted)/recop.qpf
Start Compilation
Plug in your FPGA
Tools -> Programmer
Delete all the Devices
Hardware Setup -> Select your FPGA -> close
Auto Detect -> 5CSEMA5 -> ok
Change the File for Device 5CSEMA5 to ../ReCOP (To be sorted)/output files/recop.sof
Tick Program/Configure for 5CSEMA5
Start

To Update Memory (mif) -> Processing -> Update Memory Initialization File
Processing -> Start -> Start Assembler
Reprogram the FPGA -> Tools -> Programmer -> Start


-- Assembler --
We have our python assembler asm_to_mif.py
Double click to run it, it reads ../ReCOP-ASM Package/test.asm and output to:
../modelsim/rawOutput.mif
and ../ReCOP (To be sorted)/rawOutput.mif


28/04/2025
Starting from the right switches, indicates the id of the register.
The left most segment display is the reg selected, the right most is the value of it (0~9)
Hold the KEY0 (right most button) to show

Since only 1 7-segment display is used for each purpose, it will only display the index of
register 0 ~ 9, althought it works for register 0 ~ 15.
The value of the selected register only supports 0 ~ 9, means it will only display if the
data first digit is within 0 ~ 9.


