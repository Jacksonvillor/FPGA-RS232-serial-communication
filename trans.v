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
input[7:0] TxD_data;   // 待发送的数据
output     TxD,        // 输出端口发送的串口数据
           TxD_busy;   

reg        TxD;
reg [7:0]  TxD_dataReg;   // 寄存器发送模式，因为在串口发送过程中输入端不可能一直保持有效电平
reg [3:0]  state;
parameter  ClkFrequency = 25000000;  // 时钟频率－25 MHz
parameter  Baud = 115200;            // 串口波特率－115200 



// 发送端状态
wire   TxD_ready = (state==0);  // 当state = 0时，处于准备空闲状态，TxD_ready = 1
assign TxD_busy = ~TxD_ready;   // 空闲状态时TxD_busy = 0

// 把待发送数据放入缓存寄存器 TxD_dataReg
always @(posedge clk or negedge rst)
   if(~rst)
      TxD_dataReg <= 8'b00000000;
 else if(TxD_ready & TxD_start)
  TxD_dataReg <= TxD_data;   
  
// 发送状态机
always @(posedge clk or negedge rst)
 if(~rst)
      begin
         state <= 4'b0000;   // 复位时，状态为0000，发送端一直发1电平
         TxD <= 1'b1;
      end
 else 
 case(state)
  4'b0000: if(TxD_start) begin
                      state <= 4'b0100; // 接受到发送信号，进入发送状态
                         end
  4'b0100:  begin
                            state <= 4'b1000;  // 发送开始位 - 0电平
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
