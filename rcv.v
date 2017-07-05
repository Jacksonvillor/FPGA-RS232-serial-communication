module rcv(clk,
           rst,
           RxD,
           RxD_data,
           RxD_data_ready,
           );
input       clk,
            rst,
            RxD;
output[7:0] RxD_data;        // �������ݼĴ���        
output      RxD_data_ready;  // ������8λ���ݣ�RxD_data ֵ��Чʱ��RxD_data_ready ������ź�


parameter  ClkFrequency = 25000000;  // ʱ��Ƶ�ʣ�25MHz
parameter  Baud = 115200;            // �����ʣ�115200

reg[2:0]  bit_spacing;
reg       RxD_delay;
reg      RxD_start;
reg[3:0]  state;
reg[7:0]  RxD_data;
reg       RxD_data_ready;

// �����ʲ�����ʹ��8��������
parameter Baud8 = Baud*8;
parameter Baud8GeneratorAccWidth = 16;
wire    [Baud8GeneratorAccWidth:0] Baud8GeneratorInc = ((Baud8<<(Baud8GeneratorAccWidth-7))+(ClkFrequency>>8))/(ClkFrequency>>7);
reg     [Baud8GeneratorAccWidth:0] Baud8GeneratorAcc;

always @(posedge clk or negedge rst)
   if(~rst)
      Baud8GeneratorAcc <= 0;
   else  
    Baud8GeneratorAcc <= Baud8GeneratorAcc[Baud8GeneratorAccWidth-1:0] + Baud8GeneratorInc;

// Baud8Tick Ϊ�����ʵ�8�� �� 115200*8 = 921600
//wire  Baud8Tick = Baud8GeneratorAcc[Baud8GeneratorAccWidth]; 
wire  Baud8Tick = 1; 

// next_bit Ϊ������ �� 115200
always @( negedge rst)
 if(~rst||(state==0))
      bit_spacing <= 0;
 else if(Baud8Tick)
    bit_spacing <= bit_spacing + 1;
wire next_bit = (bit_spacing==7);

// ��⵽ TxD ��������ʱ��RxD_start ��1��׼����������
always@(posedge clk)
 begin
  RxD_delay <= RxD;
    RxD_start <= (Baud8Tick &(~ RxD_delay) & (~RxD));
 end 

// ״̬����������
always@(posedge clk or negedge rst)
 if(~rst)
    state <= 4'b0000;
 else if(Baud8Tick)
    case(state)
     4'b0000: if(RxD_start) state <= 4'b1000;  // ��⵽������
     4'b1000: if(next_bit)  state <= 4'b1001;  // bit 0
     4'b1001: if(next_bit)  state <= 4'b1010;  // bit 1
     4'b1010: if(next_bit)  state <= 4'b1011;  // bit 2
     4'b1011: if(next_bit)  state <= 4'b1100;  // bit 3
     4'b1100: if(next_bit)  state <= 4'b1101;  // bit 4
     4'b1101: if(next_bit)  state <= 4'b1110;  // bit 5
     4'b1110: if(next_bit)  state <= 4'b1111;  // bit 6
     4'b1111: if(next_bit)  state <= 4'b0001;  // bit 7
     4'b0001: if(next_bit)  state <= 4'b0000;  // ֹͣλ
     default: state <= 4'b0000;
    endcase

// ����������ݵ� RxD_data ��
always @(posedge clk or negedge rst)
   if(~rst)
      RxD_data <= 8'b00000000;
 else if(Baud8Tick && next_bit && state[3])
  RxD_data <= {RxD, RxD_data[7:1]};

// RxD_data_ready ��λ�ź�
always @(posedge clk or negedge rst)
   if(~rst)
      RxD_data_ready <= 0;
 else
    RxD_data_ready <= (Baud8Tick && next_bit && state==4'b0001);

endmodule

 

