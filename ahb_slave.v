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
//  input [3 : 0] hprot,                  // ahb protection
  input hready,                         // ahb master ready

  // mastlock needed in multi master
//  input mastlock,                       // ahb master-lock
  
  output reg hreadyout,                     // ahb slave readyout
  output reg [DATA_WIDTH - 1 : 0] hrdata,   // ahb read data bus
  output reg hresp                          // ahb slave response
);


  // master transfer states
  localparam IDEAL = 2'b00;              // ideal state, no transfer
  localparam BUSY = 2'b01;               // master is busy, no transfer
  localparam SEQU = 2'b10;               // transfer sequential 
  localparam NSEQ = 2'b11;               // transfer non-sequential

  // type of data burst
  localparam BST_SING = 3'b000;          // single burst
  localparam BST_INCR = 3'b001;          // incremental burst
  localparam BST_WRAP4 = 3'b010;         // 4-byte increment 
  localparam BST_INCR4 = 3'b011;         // 4-byte wrap increment
  localparam BST_WRAP8 = 3'b100;         // 8-byte increment
  localparam BST_INCR8 = 3'b101;         // 8-byte wrap increment
  localparam BST_WRAP16 = 3'b110;        // 16-byte increment
  localparam BST_INCR16 = 3'b111;        // 16-byte wrap increment
  
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
  
  // byte addressable memory
  reg [7: 0] data_mem [0 : MEM_DEPTH - 1]; 
  
  // to represent present-state and next-state
  reg [1:0] current_state, next_state;
  reg [ADDR_WIDTH - 1 : 0] current_addr, next_addr;
  reg [4:0] burst_count, next_burst_count, total_count;
  reg [2:0] current_size, next_size;            // current size of data transfer
  reg [2:0] current_burst, next_burst;
  reg current_ready, next_ready;
  reg current_write, next_write;
  
  // currrent state logic
  always @ (posedge hclk) begin
    if (!hresetn) begin
      current_state <= IDEAL;
      current_size <= 3'b000;
      current_burst <= 3'b000;
      current_addr <= 32'h0000_0000;
    end
    else begin
      current_state <= next_state;
      current_size <= next_size;
      current_burst <= next_burst;
      current_addr <= next_addr;
      current_ready <= next_ready;
      current_write <= next_write;
    end
  end
  
  // next state logic
  always @(*) begin
    if(!hresetn) begin
      next_state  = IDEAL;
      next_addr   = 0;
      next_size   = 0;
      next_burst  = 0;
      next_ready  = 0;
      next_write  = 0;
    end
    
    else begin
      hreadyout <= 1'b1;
      hresp <= 1'b1;
      case(current_state)
        IDEAL : begin 
                  
                  next_state <= htrans;
//                  next_addr <= 32'h0000_0000;
                  next_burst <= 3'b000;
                  next_size <= 3'b000;
//                  burst_count <= 5'b00000;
                  next_ready <= 1'b0;
                  next_write <= 1'b0;
                end
        BUSY  : begin
                  next_state <= htrans;
//                  next_addr <= current_addr;
                  next_burst <= current_burst;
                  next_size <= current_size;
//                  burst_count <= burst_count;
                  next_write <= current_write;
                  next_ready <= current_ready;
                end
        SEQU  : begin 
                  if(burst_count != total_count) begin
                    next_state <= current_state;
//                    next_addr <= current_addr + 
//                                (current_size * (total_count - burst_count));
                    next_burst <= current_burst;
                    next_size <= current_size;
//                    burst_count <= burst_count - 1;
                    next_write <= current_write;
                    next_ready <= current_ready;
                  end
                  else begin
                    next_state <= htrans;
//                    next_addr <= haddr;
                    next_burst <= hburst;
                    next_size <= hsize;
//                    burst_count <= hburst - 1;
                    next_write <= hwrite;
                    next_ready <= hready;
                  end
                end
        NSEQ  : begin
                  next_state <= htrans;
//                  next_addr <= haddr;
//                  burst_count <= hburst - 1;
                  next_size <= hsize;
                  next_burst <= hburst;
                  next_write <= hwrite;
                  next_ready <= hready;
                end
        default:begin
                  next_state <= IDEAL;
//                  next_addr <= 32'h0000_0000;
                  next_size <= 3'b000;
                  next_burst <= 3'b000;
//                  burst_count <= 5'b00000;
                  next_write <= 1'b0;
                  next_ready <= 1'b0;
                end
      endcase
  end
  end





  always@(*) begin
  case(current_state)
  IDEAL : begin
            next_burst_count <= 5'b0_0000;
          end 
  NSEQ  : begin
    case(current_burst)
      BST_SING    : begin
                      next_burst_count <= 5'b0_0000;
                      total_count <= 5'b0_0000;
                    end
      BST_INCR    : begin
                      next_burst_count <= 5'b0_0001;
                      total_count <= 5'b0_0000;
                    end
      BST_WRAP4   : begin
                      next_burst_count <= 5'b1_1110;
                      total_count <= 5'b0_0011;
                    end
      BST_INCR4   : begin
                      next_burst_count <= 5'b0_0100;
                      total_count <= 5'b0_0011;
                    end
      BST_WRAP8   : begin
                      next_burst_count <= 5'b1_1100;
                      total_count <= 5'b0_0111;
                    end
      BST_INCR8   : begin
                      next_burst_count <= 5'b0_1000;
                      total_count <= 5'b0_0111;
                    end
      BST_WRAP16  : begin
                      next_burst_count <= 5'b1_1000;
                      total_count <= 5'b0_1111;
                    end
      BST_INCR16  : begin
                      next_burst_count <= 5'b1_0000;
                      total_count <= 5'b0_1111;
                    end
      default     : begin
                      next_burst_count <= 5'b0_0000;
                      total_count <= 5'b0_0000;
                    end
                  endcase
    end
    BUSY         : begin
                next_burst_count <= next_burst_count;
                   end
    SEQU        : begin
                    if(current_ready && (burst_count != 0)) begin
                      if((current_burst == BST_INCR4) || (current_burst == BST_INCR8) || (current_burst == BST_INCR16))
                      next_burst_count <= burst_count - 1;
                      next_addr <= current_addr + (burst_count * current_size);
                    end
                    else if ((current_burst == BST_WRAP4) || (current_burst == BST_WRAP8) || (current_burst == BST_WRAP16)) begin
                    if((burst_count/2) < (total/2 + 2))begin
                      next_burst_count <= burst_count  - (total_count) - 2;
                      end 
                      else if()
                    end
                  end
    endcase
  end

  // read and write logic
  always @(posedge hclk) begin
    if (!hready) begin
      hrdata <= 32'h0000_0000;
    end
    else
    // write logic
    if(current_ready && ((current_state != BUSY) || (current_state != IDEAL))) begin
     case(current_write)
      1'b1:case(current_size)
            SIZE_1 :  begin
                        data_mem[current_addr] <= hwdata[7:0];
                      end
            SIZE_2 :  begin
                        {data_mem[current_addr + 1],
                         data_mem[current_addr]} <= hwdata[15:0];
                      end
            SIZE_4 :  begin 
                        {data_mem[current_addr + 3], 
                         data_mem[current_addr + 2],
                         data_mem[current_addr + 1],
                         data_mem[current_addr]} <= hwdata[31:0];
                      end
            default:  ;
           endcase
    
    // read logic
      1'b0: case(current_size)
             SIZE_1 : begin
                        hrdata[7:0] <= data_mem[current_addr];
                      end
             SIZE_2 : begin
                        hrdata[15:0] <= {data_mem[current_addr + 1],
                                         data_mem[current_addr]};
                      end
             SIZE_4 : begin
                        hrdata[31:0] <= {data_mem[current_addr + 3],
                                         data_mem[current_addr + 2],
                                         data_mem[current_addr + 1],
                                         data_mem[current_addr]};
                      end
             default: begin
                        hrdata <= 32'h0000_0000;
                      end
            endcase
      endcase
    end
  end

endmodule