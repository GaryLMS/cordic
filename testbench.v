`include "cordic.v"
`define CLK_PERIOD  30.0

module testbench();

parameter WIDTH = 16;
parameter ANGLE_WIDTH = 32;

// 2^32 / 360 degrees
reg signed [ANGLE_WIDTH-1 : 0] angle;
reg clk;
integer idx;
reg signed [63:0] i;
wire signed [WIDTH : 0] out_x; // xxx.xx_xxxx_xxxx_xxxx
wire signed [WIDTH : 0] out_y; // xxx.xx_xxxx_xxxx_xxxx
reg in_valid;
wire out_valid;
cordic cordic_test(.clk(clk), .angle(angle), .out_x(out_x), .out_y(out_y), .in_valid(in_valid), .out_valid(out_valid) );

always #(`CLK_PERIOD/2) clk=~clk;

initial begin
    $dumpfile("testbench.vcd");
    $dumpvars(0, testbench);
    for (idx = 0; idx < 9; idx = idx + 1) $dumpvars(0, cordic_test.cal_x[idx]);
    for (idx = 0; idx < 9; idx = idx + 1) $dumpvars(0, cordic_test.cal_y[idx]);
    for (idx = 0; idx < 9; idx = idx + 1) $dumpvars(0, cordic_test.cal_z[idx]);
    
    angle = 0;
    clk = 1'b0;
    in_valid = 1'b0; 
    @(posedge clk);
   
   repeat(3) begin
       for (i = 0; i < 360; i = i + 1)     // from 0 to 359 degrees in 1 degree increments
       begin
          @(negedge clk);
          in_valid = 1'b1;
          angle = ((1 << 32)*i)/360;    // example: 45 deg = 45/360 * 2^32 = 32'b00100000000000000000000000000000 = 45.000 degrees -> atan(2^0)
          $display ("angle = %d, %h",i, angle);
       end
   end
    
    
    
    //@(negedge clk) angle = 32'b00010101010101010101010101010101; // 30 degrees
    //in_valid = 1'b1;
    @(negedge clk) in_valid = 1'b0;
    angle = 0;
    // @(negedge clk) angle = 32'b00100000000000000000000000000000; // 45 degrees
    // @(negedge clk) angle = 32'b01010101010101010101010101010101; // 120 degrees
    // @(negedge clk) angle = 32'b10010101010101010101010101010101;// 210 degrees
    
    
    
    #1000 $finish;
    


end


endmodule
