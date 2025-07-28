`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////// 
// Engineer: Varun Pateliya
// 
// Create Date: 
// Design Name: ahb
// Module Name: ahb_slave
// Project Name: ahb_protocol
// Tool Versions: Vivado 2018.2
// Description: slave module of APB protocol
// Revision: Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module apb_slave #(
  parameter DATA_WIDTH = 32,
  parameter ADDR_WIDTH = 32,
  parameter MEM_DEPTH = 65536 
)(
  // input signals
  input hclk,                           // ahb clock
  input hresetn,                        // ahb reset
  input [DATA_WIDTH - 1 : 0] hwdata,     // ahb write data bus
  input [ADDR_WIDTH - 1 : 0] haddr,     // ahb address bus
  input hwrite,                         // ahb write/read indicate
  input [2 : 0] hsize,                  // ahb transfer data width
  input [2 : 0] hburst,                 // ahb burst size
  input [1 : 0] htrans,                 // ahb transfer type
  input [3 : 0] hprot,                  // ahb protection
  input hready,                         // ahb master ready
//  input mastlock,                       // ahb master-lock
  
  output reg hreadyout,                     // ahb slave readyout
  output reg [DATA_WIDTH - 1 : 0] hrdata,   // ahb read data bus
  output reg hresp                          // ahb slave response
);


  // master transfer states
  localparam IDLE = 2'b00;               // idle state, no transfer
  localparam IDEAL = 2'b01;              // ideal state
  localparam BUSY = 2'b01;               // master is busy in transfer
  localparam SEQU = 2'b10;               // transfer sequential 
  localparam NSEQ = 2'b11;               // transfer non-sequential
  localparam S1 = 2'b01;                 // setup state
  localparam WRITE = 2'b10;                 // write state
  localparam READ = 2'b11;                 // read state

  // type of data burst
  localparam BST_SING = 3'b000;          // single burst
  localparam BST_INCR = 3'b001;          // incremental burst
  localparam BST_WRAP4 = 3'b010;        // 4-byte increment 
  localparam BST_INCR4 = 3'b011;        // 4-byte wrap increment
  localparam BST_WRAP8 = 3'b100;        // 8-byte increment
  localparam BST_INCR8 = 3'b101;        // 8-byte wrap increment
  localparam BST_WRAP16 = 3'b110;       // 16-byte increment
  localparam BST_INCR16 = 3'b111;       // 16-byte wrap increment
  
  // transfer byte size
  localparam SIZE_1 = 3'b000;            // transfer 1-byte
  localparam SIZE_2 = 3'b001;            // transfer 2-byte (half-word)
  localparam SIZE_4 = 3'b010;            // transfer 4-byte (word)
  // not implementing 
//  localparam SIZE_8 = 3'b011;            // transfer 8-byte (2-word)
//  localparam SIZE_16 = 3'b000;           // transfer 16-byte (4-word)
//  localparam SIZE_32 = 3'b001;           // transfer 32-byte (8-word)
//  localparam SIZE_64 = 3'b010;           // transfer 64-byte (16-word)
//  localparam SIZE_128 = 3'b011;          // transfer 128-byte (32-word)
  
  // busrt type flag
  reg b_sing;
  reg b_incr;
  reg b_wrap4;
  reg b_incr4;
  reg b_wrap8;
  reg b_incr8;
  reg b_wrap16;
  reg b_incr16;
  
  // data width flag
  reg size1;
  reg size2;
  reg size4;
//  reg size8;
//  reg size16;
//  reg size32;
//  reg size64;
//  reg size128;
  
  reg [DATA_WIDTH - 1: 0] data_mem [0 : MEM_DEPTH - 1]; 
  
  // to represent present-state and next-state
  reg [1:0] present_state, next_state;
  reg [ADDR_WIDTH - 1 : 0] current_addr, next_addr;
  reg count_burst;
  
  always @ (posedge hclk) begin
    if (!hresetn) begin
      present_state <= IDEAL;
      next_state <= IDEAL;
    end
    else begin
      present_state <= next_state;
      next_state <= htrans;
    end
  end
  
  always @ (posedge hclk) begin
    hresp = 1'b0;
    hreadyout = 1'b1;
    case(present_state)
        IDEAL : begin
                  hrdata <= 32'h0000_0000;
                end
        BUSY  : begin
                   
                end
        SEQU  : begin
                   if(hwrite)
                     casez({size1, size2, size4})
                       3'b1?? : begin
                                  burst_size = 0;
                                  
                                  data_mem[current_addr] = hwdata[7:0];
                                  current_addr <= next_addr;
                                  case({b_sing, b_incr, b_wrap4, b_incr4, b_wrap8, b_incr8, b_wrap16, b_incr16})
                                    8'b1???_???? : begin
                                                     
                                                   end
                                    8'b?1??_???? : begin
                                                     next_addr <= current_addr + 1'b1;
                                                   end
                                    8'b??1?_???? : begin
//                                                     new_addr = haddr + 2'b10;
                                                   end
                                    8'b???1_???? : begin
                                                     next_addr <= current_addr + 3'b100;
                                                   end
                                    8'b????_1??? : begin
//                                                     new_addr = haddr + 4'b1000;
                                                   end
                                    8'b????_?1?? : begin
                                                     next_addr <= current_addr + 4'b1000;
                                                   end
                                    8'b????_??1? : begin
                                                     
                                                   end
                                    8'b????_???1 : begin
                                                     next_addr <= current_addr + 5'b1_0000;
                                                   end
                                    default      : begin
                                                   
                                                   end
                                  endcase
                                end
                       3'b?1? : begin
                                  {data_mem[new_addr + 1'b1], data_mem[new_addr]} = hwdata[15:0];
                                  case()
                     endcase
                   else if (!hwrite) begin
                   
                   end
                end
        NSEQ  : begin
                    
                end
       default:begin
                      
               end
     endcase
   end
   
   
   
   
   
   always @ (*) begin
                case(hsize)
                  SIZE_1 :  begin
                              {size1, size2, size4} = 3'b000;
                            end
                  SIZE_2 :  begin
                              {size1, size2, size4} = 3'b001;
                            end
                  SIZE_4 :  begin
                              {size1, size2, size4} = 3'b010;
                            end
                  default:  begin
                              {size1, size2, size4} = 3'b000;
                            end
                endcase
                case(hburst)
                  BST_SING    : begin
                                  {b_sing, b_incr, b_wrap4, b_incr4,
                                   b_wrap8, b_incr8, b_wrap16, b_incr16} = 8'b1000_0000;
                                end
                  BST_INCR    : begin
                                  {b_sing, b_incr, b_wrap4, b_incr4,
                                   b_wrap8, b_incr8, b_wrap16, b_incr16} = 8'b0100_0000;
                                end
                  BST_WRAP4  : begin
                                  {b_sing, b_incr, b_wrap4, b_incr4,
                                   b_wrap8, b_incr8, b_wrap16, b_incr16} = 8'b0010_0000;
                                end
                  BST_INCR4  : begin
                                  {b_sing, b_incr, b_wrap4, b_incr4,
                                   b_wrap8, b_incr8, b_wrap16, b_incr16} = 8'b0001_0000;
                                end
                  BST_WRAP8  : begin
                                  {b_sing, b_incr, b_wrap4, b_incr4,
                                   b_wrap8, b_incr8, b_wrap16, b_incr16} = 8'b0000_1000;
                                end
                  BST_INCR8  : begin
                                  {b_sing, b_incr, b_wrap4, b_incr4,
                                   b_wrap8, b_incr8, b_wrap16, b_incr16} = 8'b0000_0100;
                                end
                  BST_WRAP16 : begin
                                  {b_sing, b_incr, b_wrap4, b_incr4,
                                   b_wrap8, b_incr8, b_wrap16, b_incr16} = 8'b0000_0010;
                                end
                  BST_INCR16 : begin
                                  {b_sing, b_incr, b_wrap4, b_incr4,
                                   b_wrap8, b_incr8, b_wrap16, b_incr16} = 8'b0000_0001;
                                end
                  default     : begin
                                 {b_sing, b_incr, b_wrap4, b_incr4,
                                  b_wrap8, b_incr8, b_wrap16, b_incr16} = 8'b1000_0000;
                                end
                endcase
                
         

  end  

endmodule