`timescale 1ns/1ps
module tb_counter;
  reg clk=0, rst=0, sel=0, req=0, we=0;
  reg [7:0] addr=0;
  reg [31:0] data=0;
  wire [31:0] rd;
  wire [3:0] leds;
  reg [31:0] before_cycle, snapshot;
  always #20 clk=~clk;
  pochoco_periph dut(.clk_i(clk),.rst_ni(rst),.sel_i(sel),.req_i(req),
    .we_i(we),.addr_i(addr),.wdata_i(data),.rdata_o(rd),.leds_o(leds),
    .btn_i(4'b0101),.seg1_o(),.seg2_o());
  task read_at;
    input [7:0] offset;
    begin
      @(negedge clk); sel=1; req=1; we=0; addr=offset;
      before_cycle=dut.cycle_q;
      @(posedge clk); #1;
    end
  endtask
  initial begin
    repeat(2) @(negedge clk);
    if(dut.cycle_q!==0 || dut.led_start_q!==0) $fatal(1,"reset");
    rst=1;
    repeat(5) @(negedge clk);
    if(dut.cycle_q!==5) $fatal(1,"not one count per cycle");
    read_at(12);
    if(rd!==before_cycle) $fatal(1,"counter MMIO read");
    @(negedge clk); we=1; addr=4; data=15; snapshot=dut.cycle_q;
    @(posedge clk); #1;
    if(leds!==15 || dut.led_start_q!==snapshot) $fatal(1,"LED atomic snapshot");
    read_at(16);
    if(rd!==snapshot) $fatal(1,"timestamp MMIO read");
    read_at(8);
    if(rd!==5) $fatal(1,"buttons regression");
    @(negedge clk); we=1; addr=12; data=0; before_cycle=dut.cycle_q;
    @(posedge clk); #1;
    if(dut.cycle_q!==before_cycle+1 || dut.led_start_q!==snapshot) $fatal(1,"counter is not read only");
    @(negedge clk); sel=0; req=0; we=0;
    // Deposit near overflow to test wrap without simulating 2^32 cycles.
    dut.cycle_q=32'hfffffffe;
    repeat(3) @(negedge clk);
    if(dut.cycle_q!==1) $fatal(1,"counter wrap");
    if((dut.cycle_q-32'hfffffffe)!==32'd3) $fatal(1,"wrap subtraction");
    rst=0; #1;
    if(dut.cycle_q!==0 || dut.led_start_q!==0 || leds!==0) $fatal(1,"reset after activity");
    $display("PASS counter: reset, MMIO, atomic LED timestamp, read-only, wrap, buttons");
    $finish;
  end
  initial begin #10000; $fatal(1,"timeout"); end
endmodule
