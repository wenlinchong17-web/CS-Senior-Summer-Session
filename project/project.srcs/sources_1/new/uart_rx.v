module uart_rx(
    input wire clk,         // 50MHz 时钟
    input wire rst_n,       // 复位信号
    input wire rx,          // 接收线 (连接到电脑)
    
    output reg [7:0] data_out, // 接收到的8位数据，准备交给CPU
    output reg rx_done      // 接收完成标志 (告诉CPU：快来拿数据！)
);

    parameter BAUD_CNT_MAX = 434;      // 115200波特率，一拍434个时钟
    parameter BAUD_CNT_HALF = 217;     // 半拍217个时钟 (踩在正中间)
    
    reg [15:0] baud_cnt;
    reg [3:0]  bit_cnt;
    reg        rx_flag;     // 正在接收的状态标志
    
    // 为了防止亚稳态并抓取下降沿，我们需要把异步的rx信号打两拍
    reg rx_d0, rx_d1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_d0 <= 1'b1;
            rx_d1 <= 1'b1;
        end else begin
            rx_d0 <= rx;
            rx_d1 <= rx_d0;
        end
    end
    
    // 当上一拍是1，这一拍是0时，说明抓到了下降沿(起始位)
    wire rx_neg = (rx_d1 == 1'b1) && (rx_d0 == 1'b0);
    
    // 状态控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_flag <= 0;
            baud_cnt <= 0;
            bit_cnt <= 0;
            rx_done <= 0;
            data_out <= 8'b0;
        end else begin
            rx_done <= 0; // 默认拉低完成信号 (只在接收完瞬间拉高一拍)
            
            // 步骤1：抓到起始位，开始接收
            if (rx_neg && rx_flag == 0) begin
                rx_flag <= 1;
                baud_cnt <= 0;
                bit_cnt <= 0;
            end
            
            // 步骤2：正在接收过程中
            if (rx_flag) begin
                if (baud_cnt < BAUD_CNT_MAX - 1) begin
                    baud_cnt <= baud_cnt + 1;
                end else begin
                    baud_cnt <= 0;
                    bit_cnt <= bit_cnt + 1;
                    
                    // 接收结束条件
                    if (bit_cnt == 9) begin 
                        rx_flag <= 0;    // 结束接收
                        rx_done <= 1'b1; // 告诉CPU数据好了
                        bit_cnt <= 0;
                    end
                end
                
                // 步骤3：在每个bit的正中间（半拍处）采样数据
                if (baud_cnt == BAUD_CNT_HALF) begin
                    case (bit_cnt)
                        // bit_cnt==0是起始位，不管它
                        1: data_out[0] <= rx_d1; // 接收第0位
                        2: data_out[1] <= rx_d1; // 接收第1位
                        3: data_out[2] <= rx_d1; 
                        4: data_out[3] <= rx_d1; 
                        5: data_out[4] <= rx_d1; 
                        6: data_out[5] <= rx_d1; 
                        7: data_out[6] <= rx_d1; 
                        8: data_out[7] <= rx_d1; // 接收第7位
                        // bit_cnt==9是停止位，不管它
                    endcase
                end
            end
        end
    end
endmodule