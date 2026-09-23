`timescale 1ns/1ps
module tb_diagnostic;
reg clk=0; reg [3:0] buttons=0; wire [3:0] leds;
integer stage=0, cycles=0; reg [7:0] last=0;
always #20 clk=~clk;
pochoco_soc #(.MemFile("build/diagnostic_fast.hex")) dut(
 .i_Clk(clk),.i_Switch(buttons),.o_LED(leds),.i_SPI_SCLK(1'b0),.i_SPI_MOSI(1'b0),.i_SPI_CS_n(1'b1));
always @(negedge clk) begin
 cycles=cycles+1;
 if(dut.u_periph.digit_q!==last && cycles>20) begin
  last=dut.u_periph.digit_q; stage=stage+1;
  if(stage<=4 && last!==stage*17) $fatal(1,"wrong stage %0d value=%h",stage,last);
  if(stage==5) begin
   if(last!==8'haa) $fatal(1,"missing AA");
   buttons=5;
  end
 end
 if(stage==5 && leds===5) begin $display("PASS diagnostic: 11,22,33,44,AA + buttons"); $finish; end
 if(cycles>5000) $fatal(1,"timeout");
end
endmodule
