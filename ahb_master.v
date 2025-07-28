`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////// 
// Engineer: Varun Pateliya
// 
// Design Name: ahb
// Module Name: ahb_master
// Project Name: ahb_protocol
// Tool Versions: Vivado 2018.2
// Description: master module of AHB protocol
// Revision: Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ahb_master #(
  parameter DATA_WIDTH = 32,
  parameter ADDR_WIDTH = 32
  )(
  input hclk,                           // ahb clk
  input hresetn,                        // ahb active-low reset
  
  // not needed haddr given
  input [ADDR_WIDTH - 1: 0] addr,       // ahb read/write data address
  //not needed hwdata given
  input [DATA_WIDTH - 1: 0] data_in,  // ahb input data
  // not needed 
  input enable,                         // ahb module enable
  // not needed hwrite given
  input wr,                             // ahb read/write flag
  input [DATA_WIDTH - 1: 0] hrdata,     // ahb read data
  input hready,                         // ahb slave are ready
  input hresp,                          // ahb slave response
  input [1:0] slave_sel,                // ahb slave select line input
  
  output reg [1:0] sel,                 // ahb slave select for decodrer
  output reg [ADDR_WIDTH - 1: 0] haddr, // ahb read/write data address for slave
  output reg [DATA_WIDTH - 1: 0] hwdata,// ahb write data
  output reg hwrite,                    // ahb read/write flag for slave
  output reg [2:0] hburst,              // ahb burst size for slave
  output reg [2:0] hsize,               // ahb transfer data width
  output reg [1:0] htrans,              // ahb transfer type
  output reg [3:0] hprot,               // ahb protection
  // not needed hrdata given
  output reg [DATA_WIDTH - 1: 0] dout   // ahb read data out
//  output reg hmastlock
);

  // master transfer states
  localparam IDLE = 2'b00;               // idle state, no transfer
//  localparam BUSY = 2'b01;               // master is busy in transfer
//  localparam SEQU = 2'b10;               // transfer sequential 
//  localparam NSEQ = 2'b11;               // transfer non-sequential
  localparam SETUP = 2'b01;                 // setup state
  localparam WRITE = 2'b10;                 // write state
  localparam READ = 2'b11;                 // read state

  // type of data burst
  localparam BST_SING = 3'b000;        // single burst
  localparam BST_INCR = 3'b001;        // incremental burst
  localparam BST_WRAP4 = 3'b010;      // 4-byte increment 
  localparam BST_INCR4 = 3'b011;      // 4-byte wrap increment
  localparam BST_WRAP8 = 3'b100;      // 8-byte increment
  localparam BST_INCR8 = 3'b101;      // 8-byte wrap increment
  localparam BST_WRAP16 = 3'b110;     // 16-byte increment
  localparam BST_INCR16 = 3'b111;     // 16-byte wrap increment
  
  // transfer byte size
  localparam SIZE_1 = 3'b000;            // transfer 1-byte
  localparam SIZE_2 = 3'b001;            // transfer 2-byte (half-word)
  localparam SIZE_4 = 3'b010;            // transfer 4-byte (word)
  // not implementing 
//  localparam SIZE_8 = 3'b011;            // transfer 8-byte (double-word)
//  localparam SIZE_16 = 3'b000;           // transfer 16-byte (4-word)
//  localparam SIZE_32 = 3'b001;           // transfer 32-byte (8-word)
//  localparam SIZE_64 = 3'b010;           // transfer 64-byte (16-word)
//  localparam SIZE_128 = 3'b011;          // transfer 128-byte (32-word)
  
  // to represent present-state and next-state
  reg [1:0] present_state, next_state;
  
  
  //present state logic
  always @ (posedge hclk) begin
    if(!hresetn) begin
      present_state <= IDLE;
    end
    else begin 
      present_state <= next_state;
    end
  end

  // next state logic
  always @ (*)
  begin
    case (present_state)
      IDLE :begin
              sel <= 2'b00;
              haddr <= 32'h0000_0000;
              hwdata <= 32'h0000_0000;
              hwrite <= 1'b0;
              hsize <= 3'b000;
              hburst <= 3'b00;
              htrans <= 2'b00;
              hprot <= 4'b0000;
              dout <= 32'h0000_0000;
              if(enable) begin
                next_state <= SETUP;
              end
              else begin
                next_state <= IDLE;
              end
            end
      SETUP:begin
              sel <= slave_sel;
              haddr <= addr;
              hwdata <= data_in;
              hwrite <= wr;
              hsize <= 3'b010;
              hburst <= 3'b000;
              htrans <= 2'b10;
              dout <= 32'h0000_0000;
              if (wr) begin
                next_state <= WRITE;
              end
              else if (!wr) begin
                next_state <= READ;
              end
              else begin
                next_state <= IDLE;
              end
            end
      WRITE:begin
            if (!hready) begin
              sel <= slave_sel;
              haddr <= addr;
              hwdata <= data_in;
              hwrite <= wr;
              hsize <= 3'b010;
              hburst <= 3'b000;
              htrans <= 2'b01;                    // trans input needed
              dout <= 32'h0000_0000;
              if (wr && enable) begin             // if (wr && htrans)
                next_state <= WRITE;
              end
              else if (!wr && enable) begin       // else if (wr && htrans)
                next_state <= READ;
              end
              else begin
                next_state <= IDLE;
              end
            end
            else begin
              sel <= slave_sel;
              haddr <= haddr;
              hwdata <= hwdata;
              hwrite <= hwrite;
              hsize <= hsize;
              hburst <= hburst;
              htrans <= htrans;
              dout <= dout;
              next_state <= present_state;
            end
            end
      READ :begin
            if (!hready) begin
              sel <= slave_sel;
              haddr <= addr;
              hwdata <= hwdata;
              hwrite <= wr;
              hsize <= 3'b010;
              hburst <= 3'b010;
              htrans <= 2'b10;
              dout <= hrdata;
              if (wr && enable) begin 
                next_state <= WRITE;
              end
              else if (!wr && enable) begin
                next_state <= READ;
              end
              else begin
                next_state <= IDLE;
              end
            end
            else 
              sel <= slave_sel;
              haddr <= haddr;
              hwdata <= hwdata;
              hwrite <= hwrite;
              hsize <= hsize;
              hburst <= hburst;
              htrans <= htrans;
              dout <= dout;
              next_state <= present_state;
            end
      default :begin
              sel <= 2'b00;
              haddr <= 32'h0000_0000;
              hwdata <= 32'h0000_0000;
              hwrite <= 1'b0;
              hsize <= 3'b000;
              hburst <= 2'b00;
              htrans <= 2'b00;
              dout <= 32'h0000_0000;
              next_state <= IDLE;
               end
    endcase
  end
endmodule