`include "core.sv"
`include "memory.sv"

module SoC (
    input clk,
    input reset
);

//INPUTS
wire [CACHE_LINE_SIZE-1:0] in_imem_read_data;
wire in_imem_ready;

wire [CACHE_LINE_SIZE-1:0] in_dmem_read_data;
wire in_dmem_ready;

//OUTPUTS
wire out_imem_read_en;
wire out_imem_write_en;
wire [31:0] out_imem_addr;
wire [CACHE_LINE_SIZE-1:0] out_imem_write_data;

wire out_dmem_read_en;
wire out_dmem_write_en;
wire [31:0] out_dmem_addr;
wire [CACHE_LINE_SIZE-1:0] out_dmem_write_data;

core core (
    .clk(clk),
    .reset(reset),

    //INPUT
    .in_imem_read_data(in_imem_read_data),
    .in_imem_ready(in_imem_ready),

    .in_dmem_read_data(in_dmem_read_data),
    .in_dmem_ready(in_dmem_ready),

    //OUTPUT
    .out_imem_read_en(out_imem_read_en),
    .out_imem_write_en(out_imem_write_en),
    .out_imem_addr(out_imem_addr),
    .out_imem_write_data(out_imem_write_data),

    .out_dmem_read_en(out_dmem_read_en),
    .out_dmem_write_en(out_dmem_write_en),
    .out_dmem_addr(out_dmem_addr),
    .out_dmem_write_data(out_dmem_write_data)
);

memory memory (
    .clk(clk),
    .reset(reset),

    //INPUT
    .in_imem_read_en(out_imem_read_en),
    .in_imem_write_en(out_imem_write_en),
    .in_imem_addr(out_imem_addr),
    .in_imem_write_data(out_imem_write_data),

    .in_dmem_read_en(out_dmem_read_en),
    .in_dmem_write_en(out_dmem_write_en),
    .in_dmem_addr(out_dmem_addr),
    .in_dmem_write_data(out_dmem_write_data),

    //OUTPUT
    .out_imem_read_data(in_imem_read_data),
    .out_imem_ready(in_imem_ready),

    .out_dmem_read_data(in_dmem_read_data),
    .out_dmem_ready(in_dmem_ready)  
);

endmodule