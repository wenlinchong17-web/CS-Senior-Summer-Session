module uart_tx(
    input wire clk,         // 系统时钟 (假设精工板是50MHz)
    input wire rst_n,       // 复位信号 (低电平有效)
    input wire tx_en,       // 发送使能 (CPU告诉你可以发数据了)
    input wire [7:0] data_in, // CPU传给你的8位数据 (比如字母 'A')
    
    output reg tx,          // 这就是那根连到电脑的发送线
    output reg tx_busy      // 忙信号 (告诉CPU：我正在发，别塞新数据过来)
);

    // 波特率计数器 (50MHz / 115200波特率 ≈ 434)
    parameter BAUD_CNT_MAX = 868; 
    
    reg [15:0] baud_cnt;
    reg [3:0]  bit_cnt;//用来计数已发送的位数
    reg [7:0]  tx_data_reg;
    reg        state; // 0: 空闲状态, 1: 发送状态

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 0;
            tx <= 1'b1; // 串口空闲时线是高电平
            tx_busy <= 0;
            baud_cnt <= 0;
            bit_cnt <= 0;
        end else begin
            case (state)
                0: begin // 空闲状态
                    if (tx_en) begin
                        state <= 1;
                        tx_data_reg <= data_in; // 把CPU的数据锁存下来
                        tx_busy <= 1;
                        tx <= 1'b0; // 发送起始位 (拉低)
                    end
                end
                1: begin // 发送状态
                    if (baud_cnt < BAUD_CNT_MAX - 1) begin
                        baud_cnt <= baud_cnt + 1;
                    end else begin
                        baud_cnt <= 0;
                        bit_cnt <= bit_cnt + 1;
                        
                        if (bit_cnt < 8) begin
                            // 依次发送8个数据位 (从低位开始发)
                            tx <= tx_data_reg[bit_cnt]; 
                        end else if (bit_cnt == 8) begin
                            // 发送停止位 (拉高)
                            tx <= 1'b1; 
                        end else if (bit_cnt == 9) begin
                            // 发送结束，回到空闲状态
                            state <= 0;
                            tx_busy <= 0;
                            bit_cnt <= 0;
                        end
                    end
                end
            endcase
        end
    end
endmodule