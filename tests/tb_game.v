`timescale 1ns/1ps
module tb_game;
  reg clk=0;
  reg [3:0] buttons=0;
  wire [3:0] leds;
  integer cycles=0, successes=0, attempts=0, sum_cycles=0;
  integer start_cycle, elapsed, expected, average, seen=0, start_delay=500;
  reg [51:0] sequence_bits=0;
  reg [31:0] last_counter_read=0;
  reg [3:0] chosen;
  always #20 clk=~clk;
  pochoco_soc #(.MemFile("build/game_fast.hex")) dut(
    .i_Clk(clk),.i_Switch(buttons),.o_LED(leds),
    .i_SPI_SCLK(1'b0),.i_SPI_MOSI(1'b0),.i_SPI_CS_n(1'b1),.o_SPI_MISO());
  always @(posedge dut.clk) begin
    cycles=cycles+1;
    if(dut.per_req && !dut.data_we && dut.data_addr[7:0]==12)
      last_counter_read=dut.u_periph.cycle_q;
    if(cycles>400000) $fatal(1,"game timeout, successes=%0d attempts=%0d",successes,attempts);
  end
  function [7:0] bcd;
    input integer value;
    begin bcd=(value/10)*16+(value%10); end
  endfunction
  task tick;
    input integer count;
    begin repeat(count) @(negedge dut.clk); end
  endtask
  initial begin
    if (!$value$plusargs("START_DELAY=%d", start_delay)) start_delay=500;
    wait(dut.u_periph.digit_q===8'haa); tick(start_delay);
    buttons=1; tick(80); buttons=0;
    while(successes<10) begin
      wait(leds===15); start_cycle=cycles;
      // Holding a button through preparation must delay the target.
      if(attempts==0) begin
        buttons=2; tick(8000);
        if(leds!==15) $fatal(1,"held button accepted before release");
        buttons=0;
      end
      wait(leds===1 || leds===2 || leds===4 || leds===8);
      if(cycles-start_cycle<7680) $fatal(1,"preparation too short");
      chosen=leds; seen=seen|chosen; sequence_bits={sequence_bits[47:0],chosen}; attempts=attempts+1;
      start_cycle=dut.u_periph.led_start_q;
      tick(600+successes*173);
      // One wrong button, simultaneous buttons, then a timeout.
      if(attempts==4) buttons=(chosen==1 ? 2 : 1);
      else if(attempts==6) buttons=15;
      else if(attempts==8) buttons=0;
      else buttons=chosen;
      wait(leds===0);
      elapsed=last_counter_read-start_cycle;
      if(attempts==4 || attempts==6 || attempts==8) begin
        wait(dut.u_periph.digit_q===8'hee);
        if(attempts==8 && elapsed<25600) $fatal(1,"timeout early");
      end else begin
        expected=elapsed/256;
        sum_cycles=sum_cycles+elapsed;
        successes=successes+1;
        tick(1000);
        if(dut.u_periph.digit_q!==bcd(expected))
          $fatal(1,"response %0d expected BCD %h got %h",elapsed,bcd(expected),dut.u_periph.digit_q);
      end
      // Holding through the response must not count again.
      tick(400); buttons=0;
    end
    wait(dut.u_periph.digit_q===8'haa);
    tick(4200);
    average=sum_cycles/2560;
    if(dut.u_periph.digit_q!==bcd(average))
      $fatal(1,"average expected %h got %h",bcd(average),dut.u_periph.digit_q);
    if(attempts!=13) $fatal(1,"errors did not preserve correct rounds");
    if((seen & (seen-1))==0) $fatal(1,"target never varied");
    tick(5000);
    if(leds!==0 || dut.u_periph.digit_q!==bcd(average)) $fatal(1,"average not retained");
    buttons=4; tick(80); buttons=0;
    wait(leds===15);
    $display("PASS game: 10 correct + wrong/multiple/timeout, exact displayed times/average, held release, restart; target mask=%h",seen);
    $display("TARGET_SEQUENCE=%h",sequence_bits);
    $finish;
  end
endmodule
