transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlib ip
vmap ip ip
vcom -93 -work ip {C:/Users/lazyp/OneDrive/Documents/IRP/IRP_PD-ASP/ip/TdmaMinFifo/TdmaMinFifo.vhd}
vcom -93 -work work {C:/Users/lazyp/OneDrive/Documents/IRP/IRP_PD-ASP/TdmaMin/TdmaMinTypes.vhd}
vcom -93 -work work {C:/Users/lazyp/OneDrive/Documents/IRP/IRP_PD-ASP/TdmaMin/TdmaMinSlots.vhd}
vcom -93 -work work {C:/Users/lazyp/OneDrive/Documents/IRP/IRP_PD-ASP/TdmaMin/TdmaMinSwitch.vhd}
vcom -93 -work work {C:/Users/lazyp/OneDrive/Documents/IRP/IRP_PD-ASP/TdmaMin/TdmaMinInterface.vhd}
vcom -93 -work work {C:/Users/lazyp/OneDrive/Documents/IRP/IRP_PD-ASP/src/PdAsp.vhd}
vcom -93 -work work {C:/Users/lazyp/OneDrive/Documents/IRP/IRP_PD-ASP/TdmaMin/TdmaMinStage.vhd}
vcom -93 -work work {C:/Users/lazyp/OneDrive/Documents/IRP/IRP_PD-ASP/TdmaMin/TdmaMinFabric.vhd}
vcom -93 -work work {C:/Users/lazyp/OneDrive/Documents/IRP/IRP_PD-ASP/TdmaMin/TdmaMin.vhd}
vcom -93 -work work {C:/Users/lazyp/OneDrive/Documents/IRP/IRP_PD-ASP/src/IRP_PD_ASP.vhd}

