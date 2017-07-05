module trans(clk,
             rst,
             TxD_start,
             TxD_data,
             TxD,
             TxD_busy
             );
input      clk,
           rst,
           TxD_start;
input[7:0] TxD_data;   // �����͵�����
output     TxD,        // ����˿ڷ��͵Ĵ�������
           TxD_busy;   

reg        TxD;
reg [7:0]  TxD_dataReg;   // �Ĵ�������ģʽ����Ϊ�ڴ��ڷ��͹���������˲�����һֱ������Ч��ƽ
reg [3:0]  state;
parameter  ClkFrequency = 25000000;  // ʱ��Ƶ�ʣ�25 MHz
parameter  Baud = 115200;            // ���ڲ����ʣ�115200 



// ���Ͷ�״̬
wire   TxD_ready = (state==0);  // ��state = 0ʱ������׼������״̬��TxD_ready = 1
assign TxD_busy = ~TxD_ready;   // ����״̬ʱTxD_busy = 0

// �Ѵ��������ݷ��뻺��Ĵ��� TxD_dataReg
always @(posedge clk or negedge rst)
   if(~rst)
      TxD_dataReg <= 8'b00000000;
 else if(TxD_ready & TxD_start)
  TxD_dataReg <= TxD_data;   
  
// ����״̬��
always @(posedge clk or negedge rst)
 if(~rst)
      begin
         state <= 4'b0000;   // ��λʱ��״̬Ϊ0000�����Ͷ�һֱ��1��ƽ
         TxD <= 1'b1;
      end
 else 
 case(state)
  4'b0000: if(TxD_start) begin
                      state <= 4'b0100; // ���ܵ������źţ����뷢��״̬
                         end
  4'b0100:  begin
                            state <= 4'b1000;  // ���Ϳ�ʼλ - 0��ƽ
                  TxD <= 1'b0;
                            end
  4'b1000:  begin
                            state <= 4'b1001;  // bit 0
                  TxD <= TxD_dataReg[0];
                            end
  4'b1001: begin
                            state <= 4'b1010;  // bit 1
                  TxD <= TxD_dataReg[1];
                        end
  4'b1010:  begin
                            state <= 4'b1011;  // bit 2
                  TxD <= TxD_dataReg[2];
                            end
  4'b1011:  begin
                            state <= 4'b1100;  // bit 3
                  TxD <= TxD_dataReg[3];
                            end
  4'b1100: begin
                            state <= 4'b1101;  // bit 4
                  TxD <= TxD_dataReg[4];
                            end
  4'b1101: begin
                            state <= 4'b1110;  // bit 5
                  TxD <= TxD_dataReg[5];
                            end
  4'b1110:  begin
                            state <= 4'b1111;  // bit 6
                  TxD <= TxD_dataReg[6];
                            end
  4'b1111:  begin
                            state <= 4'b0010;  // bit 7
                  TxD <= TxD_dataReg[7];
                            end
  4'b0010:begin
                            state <= 4'b0011;  // stop1
                  TxD <= 1'b1;
                            end

  4'b0011: begin
                            state <= 4'b0000;  // stop2
                        TxD <= 1'b1;
                            end
  default:  begin
                            state <= 4'b0000;
                TxD <= 1'b1;
              end
 endcase
endmodule
