`timescale 1ns / 1ps

module uart_rx #(
    parameter BAUD_CNT_MAX  = 434,
    parameter BAUD_CNT_HALF = BAUD_CNT_MAX / 2
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx,
    output reg  [7:0] data_out,
    output reg        rx_done
);

    parameter BAUD_CNT_MAX = 868;      // 115200波特率，一拍434个时钟
    parameter BAUD_CNT_HALF = 434;     // 半拍434个时钟 (踩在正中间)
    
    reg [15:0] baud_cnt;
    reg [3:0]  bit_cnt;
    reg        rx_flag;
    reg        rx_d0, rx_d1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_d0 <= 1'b1;
            rx_d1 <= 1'b1;
        end else begin
            rx_d0 <= rx;
            rx_d1 <= rx_d0;
        end
    end

    wire rx_neg = (rx_d1 == 1'b1) && (rx_d0 == 1'b0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_flag  <= 1'b0;
            baud_cnt <= 16'd0;
            bit_cnt  <= 4'd0;
            rx_done  <= 1'b0;
            data_out <= 8'd0;
        end else begin
            rx_done <= 1'b0;

            if (rx_neg && (rx_flag == 1'b0)) begin
                rx_flag  <= 1'b1;
                baud_cnt <= 16'd0;
                bit_cnt  <= 4'd0;
            end else if (rx_flag) begin
                if (baud_cnt < BAUD_CNT_MAX - 1) begin
                    baud_cnt <= baud_cnt + 16'd1;
                end else begin
                    baud_cnt <= 16'd0;
                    bit_cnt  <= bit_cnt + 4'd1;
                    if (bit_cnt == 4'd9) begin
                        rx_flag <= 1'b0;
                        bit_cnt <= 4'd0;
                        rx_done <= 1'b1;
                    end
                end

                if (baud_cnt == BAUD_CNT_HALF) begin
                    case (bit_cnt)
                        4'd1: data_out[0] <= rx_d1;
                        4'd2: data_out[1] <= rx_d1;
                        4'd3: data_out[2] <= rx_d1;
                        4'd4: data_out[3] <= rx_d1;
                        4'd5: data_out[4] <= rx_d1;
                        4'd6: data_out[5] <= rx_d1;
                        4'd7: data_out[6] <= rx_d1;
                        4'd8: data_out[7] <= rx_d1;
                        default: ;
                    endcase
                end
            end
        end
    end
endmodule
