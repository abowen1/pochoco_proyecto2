`timescale 1ns/1ps
module tb_timer_soc;
  reg clk=0;
  wire [3:0] leds;
  integer cycle=0, changes=0, previous=0;
  reg [3:0] last=0;
  always #20 clk=~clk;
  pochoco_soc #(.MemFile("build/timer_test_fast.hex")) dut(
    .i_Clk(clk),.i_Switch(4'b0),.o_LED(leds),
    .i_SPI_SCLK(1'b0),.i_SPI_MOSI(1'b0),.i_SPI_CS_n(1'b1),.o_SPI_MISO());
  always @(posedge dut.clk) begin
    cycle=cycle+1;
    #1;
    if(leds!==last && cycle>20) begin
      if(leds!==0 && leds!==15) $fatal(1,"unexpected LED pattern");
      if(changes>0 && (cycle-previous<128 || cycle-previous>256))
        $fatal(1,"wrong wait length: %0d",cycle-previous);
      previous=cycle; last=leds; changes=changes+1;
      if(changes==5) begin
        $display("PASS full SoC: assembler program, counter reads, LED timestamps and repeated waits");
        $finish;
      end
    end
    if(cycle>10000) $fatal(1,"SoC timeout");
  end
endmodule
