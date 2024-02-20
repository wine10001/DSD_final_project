module SyncGeneration(pclk, reset, hSync, vSync,
  dataValid, hDataCnt, vDataCnt);
  input pclk;
  input reset;
  output hSync;
  output vSync;
  output dataValid;
  output [9:0] hDataCnt;
  output [9:0] vDataCnt;
  parameter H_SP_END = 96;
  parameter H_BP_END = 144;
  parameter H_FP_START = 785;
  parameter H_TOTAL = 800;
  parameter V_SP_END = 2;
  parameter V_BP_END = 35;
  parameter V_FP_START = 516;
  parameter V_TOTAL= 525;
  reg [9:0] x_cnt, y_cnt;
  wire h_valid, y_valid;
  always @(posedge pclk or posedge reset) begin
    if (reset)
      x_cnt <= 10'd1;
    else begin
      if (x_cnt == H_TOTAL) // horizontal
        x_cnt <= 10'd1; // retracing
      else
        x_cnt <= x_cnt + 1'b1;
    end
  end
  always @(posedge pclk or posedge reset) begin
    if (reset)
      y_cnt <= 10'd1;
    else begin
      if (y_cnt == V_TOTAL & x_cnt == H_TOTAL)
        y_cnt <= 1; // vertical retracing
      else if (x_cnt == H_TOTAL)
        y_cnt <= y_cnt + 1;
      else y_cnt<=y_cnt;
    end
  end

  assign hSync = ((x_cnt > H_SP_END)) ? 1'b1 : 1'b0;
  assign vSync = ((y_cnt > V_SP_END)) ? 1'b1 : 1'b0;
  // Check P7 for horizontal timing
  assign h_valid = ((x_cnt > H_BP_END) & (x_cnt < H_FP_START)) ? 1'b1 : 1'b0;
  // Check P9 for vertical timing
  assign v_valid = ((y_cnt > V_BP_END) & (y_cnt < V_FP_START)) ? 1'b1 : 1'b0;
  assign dataValid = ((h_valid == 1'b1) & (v_valid == 1'b1)) ? 1'b1 : 1'b0;
  // hDataCnt from 1 if h_valid==1
  assign hDataCnt = ((h_valid == 1'b1)) ? x_cnt - H_BP_END : 10'b0;
  // vDataCnt from 1 if v_valid==1
  assign vDataCnt = ((v_valid == 1'b1)) ? y_cnt - V_BP_END : 10'b0;
endmodule
 
 
module debounce(         ////////////////////////    debounce
 input pb,
 input clk,
 output out);
 reg [19:0] count;
 reg pb_Q1,pb_Q2,pb_Q3;
 assign out=~count[19];
 always@(posedge clk)
   begin
     pb_Q1 <= pb;
     pb_Q2<= pb_Q1;
     pb_Q3<= pb_Q2;
   end
 always@(posedge clk)
   begin
     if(pb_Q3) count<=20'b0;
     else if(!count[19]) count<=count+1'b1;
   end
 endmodule 


module ps2scan(clk,rst_n,ps2k_clk,ps2k_data,ps2_byte);
  input clk; 
  input rst_n;  
  input ps2k_clk;   
  input ps2k_data;  
  output[7:0] ps2_byte;   
  wire ps2_state;   

  reg ps2k_clk_r0,ps2k_clk_r1,ps2k_clk_r2; 

  wire neg_ps2k_clk;  
  always @ (posedge clk or negedge rst_n) begin
      if(!rst_n) begin
            ps2k_clk_r0 <= 1'b0;
            ps2k_clk_r1 <= 1'b0;
            ps2k_clk_r2 <= 1'b0;
        end
      else begin                      
            ps2k_clk_r0 <= ps2k_clk;
            ps2k_clk_r1 <= ps2k_clk_r0;
            ps2k_clk_r2 <= ps2k_clk_r1;
        end
  end
  assign neg_ps2k_clk = ~ps2k_clk_r1 & ps2k_clk_r2;   

  reg[7:0] ps2_byte_r;   
  reg[7:0] temp_data; 
  reg[3:0] num; 
  always @ (posedge clk or negedge rst_n) begin
      if(!rst_n) begin
            num <= 4'd0;
            temp_data <= 8'd0;
        end
      else if(neg_ps2k_clk) begin 
            case (num)
                4'd0:  num <= num+1'b1;
                4'd1:  begin
                          num <= num+1'b1;
                          temp_data[0] <= ps2k_data;  //bit0
                      end
                4'd2:  begin
                          num <= num+1'b1;
                          temp_data[1] <= ps2k_data;  //bit1
                      end
                4'd3:  begin
                          num <= num+1'b1;
                          temp_data[2] <= ps2k_data;  //bit2
                      end
                4'd4:  begin
                          num <= num+1'b1;
                          temp_data[3] <= ps2k_data;  //bit3
                      end
                4'd5:  begin
                          num <= num+1'b1;
                          temp_data[4] <= ps2k_data;  //bit4
                      end
                4'd6:  begin
                          num <= num+1'b1;
                          temp_data[5] <= ps2k_data;  //bit5
                      end
                4'd7:  begin
                          num <= num+1'b1;
                          temp_data[6] <= ps2k_data;  //bit6
                      end
                4'd8:  begin
                          num <= num+1'b1;
                          temp_data[7] <= ps2k_data;  //bit7
                      end
                4'd9:  begin
                          num <= num+1'b1;  
                      end
                4'd10: begin
                          num <= 4'd0;  
                      end
                default: ;
                endcase
        end
  end
  reg key_f0;      
  reg ps2_state_r;  
  always @ (posedge clk or negedge rst_n) begin 
      if(!rst_n) begin
            key_f0 <= 1'b0;
            ps2_state_r <= 1'b0;
        end
      else if(num==4'd10) begin   
            if(temp_data == 8'hf0) key_f0 <= 1'b1;
            else begin
                    if(!key_f0) begin 
                          ps2_state_r <= 1'b1;
                          ps2_byte_r <= temp_data; 
                      end
                    else begin
                          ps2_state_r <= 1'b0;
                          key_f0 <= 1'b0;
                      end
                end
        end
  end
  reg[7:0] ps2_asci;  

  always @ (*) begin
      if(key_f0==1'b0) ps2_asci =8'hf0;
      else begin
      case (ps2_byte_r)   
  
        8'h1d: ps2_asci <= 8'h57;   //W        
        8'h1c: begin ps2_asci <= 8'h41; end//key_w <= 1'b0;key_a <= 1'b1;key_s <= 1'b0;key_d <= 1'b0;key_k <= 1'b0; end  //A
        8'h1b: begin ps2_asci <= 8'h53; end//  key_w <= 1'b0;key_a <= 1'b0;key_s <= 1'b1;key_d <= 1'b0;key_k <= 1'b0; end//S
        8'h23: begin ps2_asci <= 8'h44; end// key_w <= 1'b0;key_a <= 1'b0;key_s <= 1'b0;key_d <= 1'b1;key_k <= 1'b0; end //D
        8'h42: begin ps2_asci <= 8'h4b; end// key_w <= 1'b0;key_a <= 1'b0;key_s <= 1'b0;key_d <= 1'b0;key_k <= 1'b1; end //K
        
        default: ;
        endcase
        end
  end
  assign ps2_byte = ps2_asci;
  assign ps2_state = ps2_state_r;

endmodule


module final_project(clk,mode,rst,ps2_clk,ps2_data,S4,S1,S3,S0,
                     hsync,vsync,vga_r,vga_g,vga_b,LED,left_seg,right_seg,en0,en1);
input clk,mode,rst,ps2_clk,ps2_data,S4,S1,S3,S0;
output hsync,vsync;
output[3:0] vga_r,vga_g,vga_b;
output reg[15:0]LED;
output reg[7:0]left_seg,right_seg;
output reg[3:0]en0,en1;

wire[7:0]ps2_byte;
wire s4,s1,s3,s0;
wire w,a,s,d,k;
wire pclk;
wire valid;
wire irst;
wire[9:0] h_cnt,v_cnt;
reg[11:0] vga_data;
wire [11:0]rom_dout,rom_dout2,rom_dout3,rom_dout4,rom_dout5,rom_dout6;
reg[10:0]rom_addr,rom_addr2,rom_addr3,rom_addr4,rom_addr5,rom_addr6;


wire mario_area,dragon_area,question_area,mushroom_area,knife_area,bullet_area;
reg[9:0]mario_x,mario_y,next_mario_x,next_mario_y;
reg[9:0]dragon_x,dragon_y;
reg[9:0]question_x,question_y;
reg[9:0]mushroom_x,mushroom_y;
reg[9:0]knife_x,knife_y;
reg[9:0]bullet_x,bullet_y;

reg[26:0]dragon_cnt;
reg[5:0]time_cnt;
reg[2:0]life,next_life; 

wire clk1500Hz,clk1Hz;
reg[15:0]count1500Hz;
reg[25:0]count1Hz;
reg[1:0]refreshcounter;
reg[7:0]Seg1,Seg3,Seg4,Seg5,Seg6,Seg8;  

reg[4:0]CS1,NS1;
parameter go=5'd0,l_block=5'd1,t_block=5'd2,r_block=5'd3,b_block=5'd4,lt_block=5'd5,rt_block=5'd6,rb_block=5'd7,
          lb_block=5'd8,lr_block=5'd9,lrb_block=5'd10,up=5'd11,down=5'd12,left=5'd13,right=5'd14,undergo=5'd15,
          flash=5'd16,die=5'd17,sucess=5'd18,special=5'd19;
          
parameter mario_length = 35, mario_height=35;
parameter dragon_length = 35, dragon_height=35;
parameter question_length = 35 ,question_height=35;
parameter mushroom_length = 35 ,mushroom_height=35;
parameter knife_length = 35 ,knife_height=35;
parameter bullet_length = 35 ,bullet_height=35;

assign irst=~rst;


 dcm_25m u0 (
// Clock in ports
.clk_in1(clk), // input clk_in1
// Clock out ports
.clk_out1(pclk), // output clk_out1
// Status and control signals
.reset(irst)); 

 ROMmario u1 (
.clka(pclk), // input wire clka
.addra(rom_addr), // input
.douta(rom_dout)); // output 

ROMdragon u2 (
.clka(pclk), // input wire clka
.addra(rom_addr2), // input
.douta(rom_dout2)); // output 

ROMquestion u3 (
.clka(pclk), // input wire clka
.addra(rom_addr3), // input
.douta(rom_dout3)); // output 

 ROMmushroom u4 (
.clka(pclk), // input wire clka
.addra(rom_addr4), // input
.douta(rom_dout4)); // output 

ROMknife u5 (
.clka(pclk), // input wire clka
.addra(rom_addr5), // input
.douta(rom_dout5)); // output 

ROMbullet u6 (
.clka(pclk), // input wire clka
.addra(rom_addr6), // input
.douta(rom_dout6)); // output 

//ps2  u7 (clk,ps2_clk,ps2_data,rst,w,a,s,d,k);
ps2scan u9 (clk,rst,ps2_clk,ps2_data,ps2_byte);

SyncGeneration u8 (
.pclk(pclk),
.reset(irst),
.hSync(hsync),
.vSync(vsync),
.dataValid(valid),
.hDataCnt(h_cnt),
.vDataCnt(v_cnt));

debounce pbs4(S4,clk,s4);
debounce pbs1(S1,clk,s1);
debounce pbs3(S3,clk,s3);
debounce pbs0(S0,clk,s0);

always@(posedge clk or posedge irst) ////////   1500Hz clk
  begin
    if (irst)
      count1500Hz<=16'b0;
    else
      count1500Hz<=count1500Hz+1'b1;
  end
  assign clk1500Hz=count1500Hz[15];

always@(posedge clk or negedge irst) ////////   1Hz clk
  begin
    if (irst)
      count1Hz<=26'b0;
    else
      count1Hz<=count1Hz+1'b1;
  end
  assign clk1Hz=count1Hz[25];

assign mario_area = ((v_cnt >= mario_y) & (v_cnt   ////////////////////     判斷是否在掃描  mario
<= mario_y + mario_height - 1) & (h_cnt >= mario_x)
& (h_cnt <= mario_x + mario_length - 1)) ? 1'b1 :
1'b0;

assign dragon_area = ((v_cnt >= dragon_y) & (v_cnt   ////////////////////     判斷是否在掃描   dragon
<= dragon_y + dragon_height - 1) & (h_cnt >= dragon_x)
& (h_cnt <= dragon_x + dragon_length - 1)) ? 1'b1 :
1'b0;

assign question_area = ((v_cnt >= question_y) & (v_cnt   ////////////////////     判斷是否在掃描  question
<= question_y + question_height - 1) & (h_cnt >= question_x)
& (h_cnt <= question_x + question_length - 1)) ? 1'b1 :
1'b0;

assign mushroom_area = ((v_cnt >= mushroom_y) & (v_cnt   ////////////////////     判斷是否在掃描  mushroom
<= mushroom_y +mushroom_height - 1) & (h_cnt >= mushroom_x)
& (h_cnt <= mushroom_x + mushroom_length - 1)) ? 1'b1 :
1'b0;

assign knife_area = ((v_cnt >= knife_y) & (v_cnt   ////////////////////     判斷是否在掃描  knife
<= knife_y +knife_height - 1) & (h_cnt >= knife_x)
& (h_cnt <= knife_x + knife_length - 1)) ? 1'b1 :
1'b0;

assign bullet_area = ((v_cnt >= bullet_y) & (v_cnt   ////////////////////     判斷是否在掃描 bullet
<= bullet_y +bullet_height - 1) & (h_cnt >= bullet_x)
& (h_cnt <= bullet_x + bullet_length - 1)) ? 1'b1 :
1'b0;



always @(posedge pclk or posedge irst ) ///////////////     畫出藍線 & 煙囪 & mario & dragon &question
  begin
    if(irst) vga_data <= 12'd0;
    
    else begin
      if(valid==1'b1) begin
        if( (h_cnt>=10'd161) && (h_cnt<=10'd485) && (v_cnt>=10'd81) && (v_cnt<=10'd405) ) begin
                              ////////////////// level 1
            if (dragon_area == 1'b1) begin     /////////////////  畫 dragon
              rom_addr2 <= rom_addr2 +11'd1;
              rom_addr <= rom_addr;
              rom_addr3 <= rom_addr3;
              rom_addr4 <= rom_addr4; 
              rom_addr5 <= rom_addr5; 
              rom_addr6 <= rom_addr6;  
              vga_data <= rom_dout2;
            end
            
            else if( bullet_area && mode ) begin  ///////////////  畫bullet
              rom_addr6 <= rom_addr6 +11'd1;
              rom_addr <= rom_addr;
              rom_addr2 <= rom_addr2;
              rom_addr3 <= rom_addr3;
              rom_addr4 <= rom_addr4; 
              rom_addr5 <= rom_addr5;
              vga_data <= rom_dout6;
            end
            
            else if (mario_area == 1'b1) begin  ////////////  畫 mario
              rom_addr <= rom_addr +11'd1;
              rom_addr2 <= rom_addr2;
              rom_addr3 <= rom_addr3;
              rom_addr4 <= rom_addr4;
              rom_addr5 <= rom_addr5; 
              rom_addr6 <= rom_addr6;
              vga_data <= rom_dout;
            end
            
            else if(question_area == 1'b1) begin ///////////////////    畫question
              rom_addr3 <= rom_addr3 +11'd1;
              rom_addr <= rom_addr;
              rom_addr2 <= rom_addr2;
              rom_addr4 <= rom_addr4;
              rom_addr5 <= rom_addr5; 
              rom_addr6 <= rom_addr6;
              vga_data <= rom_dout3;
            end 
            
            else if(mushroom_area == 1'b1) begin  ////////////////  畫mushroom
              rom_addr4 <= rom_addr4 +11'd1;
              rom_addr <= rom_addr;
              rom_addr2 <= rom_addr2;
              rom_addr3 <= rom_addr3;
              rom_addr5 <= rom_addr5; 
              rom_addr6 <= rom_addr6;
              vga_data <= rom_dout4;
            end
            
            else if( knife_area && mode ) begin  ///////////////  畫knife
              rom_addr5 <= rom_addr5 +11'd1;
              rom_addr <= rom_addr;
              rom_addr2 <= rom_addr2;
              rom_addr3 <= rom_addr3;
              rom_addr4 <= rom_addr4; 
              rom_addr6 <= rom_addr6;
              vga_data <= rom_dout5;
            end
            
            
            
            else if(( (v_cnt>=10'd286) && (v_cnt<=10'd405) && (h_cnt>=10'd206) && (h_cnt<=10'd240) )  ||
                  ( (v_cnt>=10'd86) && (v_cnt<=10'd120) && (h_cnt>=10'd326) && (h_cnt<=10'd360) )  )
                    begin
                           vga_data <= 12'h2B4;                     ///////////   煙囪
                           rom_addr <= rom_addr; 
                           rom_addr2 <= rom_addr2;
                           rom_addr3 <= rom_addr3;
                           rom_addr4 <= rom_addr4;
                           rom_addr5 <= rom_addr5; 
                           rom_addr6 <= rom_addr6;
                    end
            else if( ((v_cnt>=10'd81)&&(v_cnt<=10'd85)) || ((v_cnt>=10'd121)&&(v_cnt<=10'd125))|| ((v_cnt>=10'd161)&&(v_cnt<=10'd165)) ||
                     ((v_cnt>=10'd201)&&(v_cnt<=10'd205)) || ((v_cnt>=10'd241)&&(v_cnt<=10'd245)) || ((v_cnt>=10'd281)&&(v_cnt<=10'd285)) ||
                     ((v_cnt>=10'd321)&&(v_cnt<=10'd325)) || ((v_cnt>=10'd361)&&(v_cnt<=10'd365)) || ((v_cnt>=10'd401)&&(v_cnt<=10'd405)) )     
                    begin
                           vga_data <= 12'h0AE;                  ////////////   線條
                           rom_addr <= rom_addr;
                           rom_addr2 <= rom_addr2;
                           rom_addr3 <= rom_addr3;
                           rom_addr4 <= rom_addr4;
                           rom_addr5 <= rom_addr5; 
                           rom_addr6 <= rom_addr6;
                    end
            else if( ((h_cnt>=10'd161)&&(h_cnt<=10'd165)) || ((h_cnt>=10'd201)&&(h_cnt<=10'd205))|| ((h_cnt>=10'd241)&&(h_cnt<=10'd245)) ||
                     ((h_cnt>=10'd281)&&(h_cnt<=10'd285)) || ((h_cnt>=10'd321)&&(h_cnt<=10'd325)) || ((h_cnt>=10'd361)&&(h_cnt<=10'd365)) ||
                     ((h_cnt>=10'd401)&&(h_cnt<=10'd405)) || ((h_cnt>=10'd441)&&(h_cnt<=10'd445)) || ((h_cnt>=10'd481)&&(h_cnt<=10'd485)) )     
                    begin
                           vga_data <= 12'h0AE;                  ///////////////    線條
                           rom_addr <= rom_addr;
                           rom_addr2 <= rom_addr2;
                           rom_addr3 <= rom_addr3;
                           rom_addr4 <= rom_addr4;
                           rom_addr5 <= rom_addr5; 
                           rom_addr6 <= rom_addr6;
                    end
            else  begin
              vga_data <= 12'hfff;                            /////////////////    白格子
              rom_addr <= rom_addr;
              rom_addr2 <= rom_addr2;
              rom_addr3 <= rom_addr3;
              rom_addr4 <= rom_addr4;
              rom_addr5 <= rom_addr5; 
              rom_addr6 <= rom_addr6;
            end
   
        end 
        
        else begin     //////////////////////// 8*8 方格之外
          vga_data <= 12'h000;
          rom_addr <= rom_addr;
          rom_addr2 <= rom_addr2;
          rom_addr3 <= rom_addr3;
          rom_addr4 <= rom_addr4;
          rom_addr5 <= rom_addr5; 
          rom_addr6 <= rom_addr6;
        end
      end
      
      else begin      ////////////////////////   valid = 0
        vga_data <= 12'h000; 
        if(v_cnt==0) begin
          rom_addr <= 11'd0;
          rom_addr2 <= 11'd0;
          rom_addr3 <= 11'd0;
          rom_addr4 <= 11'd0;
          rom_addr5 <= 11'd0; 
          rom_addr6 <= 11'd0;
        end
        
        else begin
          rom_addr <= rom_addr;
          rom_addr2 <= rom_addr2;
          rom_addr3 <= rom_addr3;
          rom_addr4 <= rom_addr4;
          rom_addr5 <= rom_addr5; 
          rom_addr6 <= rom_addr6;
        end
   
      end
     
    end
 end
 
 assign {vga_r,vga_g,vga_b} = vga_data;
 
 wire l,t,r,b,lt,rt,rb,lb,lr,lrb,boom,m_show,enter,touch_d,touch_b,goal;
 assign boom=( (mario_x==10'd206)&&(mario_y==10'd246)&&(  (s1&&!mode)||(ps2_byte==8'h53&&mode) )) ? 1'b1:1'b0;
 assign m_show=( (mario_x==10'd206)&&(mario_y==10'd246)&&( (s4&&!mode) ||(ps2_byte==8'h57&&mode) )) ?1'b1:1'b0; 
 assign enter=( (mario_x==10'd206)&&(mario_y==10'd246) ) ? 1'b1:1'b0;   //////////////////////// 判斷是否進入 special 狀態
 
 assign l=( (mario_x==10'd166)&&(mario_y==10'd126) || (mario_x==10'd166)&&(mario_y==10'd166) || (mario_x==10'd166)&&(mario_y==10'd246) ||
            (mario_x==10'd246)&&(mario_y==10'd206) || (mario_x==10'd246)&&(mario_y==10'd286) || (mario_x==10'd246)&&(mario_y==10'd326)) ? 1'b1:1'b0;
 assign t=( (mario_x==10'd206)&&(mario_y==10'd86) || (mario_x==10'd246)&&(mario_y==10'd86) || (mario_x==10'd326)&&(mario_y==10'd126) || 
            (mario_x==10'd406)&&(mario_y==10'd86) || (mario_x==10'd446)&&(mario_y==10'd86) ) ? 1'b1:1'b0;
 assign r=( (mario_x==10'd446)&&(mario_y==10'd126) || (mario_x==10'd446)&&(mario_y==10'd166) || (mario_x==10'd446)&&(mario_y==10'd206) ||
            (mario_x==10'd446)&&(mario_y==10'd246) || (mario_x==10'd446)&&(mario_y==10'd286) || (mario_x==10'd446)&&(mario_y==10'd326)) ? 1'b1:1'b0;
 assign b=( (mario_x==10'd206)&&(mario_y==10'd166) || (mario_x==10'd286)&&(mario_y==10'd366) || (mario_x==10'd326)&&(mario_y==10'd366) || 
            (mario_x==10'd366)&&(mario_y==10'd366) || (mario_x==10'd406)&&(mario_y==10'd366) ) ? 1'b1:1'b0;
 assign lt=( (mario_x==10'd166)&&(mario_y==10'd86) || (mario_x==10'd366)&&(mario_y==10'd86) ) ? 1'b1:1'b0;
 assign rt=( (mario_x==10'd286)&&(mario_y==10'd86) ) ? 1'b1:1'b0;
 assign rb=( (mario_x==10'd446)&&(mario_y==10'd366) ) ? 1'b1:1'b0;
 assign lb=( (mario_x==10'd246)&&(mario_y==10'd366) ) ? 1'b1:1'b0;
 assign lr=( (mario_x==10'd166)&&(mario_y==10'd206) || (mario_x==10'd166)&&(mario_y==10'd286) || (mario_x==10'd166)&&(mario_y==10'd326) ) ? 1'b1:1'b0;
 assign lrb=( (mario_x==10'd166)&&(mario_y==10'd366) ) ? 1'b1:1'b0;
 
 assign touch_d = ( (mario_x==dragon_x) && (mario_y==dragon_y) ) ? 1'b1:1'b0;
 assign touch_b=  ( (mario_x==bullet_x) && (mario_y==bullet_y) ) ? 1'b1:1'b0;
 
 assign goal=( (mario_x==10'd486)&&(mario_y==10'd86) ) ?1'b1:1'b0;
 
 
 always@(*)       //////////////////////    第一關 mario next state 判斷
   begin
     case(CS1)
     go: begin
         if(enter) NS1=special;
         else if(!life || !time_cnt ) NS1=die;
         else if(goal) NS1=sucess;
         else if(l) NS1=l_block;
         else if(t) NS1=t_block;
         else if(r) NS1=r_block;
         else if(b) NS1=b_block;
         else if(lt) NS1=lt_block;
         else if(rt) NS1=rt_block;
         else if(rb) NS1=rb_block;
         else if(lb) NS1=lb_block;
         else if(lr) NS1=lr_block;
         else if(lrb)NS1=lrb_block;
         else if((s4&&!mode) ||(ps2_byte==8'h57&&mode)) NS1=up;
         else if((s1&&!mode)||(ps2_byte==8'h53&&mode)) NS1=down;
         else if((s3&&!mode)||(ps2_byte==8'h41&&mode)) NS1=left;
         else if((s0&&!mode)||(ps2_byte==8'h44&&mode)) NS1=right;
         else NS1=go;
         end 
     special: begin
                if(boom) NS1=flash;
                else if(m_show) NS1=special;
                else if((s3&&!mode)||(ps2_byte==8'h41&&mode)) NS1=left;
                else if((s0&&!mode)||(ps2_byte==8'h44&&mode)) NS1=right;
                else NS1=special;
              end
     up: NS1=undergo;
     down: NS1=undergo;
     left: NS1=undergo;
     right:NS1=undergo;
     undergo:begin
               if( (!s4&&!s1&&!s3&&!s0&&!mode) ||(  (ps2_byte!=8'h57)&&(ps2_byte!=8'h41)&&(ps2_byte!=8'h53)&&(ps2_byte!=8'h44)&&mode ) ) NS1=go;
               else NS1=undergo;
             end
      l_block: begin
                 if((s4&&!mode) ||(ps2_byte==8'h57&&mode)) NS1=up;
                 else if((s1&&!mode) ||(ps2_byte==8'h53&&mode)) NS1=down;
                 else if((s0&&!mode) ||(ps2_byte==8'h44&&mode)) NS1=right;
                 else NS1=l_block;
               end
      t_block: begin
                 if(touch_d) NS1=go;
                 else if((s1&&!mode) ||(ps2_byte==8'h53&&mode)) NS1=down;
                 else if((s3&&!mode) ||(ps2_byte==8'h41&&mode)) NS1=left;
                 else if((s0&&!mode) ||(ps2_byte==8'h44&&mode)) NS1=right;                 
                 else NS1=t_block;
               end
      r_block: begin
                 if(!life) NS1=die;
                 else if((s4&&!mode) ||(ps2_byte==8'h57&&mode)) NS1=up;
                 else if((s1&&!mode) ||(ps2_byte==8'h53&&mode)) NS1=down;
                 else if((s3&&!mode) ||(ps2_byte==8'h41&&mode)) NS1=left;
                 else NS1=r_block;
               end
      b_block: begin
                 if((s4&&!mode) ||(ps2_byte==8'h57&&mode)) NS1=up;
                 else if((s3&&!mode) ||(ps2_byte==8'h41&&mode)) NS1=left;
                 else if((s0&&!mode) ||(ps2_byte==8'h44&&mode)) NS1=right;
                 else NS1=b_block;
               end
      lt_block: begin
                  if((s0&&!mode) ||(ps2_byte==8'h44&&mode))  NS1=right;
                  else if((s1&&!mode) ||(ps2_byte==8'h53&&mode)) NS1=down;
                  else NS1=lt_block;
                end
      rt_block: begin
                  if((s3&&!mode) ||(ps2_byte==8'h41&&mode)) NS1=left;
                  else if((s1&&!mode) ||(ps2_byte==8'h53&&mode)) NS1=down;
                  else NS1=rt_block;
                end
      rb_block: begin
                  if((s3&&!mode) ||(ps2_byte==8'h41&&mode)) NS1=left;
                  else if((s4&&!mode) ||(ps2_byte==8'h57&&mode)) NS1=up;
                  else NS1=rb_block;
                end
      lb_block: begin
                  if((s0&&!mode) ||(ps2_byte==8'h44&&mode)) NS1=right;
                  else if((s4&&!mode) ||(ps2_byte==8'h57&&mode)) NS1=up;
                  else NS1=lb_block;
                end
      lr_block: begin
                  if((s4&&!mode) ||(ps2_byte==8'h57&&mode)) NS1=up;
                  else if((s1&&!mode) ||(ps2_byte==8'h53&&mode)) NS1=down;
                  else NS1=lr_block;
                end
      lrb_block: begin
                  if((s4&&!mode) ||(ps2_byte==8'h57&&mode)) NS1=up;
                  else NS1=lrb_block;
                end
      flash : NS1=undergo;
      die: NS1=die;
      sucess:NS1=sucess;
     default: NS1=go;
    endcase
   end
   
   
   always@(posedge pclk or posedge irst)
     begin
       if(irst) CS1<=go;
       else CS1<=NS1;
     end
     
   always@(*)
     begin
      
  
       case(CS1)
       go : begin
              next_mario_x=mario_x;
              next_mario_y=mario_y;
            end
      up :  begin
              next_mario_x=mario_x;
              next_mario_y=mario_y - 10'd40;
            end
      down : begin
               next_mario_x=mario_x;
               next_mario_y=mario_y + 10'd40;
             end
      left : begin
               next_mario_x=mario_x - 10'd40;
               next_mario_y=mario_y;
             end
      right : begin
                next_mario_y=mario_y;
                next_mario_x=mario_x + 10'd40;
              end
      undergo :begin
                next_mario_x=mario_x;
                next_mario_y=mario_y;
               end
      flash : begin
                next_mario_x=10'd326;
                next_mario_y=10'd126;
              end
      default: begin
                next_mario_x=mario_x;
                next_mario_y=mario_y;
               end
      endcase
  
    end
 
 
 
 
 
 
 
 always@(posedge pclk or posedge irst)
   begin
     if (irst) begin
       mario_x <= 10'd166;
       mario_y <= 10'd366;
       question_x <= 10'd206;
       question_y <= 10'd206;
     end
     
     else if(touch_b || touch_d) begin
       mario_x <= 10'd166;
       mario_y <= 10'd366;
       question_x <= 10'd206;
       question_y <= 10'd206;
       
     end
     else begin
       mario_x<=next_mario_x;
       mario_y<=next_mario_y;
       question_x <= question_x;
       question_y <= question_y;
    end
  end

assign k_taken=( (mario_x==knife_x)&&(mario_y==knife_y) ) ? 1'b1:1'b0;
reg kCS,kNS;
parameter k_app=1'b0,k_disapp=1'b1;
always@(*)                                       /////////////////////////////   knife 的狀態判斷
  begin
    case(kCS)
      k_app : begin
              
               if(k_taken) kNS=k_disapp;
               else kNS=k_app;
              end
      k_disapp:  kNS=k_disapp;
 
      default : kNS=k_disapp;
    endcase
  end

always@(posedge pclk or posedge irst)
     begin
       if(irst) kCS<=k_app;
       else kCS<=kNS;
     end
always@(*) begin                         ////////////////////////////// knife 輸出
    case(kCS)
      k_app : begin
                if(!mode)   begin
                  knife_x <= 10'd286;
                  knife_y <= 10'd406;
                end
                
                else begin
                  knife_x <= 10'd286;
                  knife_y <= 10'd366;
                end
              end
      default : begin
                  knife_x <= 10'd286;
                  knife_y <= 10'd406;
                end
    endcase
  end


assign m_eaten=( (mario_x==mushroom_x)&&(mario_y==mushroom_y) ) ? 1'b1:1'b0;
reg mCS,mNS;
parameter m_app=1'b0,m_disapp=1'b1;
always@(*)                                       /////////////////////////////   mushroom 的狀態判斷
  begin
    case(mCS)
      m_app : begin
               if(m_eaten) mNS=m_disapp;
               else mNS=m_app;
              end
      m_disapp: begin
                  if(m_show) mNS=m_app;
                  else mNS=m_disapp;
                end
      default : mNS=m_disapp;
    endcase
  end
  always@(posedge pclk or posedge irst)
     begin
       if(irst) mCS<=m_disapp;
       else mCS<=mNS;
     end
  always@(*) begin                         ////////////////////////////// mushroom 輸出
    case(mCS)
      m_app : begin
                mushroom_x <= 10'd206;
                mushroom_y <= 10'd166;
              end
      default : begin
                  mushroom_x <= 10'd86;
                  mushroom_y <= 10'd166;
                end
    endcase
  end


 always@(posedge pclk or posedge irst)
  begin
    if(irst) dragon_cnt <= 27'd0;
    else if(dragon_cnt==27'd100000000) dragon_cnt <= 27'd0;
    else dragon_cnt <= dragon_cnt + 27'd1;
  end
  
 assign kill_d= ( ( ((mario_x==10'd406)&&(mario_y==10'd86)) || ((mario_x==10'd446)&&(mario_y==10'd126)) ) &&(kCS==k_disapp)&&ps2_byte==8'h4b ) ?1'b1:1'b0;
 reg dCS,dNS;
 parameter d_app=1'b0,d_disapp=1'b1;
 always@(*)                                       /////////////////////////////   dragon 的狀態判斷
  begin
    case(dCS)
      d_app : begin
               if(kill_d) dNS=d_disapp;
               else dNS=d_app;
              end
      d_disapp:  dNS=d_disapp;
 
      default : dNS=d_disapp;
    endcase
  end
  always@(posedge pclk or posedge irst)
     begin
       if(irst) dCS<=d_app;
       else dCS<=dNS;
     end
  always@(*) begin                         ////////////////////////////// dragon 輸出
    case(dCS)
      d_app : begin
                if(mode) begin
                  dragon_x <= 10'd446;
                  dragon_y <= 10'd86;
                end
                else begin
                  if( (dragon_cnt>=27'd50000000)  ) begin 
                    dragon_x <= 10'd446;
                    dragon_y <= 10'd46;
                  end
                  else begin
                    dragon_x <= 10'd446;
                    dragon_y <= 10'd86;
                  end
                end
              end
      d_disapp : begin
                  dragon_x <= 10'd446;
                  dragon_y <= 10'd46;
                end
    endcase
  end


                                                                 /////////////////////// 計算生命
 always@(*) begin
   if(touch_b || touch_d) next_life=life-3'd1;
   else if(life==3'd4) next_life=3'd4;
   else if(m_eaten) next_life=life+3'd1;
   else next_life=life;
 end
 always@(posedge pclk or posedge irst)
   begin
     if(irst) life<=3'd1;
     else life<=next_life;
   end
   
 reg[2:0] bullet_cnt;
 always@(posedge clk1Hz or posedge irst)                 ////////////////////////////// 子彈飛行  
   begin
     if(irst) bullet_cnt <= 3'd0;
     else if(bullet_cnt==3'd6) bullet_cnt<= 3'd0;
     else bullet_cnt<=bullet_cnt+3'd1;
   end
   
 always@(*)
   begin
     if(!mode) begin
                 bullet_x <= 10'd486;
                 bullet_y <= 10'd326;
               end
     else begin
       case(bullet_cnt)
         3'd0: begin
                 bullet_x <= 10'd446;
                 bullet_y <= 10'd326;
               end
         3'd1: begin
                 bullet_x <= 10'd406;
                 bullet_y <= 10'd326;
               end
         3'd2:begin
                 bullet_x <= 10'd366;
                 bullet_y <= 10'd326;
               end
         3'd3: begin
                 bullet_x <= 10'd326;
                 bullet_y <= 10'd326;
               end
         3'd4: begin
                 bullet_x <= 10'd286;
                 bullet_y <= 10'd326;
               end
         3'd5: begin
                 bullet_x <= 10'd246;
                 bullet_y <= 10'd326;
               end
         3'd6: begin
                 bullet_x <= 10'd486;
                 bullet_y <= 10'd326;
               end
         default: begin
                  bullet_x <= 10'd446;
                  bullet_y <= 10'd326;
                  end
       endcase
     end
   end
   
   
   
always@(*) begin      ///////////////////////////////////////////   LED 輸出
  if(CS1==die || CS1==sucess || time_cnt==6'd0)
    begin
      if(dragon_cnt<=27'd50000000) LED=16'b1111_1111_1111_1111;
      else LED=16'b0;
    end
  else begin
    case(life)
      3'd1: LED=16'b1000_0000_0000_0000;
      3'd2: LED=16'b1100_0000_0000_0000;
      3'd3: LED=16'b1110_0000_0000_0000;
      3'd4: LED=16'b1111_0000_0000_0000;
      default: LED=16'b0;
    endcase
  end
end
   

 always@(posedge clk1500Hz or posedge irst) 
     begin
       if(irst) refreshcounter<=2'b0;
       else  refreshcounter<=refreshcounter+2'b1;  
     end
                                           /////////// 視覺暫留之 rightseg show
   always@(*)
     begin
       case(refreshcounter)
         2'd0: en0=4'b0001;
         2'd1: en0=4'b0010;    
         2'd2: en0=4'b0100;
         2'd3: en0=4'b1000;   
       endcase
     end
   always@(*)      /////////////////// left_seg   show
     begin
       case(refreshcounter)
         2'd0:left_seg=Seg4;
         2'd1:left_seg=Seg3; 
         //2'd2:;
         2'd3: left_seg=Seg1;
         default: left_seg=8'b0;   
       endcase
     end
   
   always@(*)
     begin
       case(refreshcounter)
         2'd0: en1=4'b0001;
         2'd1: en1=4'b0010;    
         2'd2: en1=4'b0100;
         2'd3: en1=4'b1000;   
       endcase
     end
   always@(*)      /////////////////// right_seg   show
     begin
       case(refreshcounter)
         2'd0:right_seg=Seg8;
         //2'd1:; 
         2'd2: right_seg=Seg6;
         2'd3: right_seg=Seg5;
         default: right_seg=8'b0;   
       endcase
     end
  
   

always@(*) begin       //////////////////////////// SevenSeg 輸出
  case(life)
    3'd0: Seg1=8'b0011_1111; //0
    3'd1: Seg1=8'b0000_0110; //1
    3'd2: Seg1=8'b0101_1011; //2
    3'd3: Seg1=8'b0100_1111; //3
    3'd4: Seg1=8'b0110_0110; //4
    default:Seg1=8'b0000_0000;
  endcase
end

always@(posedge clk1Hz or posedge irst)
  begin
    if(irst) time_cnt <= 6'd60;
    else if(CS1==die || CS1==sucess || time_cnt==6'd0) time_cnt <= time_cnt;
    else time_cnt <= time_cnt-6'd1;
  end

always@(*) begin
  if(!mode) begin Seg3=8'b0000_0000;Seg4=8'b0000_0000; end
  else begin
    case(time_cnt)
    6'd60: begin Seg3=8'b0111_1101; Seg4=8'b0011_1111; end
    6'd59: begin Seg3=8'b0110_1101; Seg4=8'b0110_1111; end
    6'd58: begin Seg3=8'b0110_1101; Seg4=8'b0111_1111; end
    6'd57: begin Seg3=8'b0110_1101; Seg4=8'b0000_0111; end
    6'd56: begin Seg3=8'b0110_1101; Seg4=8'b0111_1101; end
    6'd55: begin Seg3=8'b0110_1101; Seg4=8'b0110_1101; end
    6'd54: begin Seg3=8'b0110_1101; Seg4=8'b0110_0110; end
    6'd53: begin Seg3=8'b0110_1101; Seg4=8'b0100_1111; end
    6'd52: begin Seg3=8'b0110_1101; Seg4=8'b0101_1011; end
    6'd51: begin Seg3=8'b0110_1101; Seg4=8'b0000_0110; end
    6'd50: begin Seg3=8'b0110_1101; Seg4=8'b0011_1111; end
    
    6'd49: begin Seg3=8'b0110_0110; Seg4=8'b0110_1111; end
    6'd48: begin Seg3=8'b0110_0110; Seg4=8'b0111_1111; end
    6'd47: begin Seg3=8'b0110_0110; Seg4=8'b0000_0111; end
    6'd46: begin Seg3=8'b0110_0110; Seg4=8'b0111_1101; end
    6'd45: begin Seg3=8'b0110_0110; Seg4=8'b0110_1101; end
    6'd44: begin Seg3=8'b0110_0110; Seg4=8'b0110_0110; end
    6'd43: begin Seg3=8'b0110_0110; Seg4=8'b0100_1111; end
    6'd42: begin Seg3=8'b0110_0110; Seg4=8'b0101_1011; end
    6'd41: begin Seg3=8'b0110_0110; Seg4=8'b0000_0110; end
    6'd40: begin Seg3=8'b0110_0110; Seg4=8'b0011_1111; end
    
    6'd39: begin Seg3=8'b0100_1111; Seg4=8'b0110_1111; end
    6'd38: begin Seg3=8'b0100_1111; Seg4=8'b0111_1111; end
    6'd37: begin Seg3=8'b0100_1111; Seg4=8'b0000_0111; end
    6'd36: begin Seg3=8'b0100_1111; Seg4=8'b0111_1101; end
    6'd35: begin Seg3=8'b0100_1111; Seg4=8'b0110_1101; end
    6'd34: begin Seg3=8'b0100_1111; Seg4=8'b0110_0110; end
    6'd33: begin Seg3=8'b0100_1111; Seg4=8'b0100_1111; end
    6'd32: begin Seg3=8'b0100_1111; Seg4=8'b0101_1011; end
    6'd31: begin Seg3=8'b0100_1111; Seg4=8'b0000_0110; end
    6'd30: begin Seg3=8'b0100_1111; Seg4=8'b0011_1111; end
    
    6'd29: begin Seg3=8'b0101_1011; Seg4=8'b0110_1111; end
    6'd28: begin Seg3=8'b0101_1011; Seg4=8'b0111_1111; end
    6'd27: begin Seg3=8'b0101_1011; Seg4=8'b0000_0111; end
    6'd26: begin Seg3=8'b0101_1011; Seg4=8'b0111_1101; end
    6'd25: begin Seg3=8'b0101_1011; Seg4=8'b0110_1101; end
    6'd24: begin Seg3=8'b0101_1011; Seg4=8'b0110_0110; end
    6'd23: begin Seg3=8'b0101_1011; Seg4=8'b0100_1111; end
    6'd22: begin Seg3=8'b0101_1011; Seg4=8'b0101_1011; end
    6'd21: begin Seg3=8'b0101_1011; Seg4=8'b0000_0110; end
    6'd20: begin Seg3=8'b0101_1011; Seg4=8'b0011_1111; end
    
    6'd19: begin Seg3=8'b0000_0110; Seg4=8'b0110_1111; end
    6'd18: begin Seg3=8'b0000_0110; Seg4=8'b0111_1111; end
    6'd17: begin Seg3=8'b0000_0110; Seg4=8'b0000_0111; end
    6'd16: begin Seg3=8'b0000_0110; Seg4=8'b0111_1101; end
    6'd15: begin Seg3=8'b0000_0110; Seg4=8'b0110_1101; end
    6'd14: begin Seg3=8'b0000_0110; Seg4=8'b0110_0110; end
    6'd13: begin Seg3=8'b0000_0110; Seg4=8'b0100_1111; end
    6'd12: begin Seg3=8'b0000_0110; Seg4=8'b0101_1011; end
    6'd11: begin Seg3=8'b0000_0110; Seg4=8'b0000_0110; end
    6'd10: begin Seg3=8'b0000_0110; Seg4=8'b0011_1111; end
    
    6'd9: begin Seg3=8'b0011_1111; Seg4=8'b0110_1111; end
    6'd8: begin Seg3=8'b0011_1111; Seg4=8'b0111_1111; end
    6'd7: begin Seg3=8'b0011_1111; Seg4=8'b0000_0111; end
    6'd6: begin Seg3=8'b0011_1111; Seg4=8'b0111_1101; end
    6'd5: begin Seg3=8'b0011_1111; Seg4=8'b0110_1101; end
    6'd4: begin Seg3=8'b0011_1111; Seg4=8'b0110_0110; end
    6'd3: begin Seg3=8'b0011_1111; Seg4=8'b0100_1111; end
    6'd2: begin Seg3=8'b0011_1111; Seg4=8'b0101_1011; end
    6'd1: begin Seg3=8'b0011_1111; Seg4=8'b0000_0110; end
    6'd0: begin Seg3=8'b0011_1111; Seg4=8'b0011_1111; end
    endcase
  end
end

always@(*) begin
  if(kCS==k_disapp) Seg5=8'b0000_0110; //1
  else Seg5=8'b0000_0000;
end

always@(*) begin
  if(dCS==d_disapp) Seg6=8'b0000_0110; //1
  else Seg6=8'b0000_0000;
end

always@(*) begin
  if(CS1==sucess) Seg8= 8'b0111_1111; //8
  else Seg8=8'b0000_0000;
end

  
endmodule
