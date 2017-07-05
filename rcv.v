module rcv(clk,
           rst,
           RxD,
           RxD_data,
           RxD_data_ready,
           );
input       clk,
            rst,
            RxD;
output[7:0] RxD_data;        // 接收数据寄存器        
output      RxD_data_ready;  // 接收完8位数据，RxD_data 值有效时，RxD_data_ready 输出读信号


parameter  ClkFrequency = 25000000;  // 时钟频率－25MHz
parameter  Baud = 115200;            // 波特率－115200

reg[2:0]  bit_spacing;
reg       RxD_delay;
reg      RxD_start;
reg[3:0]  state;
reg[7:0]  RxD_data;
reg       RxD_data_ready;

// 波特率产生，使用8倍过采样
parameter Baud8 = Baud*8;
parameter Baud8GeneratorAccWidth = 16;
wire    [Baud8GeneratorAccWidth:0] Baud8GeneratorInc = ((Baud8<<(Baud8GeneratorAccWidth-7))+(ClkFrequency>>8))/(ClkFrequency>>7);
reg     [Baud8GeneratorAccWidth:0] Baud8GeneratorAcc;

always @(posedge clk or negedge rst)
   if(~rst)
      Baud8GeneratorAcc <= 0;
   else  
    Baud8GeneratorAcc <= Baud8GeneratorAcc[Baud8GeneratorAccWidth-1:0] + Baud8GeneratorInc;

// Baud8Tick 为波特率的8倍 － 115200*8 = 921600
//wire  Baud8Tick = Baud8GeneratorAcc[Baud8GeneratorAccWidth]; 
wire  Baud8Tick = 1; 

// next_bit 为波特率 － 115200
always @( negedge rst)
 if(~rst||(state==0))
      bit_spacing <= 0;
 else if(Baud8Tick)
    bit_spacing <= bit_spacing + 1;
wire next_bit = (bit_spacing==7);

// 检测到 TxD 有下跳沿时，RxD_start 置1，准备接收数据
always@(posedge clk)
 begin
  RxD_delay <= RxD;
    RxD_start <= (Baud8Tick &(~ RxD_delay) & (~RxD));
 end 

// 状态机接收数据
always@(posedge clk or negedge rst)
 if(~rst)
    state <= 4'b0000;
 else if(Baud8Tick)
    case(state)
     4'b0000: if(RxD_start) state <= 4'b1000;  // 检测到下跳沿
     4'b1000: if(next_bit)  state <= 4'b1001;  // bit 0
     4'b1001: if(next_bit)  state <= 4'b1010;  // bit 1
     4'b1010: if(next_bit)  state <= 4'b1011;  // bit 2
     4'b1011: if(next_bit)  state <= 4'b1100;  // bit 3
     4'b1100: if(next_bit)  state <= 4'b1101;  // bit 4
     4'b1101: if(next_bit)  state <= 4'b1110;  // bit 5
     4'b1110: if(next_bit)  state <= 4'b1111;  // bit 6
     4'b1111: if(next_bit)  state <= 4'b0001;  // bit 7
     4'b0001: if(next_bit)  state <= 4'b0000;  // 停止位
     default: state <= 4'b0000;
    endcase

// 保存接收数据到 RxD_data 中
always @(posedge clk or negedge rst)
   if(~rst)
      RxD_data <= 8'b00000000;
 else if(Baud8Tick && next_bit && state[3])
  RxD_data <= {RxD, RxD_data[7:1]};

// RxD_data_ready 置位信号
always @(posedge clk or negedge rst)
   if(~rst)
      RxD_data_ready <= 0;
 else
    RxD_data_ready <= (Baud8Tick && next_bit && state==4'b0001);

endmodule

 

