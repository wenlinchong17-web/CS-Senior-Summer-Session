`timescale 1ns / 1ps

// 8N1 TX. One bit lasts BAUD_CNT_MAX clocks.
// 50 MHz / 115200 ~= 434; 100 MHz / 115200 ~= 868.
module uart_tx #(
    parameter BAUD_CNT_MAX = 434
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tx_en,
    input  wire [7:0] data_in,
    output reg        tx,
    output reg        tx_busy
);

    // 波特率计数器 (50MHz / 115200波特率 ≈ 434)
    parameter BAUD_CNT_MAX = 868; 
    
    reg [15:0] baud_cnt;
    reg [3:0]  bit_cnt;
    reg [7:0]  tx_data_reg;
    reg        state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= 1'b0;
            tx          <= 1'b1;
            tx_busy     <= 1'b0;
            baud_cnt    <= 16'd0;
            bit_cnt     <= 4'd0;
            tx_data_reg <= 8'd0;
        end else begin
            case (state)
                1'b0: begin
                    if (tx_en) begin
                        state       <= 1'b1;
                        tx_data_reg <= data_in;
                        tx_busy     <= 1'b1;
                        tx          <= 1'b0;
                        baud_cnt    <= 16'd0;
                        bit_cnt     <= 4'd0;
                    end
                end
                1'b1: begin
                    if (baud_cnt < BAUD_CNT_MAX - 1) begin
                        baud_cnt <= baud_cnt + 16'd1;
                    end else begin
                        baud_cnt <= 16'd0;
                        bit_cnt  <= bit_cnt + 4'd1;
                        if (bit_cnt < 4'd8)
                            tx <= tx_data_reg[bit_cnt];
                        else if (bit_cnt == 4'd8)
                            tx <= 1'b1;
                        else begin
                            state   <= 1'b0;
                            tx_busy <= 1'b0;
                            bit_cnt <= 4'd0;
                        end
                    end
                end
            endcase
        end
    end
endmodule
