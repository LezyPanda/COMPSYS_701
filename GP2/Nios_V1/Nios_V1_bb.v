
module Nios_V1 (
	clk_clk,
	hex0_external_connection_export,
	hex1_external_connection_export,
	hex2_external_connection_export,
	hex3_external_connection_export,
	hex4_external_connection_export,
	hex5_external_connection_export,
	reset_reset_n,
	tdma_recv_addr_external_connection_export,
	tdma_recv_data_external_connection_export,
	tdma_send_addr_external_connection_export,
	tdma_send_data_external_connection_export);	

	input		clk_clk;
	output	[6:0]	hex0_external_connection_export;
	output	[6:0]	hex1_external_connection_export;
	output	[6:0]	hex2_external_connection_export;
	output	[6:0]	hex3_external_connection_export;
	output	[6:0]	hex4_external_connection_export;
	output	[6:0]	hex5_external_connection_export;
	input		reset_reset_n;
	input	[7:0]	tdma_recv_addr_external_connection_export;
	input	[31:0]	tdma_recv_data_external_connection_export;
	output	[7:0]	tdma_send_addr_external_connection_export;
	output	[31:0]	tdma_send_data_external_connection_export;
endmodule
