module uart_rx(
    input wire clk,         // 50MHz ʱ��
    input wire rst_n,       // ��λ�ź�
    input wire rx,          // ������ (���ӵ�����)
    
    output reg [7:0] data_out, // ���յ���8λ���ݣ�׼������CPU
    output reg rx_done      // ������ɱ�־ (����CPU�����������ݣ�)
);

    parameter BAUD_CNT_MAX = 868;      // 115200�����ʣ�һ��868��ʱ��
    parameter BAUD_CNT_HALF = 434;     // ����434��ʱ�� (�������м�)
    
    reg [15:0] baud_cnt;
    reg [3:0]  bit_cnt;
    reg        rx_flag;     // ���ڽ��յ�״̬��־
    
    // Ϊ�˷�ֹ����̬��ץȡ�½��أ�������Ҫ���첽��rx�źŴ�����
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
    
    // ����һ����1����һ����0ʱ��˵��ץ�����½���(��ʼλ)
    wire rx_neg = (rx_d1 == 1'b1) && (rx_d0 == 1'b0);
    
    // ״̬�����߼�
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_flag <= 0;
            baud_cnt <= 0;
            bit_cnt <= 0;
            rx_done <= 0;
            data_out <= 8'b0;
        end else begin
            rx_done <= 0; // Ĭ����������ź� (ֻ�ڽ�����˲������һ��)
            
            // ����1��ץ����ʼλ����ʼ����
            if (rx_neg && rx_flag == 0) begin
                rx_flag <= 1;
                baud_cnt <= 0;
                bit_cnt <= 0;
            end
            
            // ����2�����ڽ��չ�����
            if (rx_flag) begin
                if (baud_cnt < BAUD_CNT_MAX - 1) begin
                    baud_cnt <= baud_cnt + 1;
                end else begin
                    baud_cnt <= 0;
                    bit_cnt <= bit_cnt + 1;
                    
                    // ���ս�������
                    if (bit_cnt == 9) begin 
                        rx_flag <= 0;    // ��������
                        rx_done <= 1'b1; // ����CPU���ݺ���
                        bit_cnt <= 0;
                    end
                end
                
                // ����3����ÿ��bit�����м䣨���Ĵ�����������
                if (baud_cnt == BAUD_CNT_HALF) begin
                    case (bit_cnt)
                        // bit_cnt==0����ʼλ��������
                        1: data_out[0] <= rx_d1; // ���յ�0λ
                        2: data_out[1] <= rx_d1; // ���յ�1λ
                        3: data_out[2] <= rx_d1; 
                        4: data_out[3] <= rx_d1; 
                        5: data_out[4] <= rx_d1; 
                        6: data_out[5] <= rx_d1; 
                        7: data_out[6] <= rx_d1; 
                        8: data_out[7] <= rx_d1; // ���յ�7λ
                        // bit_cnt==9��ֹͣλ��������
                    endcase
                end
            end
        end
    end
endmodule