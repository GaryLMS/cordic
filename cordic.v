// Calculation of sin and cos value
module cordic(clk, angle, out_x, out_y, in_valid, out_valid);

parameter WIDTH = 16;
parameter ANGLE_WIDTH = 32;

// 2^32 / 360 degrees
input signed [ANGLE_WIDTH-1 : 0] angle;

input clk;
input in_valid;
output reg out_valid;
output signed [WIDTH : 0] out_x; // xxx.xx_xxxx_xxxx_xxxx
output signed [WIDTH : 0] out_y; // xxx.xx_xxxx_xxxx_xxxx


// atan table //
wire signed [ANGLE_WIDTH-1 : 0] atan_table [0:WIDTH-1];
assign atan_table[00] = 32'b00100000000000000000000000000000;
assign atan_table[01] = 32'b00010010111001000000010100011101;
assign atan_table[02] = 32'b00001001111110110011100001011011;
assign atan_table[03] = 32'b00000101000100010001000111010100;
assign atan_table[04] = 32'b00000010100010110000110101000011;
assign atan_table[05] = 32'b00000001010001011101011111100001;
assign atan_table[06] = 32'b00000000101000101111011000011110;
assign atan_table[07] = 32'b00000000010100010111110001010101;
assign atan_table[08] = 32'b00000000001010001011111001010011;
assign atan_table[09] = 32'b00000000000101000101111100101110;
assign atan_table[10] = 32'b00000000000010100010111110011000;
assign atan_table[11] = 32'b00000000000001010001011111001100;
assign atan_table[12] = 32'b00000000000000101000101111100110;
assign atan_table[13] = 32'b00000000000000010100010111110011;
assign atan_table[14] = 32'b00000000000000001010001011111001;
assign atan_table[15] = 32'b00000000000000000101000101111100;


reg signed [WIDTH : 0] cal_x [ 0 : WIDTH];
reg signed [WIDTH : 0] cal_y [ 0 : WIDTH];
reg signed [ANGLE_WIDTH-1 : 0] cal_z [ 0 : WIDTH];

reg signed [ANGLE_WIDTH-1 : 0] correct_angle;
reg [WIDTH: 0] delay_valid;


// initial stage setup //

always @(posedge clk)
begin
    case(angle[31:30])
        2'b00, 2'b11: // 1st and 4th quadrant, +90 degrees ~ -90 degrees
        begin
            cal_x[0] <= {3'b000, 14'b10011011011101};// cosine constant, ~0.6072529
            cal_y[0] <= 0;
            cal_z[0] <= angle;
        end
        
        2'b01: // 2nd quadrant, +90 ~ + 180 degrees
        begin
            cal_x[0] <= 0;
            cal_y[0] <= {3'b000, 14'b10011011011101};
            cal_z[0] <= {2'b00, angle[29:0]};
        end
        
        2'b10: // 3rd quadrant, +180 degrees ~ + 270 degrees
        begin
            cal_x[0] <= 0;
            cal_y[0] <= -{3'b000, 14'b10011011011101};
            cal_z[0] <= {2'b11, angle[29:0]};
        end
        
    endcase
end

always @(posedge clk) begin

    delay_valid[0] <= in_valid;
end


// pipeline stage //

genvar j;
generate
for (j=0; j<WIDTH; j=j+1)
begin
    
    always @(posedge clk) 
    begin
        delay_valid[j+1] <= delay_valid[j];
    end
end

endgenerate

// genvar i;
// generate
// for (i=0; i < 8; i=i+1)
// begin:

  // always @(posedge clk)
  // begin
    // if(cal_z[i][ANGLE_WIDTH-1] == 0) begin
        // cal_x[i+1] = cal_x[i] - (cal_y[i] >>> i);
        // cal_y[i+1] = cal_y[i] + (cal_x[i] >>> i);
        // cal_z[i+1] = cal_z[i] - atan_table[i];
    // end
    // else begin
        // cal_x[i+1] = cal_x[i] + (cal_y[i] >>> i);
        // cal_y[i+1] = cal_y[i] - (cal_x[i] >>> i);
        // cal_z[i+1] = cal_z[i] + atan_table[i];
    // end
  // end
// end
// endgenerate


// stage 1//
always @(posedge clk)
begin
    
    if(cal_z[0][ANGLE_WIDTH-1] === 0) begin // remaining angle is positive
        cal_x[1] <= cal_x[0] - (cal_y[0]);
        cal_y[1] <= cal_y[0] + (cal_x[0]);
        cal_z[1] <= cal_z[0] - atan_table[0];
    end
    else begin
        cal_x[1] <= cal_x[0] + (cal_y[0]);
        cal_y[1] <= cal_y[0] - (cal_x[0]);
        cal_z[1] <= cal_z[0] + atan_table[0];
    end
end

// stage 2//
always @(posedge clk)
begin
    if(cal_z[1][ANGLE_WIDTH-1] === 0) begin
        cal_x[2] <= cal_x[1] - (cal_y[1] >>> 1);
        cal_y[2] <= cal_y[1] + (cal_x[1] >>> 1);
        cal_z[2] <= cal_z[1] - atan_table[1];
    end
    else begin
        cal_x[2] <= cal_x[1] + (cal_y[1] >>> 1);
        cal_y[2] <= cal_y[1] - (cal_x[1] >>> 1);
        cal_z[2] <= cal_z[1] + atan_table[1];
    end
end

// stage 3//
always @(posedge clk)
begin
    if(cal_z[2][ANGLE_WIDTH-1] === 0) begin
        cal_x[3] <= cal_x[2] - (cal_y[2] >>> 2);
        cal_y[3] <= cal_y[2] + (cal_x[2] >>> 2);
        cal_z[3] <= cal_z[2] - atan_table[2];
    end
    else begin
        cal_x[3] <= cal_x[2] + (cal_y[2] >>> 2);
        cal_y[3] <= cal_y[2] - (cal_x[2] >>> 2);
        cal_z[3] <= cal_z[2] + atan_table[2];
    end
end

// stage 4//
always @(posedge clk)
begin
    if(cal_z[3][ANGLE_WIDTH-1] === 0) begin
        cal_x[4] <= cal_x[3] - (cal_y[3] >>> 3);
        cal_y[4] <= cal_y[3] + (cal_x[3] >>> 3);
        cal_z[4] <= cal_z[3] - atan_table[3];
    end
    else begin
        cal_x[4] <= cal_x[3] + (cal_y[3] >>> 3);
        cal_y[4] <= cal_y[3] - (cal_x[3] >>> 3);
        cal_z[4] <= cal_z[3] + atan_table[3];
    end
end

// stage 5//
always @(posedge clk)
begin
    if(cal_z[4][ANGLE_WIDTH-1] === 0) begin
        cal_x[5] <= cal_x[4] - (cal_y[4] >>> 4);
        cal_y[5] <= cal_y[4] + (cal_x[4] >>> 4);
        cal_z[5] <= cal_z[4] - atan_table[4];
    end
    else begin                
        cal_x[5] <= cal_x[4] + (cal_y[4] >>> 4);
        cal_y[5] <= cal_y[4] - (cal_x[4] >>> 4);
        cal_z[5] <= cal_z[4] + atan_table[4];
    end
end

// stage 6//
always @(posedge clk)
begin
    if(cal_z[5][ANGLE_WIDTH-1] === 0) begin
        cal_x[6] <= cal_x[5] - (cal_y[5] >>> 5);
        cal_y[6] <= cal_y[5] + (cal_x[5] >>> 5);
        cal_z[6] <= cal_z[5] - atan_table[5];
    end
    else begin
        cal_x[6] <= cal_x[5] + (cal_y[5] >>> 5);
        cal_y[6] <= cal_y[5] - (cal_x[5] >>> 5);
        cal_z[6] <= cal_z[5] + atan_table[5];
    end
end

// stage 7//
always @(posedge clk)
begin
    if(cal_z[6][ANGLE_WIDTH-1] === 0) begin
        cal_x[7] <= cal_x[6] - (cal_y[6] >>> 6);
        cal_y[7] <= cal_y[6] + (cal_x[6] >>> 6);
        cal_z[7] <= cal_z[6] - atan_table[6];
    end
    else begin
        cal_x[7] <= cal_x[6] + (cal_y[6] >>> 6);
        cal_y[7] <= cal_y[6] - (cal_x[6] >>> 6);
        cal_z[7] <= cal_z[6] + atan_table[6];
    end
end

// stage 8//
always @(posedge clk)
begin
    if(cal_z[7][ANGLE_WIDTH-1] === 0) begin
        cal_x[8] <= cal_x[7] - (cal_y[7] >>> 7);
        cal_y[8] <= cal_y[7] + (cal_x[7] >>> 7);
        cal_z[8] <= cal_z[7] - atan_table[7];
    end
    else begin
        cal_x[8] <= cal_x[7] + (cal_y[7] >>> 7);
        cal_y[8] <= cal_y[7] - (cal_x[7] >>> 7);
        cal_z[8] <= cal_z[7] + atan_table[7];
    end
end

// stage 9//
always @(posedge clk)
begin
    if(cal_z[8][ANGLE_WIDTH-1] === 0) begin
        cal_x[9] <= cal_x[8] - (cal_y[8] >>> 8);
        cal_y[9] <= cal_y[8] + (cal_x[8] >>> 8);
        cal_z[9] <= cal_z[8] - atan_table[8];
    end
    else begin
        cal_x[9] <= cal_x[8] + (cal_y[8] >>> 8);
        cal_y[9] <= cal_y[8] - (cal_x[8] >>> 8);
        cal_z[9] <= cal_z[8] + atan_table[8];
    end
end

// stage 10//
always @(posedge clk)
begin
    if(cal_z[9][ANGLE_WIDTH-1] === 0) begin
        cal_x[10] <= cal_x[9] - (cal_y[9] >>> 9);
        cal_y[10] <= cal_y[9] + (cal_x[9] >>> 9);
        cal_z[10] <= cal_z[9] - atan_table[9];
    end
    else begin
        cal_x[10] <= cal_x[9] + (cal_y[9] >>> 9);
        cal_y[10] <= cal_y[9] - (cal_x[9] >>> 9);
        cal_z[10] <= cal_z[9] + atan_table[9];
    end
end

// stage 11//
always @(posedge clk)
begin
    if(cal_z[10][ANGLE_WIDTH-1] === 0) begin
        cal_x[11] <= cal_x[10] - (cal_y[10] >>> 10);
        cal_y[11] <= cal_y[10] + (cal_x[10] >>> 10);
        cal_z[11] <= cal_z[10] - atan_table[10];
    end
    else begin
        cal_x[11] <= cal_x[10] + (cal_y[10] >>> 10);
        cal_y[11] <= cal_y[10] - (cal_x[10] >>> 10);
        cal_z[11] <= cal_z[10] + atan_table[10];
    end
end

// stage 12//
always @(posedge clk)
begin
    if(cal_z[11][ANGLE_WIDTH-1] === 0) begin
        cal_x[12] <= cal_x[11] - (cal_y[11] >>> 11);
        cal_y[12] <= cal_y[11] + (cal_x[11] >>> 11);
        cal_z[12] <= cal_z[11] - atan_table[11];
    end
    else begin
        cal_x[12] <= cal_x[11] + (cal_y[11] >>> 11);
        cal_y[12] <= cal_y[11] - (cal_x[11] >>> 11);
        cal_z[12] <= cal_z[11] + atan_table[11];
    end
end

// stage 13//
always @(posedge clk)
begin
    if(cal_z[12][ANGLE_WIDTH-1] === 0) begin
        cal_x[13] <= cal_x[12] - (cal_y[12] >>> 12);
        cal_y[13] <= cal_y[12] + (cal_x[12] >>> 12);
        cal_z[13] <= cal_z[12] - atan_table[12];
    end
    else begin
        cal_x[13] <= cal_x[12] + (cal_y[12] >>> 12);
        cal_y[13] <= cal_y[12] - (cal_x[12] >>> 12);
        cal_z[13] <= cal_z[12] + atan_table[12];
    end
end

// stage 14//
always @(posedge clk)
begin
    if(cal_z[13][ANGLE_WIDTH-1] === 0) begin
        cal_x[14] <= cal_x[13] - (cal_y[13] >>> 13);
        cal_y[14] <= cal_y[13] + (cal_x[13] >>> 13);
        cal_z[14] <= cal_z[13] - atan_table[13];
    end
    else begin
        cal_x[14] <= cal_x[13] + (cal_y[13] >>> 13);
        cal_y[14] <= cal_y[13] - (cal_x[13] >>> 13);
        cal_z[14] <= cal_z[13] + atan_table[13];
    end
end

// stage 15//
always @(posedge clk)
begin
    if(cal_z[14][ANGLE_WIDTH-1] === 0) begin
        cal_x[15] <= cal_x[14] - (cal_y[14] >>> 14);
        cal_y[15] <= cal_y[14] + (cal_x[14] >>> 14);
        cal_z[15] <= cal_z[14] - atan_table[14];
    end
    else begin
        cal_x[15] <= cal_x[14] + (cal_y[14] >>> 14);
        cal_y[15] <= cal_y[14] - (cal_x[14] >>> 14);
        cal_z[15] <= cal_z[14] + atan_table[14];
    end
end

// stage 16//
always @(posedge clk)
begin
    if(cal_z[15][ANGLE_WIDTH-1] === 0) begin
        cal_x[16] <= cal_x[15] - (cal_y[15] >>> 15);
        cal_y[16] <= cal_y[15] + (cal_x[15] >>> 15);
        cal_z[16] <= cal_z[15] - atan_table[15];
    end
    else begin
        cal_x[16] <= cal_x[15] + (cal_y[15] >>> 15);
        cal_y[16] <= cal_y[15] - (cal_x[15] >>> 15);
        cal_z[16] <= cal_z[15] + atan_table[15];
    end
end

assign out_x = cal_x[16];
assign out_y = cal_y[16];

always @(*) begin
    out_valid = delay_valid[WIDTH];
    end
endmodule
