module uart_tx(
    input wire clk,         // ϵͳʱ�� (���辫������50MHz)
    input wire rst_n,       // ��λ�ź� (�͵�ƽ��Ч)
    input wire tx_en,       // ����ʹ�� (CPU��������Է�������)
    input wire [7:0] data_in, // CPU�������8λ���� (������ĸ 'A')
    
    output reg tx,          // ������Ǹ��������Եķ�����
    output reg tx_busy      // æ�ź� (����CPU�������ڷ������������ݹ���)
);

    // �����ʼ����� (50MHz / 115200������ �� 868)
    parameter BAUD_CNT_MAX = 868; 
    
    reg [15:0] baud_cnt;
    reg [3:0]  bit_cnt;//���������ѷ��͵�λ��
    reg [7:0]  tx_data_reg;
    reg        state; // 0: ����״̬, 1: ����״̬

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 0;
            tx <= 1'b1; // ���ڿ���ʱ���Ǹߵ�ƽ
            tx_busy <= 0;
            baud_cnt <= 0;
            bit_cnt <= 0;
        end else begin
            case (state)
                0: begin // ����״̬
                    if (tx_en) begin
                        state <= 1;
                        tx_data_reg <= data_in; // ��CPU��������������
                        tx_busy <= 1;
                        tx <= 1'b0; // ������ʼλ (����)
                    end
                end
                1: begin // ����״̬
                    if (baud_cnt < BAUD_CNT_MAX - 1) begin
                        baud_cnt <= baud_cnt + 1;
                    end else begin
                        baud_cnt <= 0;
                        bit_cnt <= bit_cnt + 1;
                        
                        if (bit_cnt < 8) begin
                            // ���η���8������λ (�ӵ�λ��ʼ��)
                            tx <= tx_data_reg[bit_cnt]; 
                        end else if (bit_cnt == 8) begin
                            // ����ֹͣλ (����)
                            tx <= 1'b1; 
                        end else if (bit_cnt == 9) begin
                            // ���ͽ������ص�����״̬
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