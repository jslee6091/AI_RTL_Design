module Ex10_1(
    input clk,
    output [15:0] outp
    );
            (* mark_debug = "true" *) reg [18:0] addr_w;
            (* mark_debug = "true" *) reg [13:0] addr_i;
            (* mark_debug = "true" *) reg [12:0] addr_x_Write, addr_x_Read;
            (* mark_debug = "true" *) reg [6:0] addr_bias;
            (* mark_debug = "true" *) wire [9:0] out_w;
            (* mark_debug = "true" *) reg [9:0] out_w_1clock;
            (* mark_debug = "true" *) wire [15:0] out_i, out_x;
            (* mark_debug = "true" *) wire [15:0] out_bias;
            (* mark_debug = "true" *) reg [15:0] mux_out;
            (* mark_debug = "true" *) reg [25:0] mul_out;
            (* mark_debug = "true" *) reg wea;
            (* mark_debug = "true" *) reg s_mux;
            (* mark_debug = "true" *) reg [1:0] s_fsm;
            
            (* mark_debug = "true" *) reg[15:0] max_pool_out; 
            reg [15:0] max1,max2;
            
            mem_W weight (
              .clka(clk),    // input wire clka
              .addra(addr_w),  // input wire [18 : 0] addra
              .douta(out_w)  // output wire [9 : 0] douta
            );
            
            mem_i1 ione (
              .clka(clk),    // input wire clka
              .addra(addr_i),  // input wire [13 : 0] addra
              .douta(out_i)  // output wire [15 : 0] douta
            );
            
            mem_X x (
              .clka(clk),    // input wire clka
              .wea(wea),      // input wire [0 : 0] wea
              .addra(addr_x_Write),  // input wire [12 : 0] addra
              .dina(max_pool_out),    // input wire [15 : 0] dina
              .clkb(clk),    // input wire clkb
              .addrb(addr_x_Read),  // input wire [12 : 0] addrb
              .doutb(out_x)  // output wire [15 : 0] doutb
            );
            
            mem_bias Bias (
              .clka(clk),    // input wire clka
              .addra(addr_bias),  // input wire [6 : 0] addra
              .douta(out_bias)  // output wire [15 : 0] douta
            );
            
            // multiplexer
            always @(posedge clk) begin
                if(s_mux==0) mux_out<=out_x;
                else mux_out<=out_i;
            end
            
            // multiple
            //mul_out 26bits , mux_out 16bits, out_w 10bits
            always @(posedge clk) begin
                out_w_1clock<=out_w;
                mul_out<=mux_out*out_w_1clock;
            end
            

            
            //accumulate
            
            //input: mul_out, acc_reg, output: acc_out
            (* mark_debug = "true" *) reg [25:0] acc_reg;
            (* mark_debug = "true" *) reg [25:0] acc_out;
            (* mark_debug = "true" *) reg last;
            //reg last_delay1, last_delay2, last_delay3, last_delay4,
            
            always @(posedge clk) begin
                acc_out<=mul_out+acc_out;
                if(last) acc_out<=0;
            end
            
            
            //bias convert floating point
            (* mark_debug = "true" *) reg [25:0] out_bias_conv;
            
            always @(posedge clk) begin
                        out_bias_conv[21:7] <= out_bias[14:0];
                        out_bias_conv[25] <= out_bias[15];
                        out_bias_conv[6:0] <= 7'b0000000;
                        out_bias_conv[24:22] <= 3'b000;
            end

            
            //add bias
            (* mark_debug = "true" *) reg [31:0] add_bias;
            
            always @(posedge clk) begin
                add_bias<= out_bias_conv + acc_out;
            end


            
            //sigmoid
            (* mark_debug = "true" *) wire [31:0] add_bias_float;
            
            fixed_to_float biasfloat (
              .aclk(clk),                                  // input wire aclk
              .s_axis_a_tvalid(1),            // input wire s_axis_a_tvalid
              .s_axis_a_tdata(add_bias),              // input wire [31 : 0] s_axis_a_tdata
              .m_axis_result_tvalid(),  // output wire m_axis_result_tvalid
              .m_axis_result_tdata(add_bias_float)    // output wire [31 : 0] m_axis_result_tdata
            );
            
            (* mark_debug = "true" *) wire [31:0] sigmoid_exp;
            (* mark_debug = "true" *) wire [31:0] sigmoid_out;
            
            floating_exp exponential (
              .aclk(clk),                                  // input wire aclk
              .s_axis_a_tvalid(1),            // input wire s_axis_a_tvalid
              .s_axis_a_tdata(add_bias_float),              // input wire [31 : 0] s_axis_a_tdata
              .m_axis_result_tvalid(),  // output wire m_axis_result_tvalid
              .m_axis_result_tdata(sigmoid_exp)    // output wire [31 : 0] m_axis_result_tdata
            );
            
            (* mark_debug = "true" *) wire [31:0] sigmoid_exp_reciprocal;
            floating_div division_exp (
              .s_axis_a_tvalid(1),            // input wire s_axis_a_tvalid
              .s_axis_a_tdata(1),              // input wire [31 : 0] s_axis_a_tdata
              .s_axis_b_tvalid(1),            // input wire s_axis_b_tvalid
              .s_axis_b_tdata(sigmoid_exp),              // input wire [31 : 0] s_axis_b_tdata
              .m_axis_result_tvalid(),  // output wire m_axis_result_tvalid
              .m_axis_result_tdata(sigmoid_exp_reciprocal)    // output wire [31 : 0] m_axis_result_tdata
            );
            
            (* mark_debug = "true" *) wire [31:0] sigmoid_add;
            
            floating_add sigmoid_adder (
              .aclk(clk),                                        // input wire aclk
              .s_axis_a_tvalid(1),                  // input wire s_axis_a_tvalid
              .s_axis_a_tdata(1),                    // input wire [31 : 0] s_axis_a_tdata
              .s_axis_b_tvalid(1),                  // input wire s_axis_b_tvalid
              .s_axis_b_tdata(sigmoid_exp_reciprocal),                    // input wire [31 : 0] s_axis_b_tdata
              .m_axis_result_tvalid(),        // output wire m_axis_result_tvalid
              .m_axis_result_tdata(sigmoid_add)          // output wire [31 : 0] m_axis_result_tdata
            );
            
            floating_div division (
              .aclk(clk),                                  // input wire aclk
              .s_axis_a_tvalid(1),            // input wire s_axis_a_tvalid
              .s_axis_a_tdata(1),              // input wire [31 : 0] s_axis_a_tdata
              .s_axis_b_tvalid(1),            // input wire s_axis_b_tvalid
              .s_axis_b_tdata(sigmoid_add),              // input wire [31 : 0] s_axis_b_tdata
              .m_axis_result_tvalid(),  // output wire m_axis_result_tvalid
              .m_axis_result_tdata(sigmoid_out)    // output wire [31 : 0] m_axis_result_tdata
            );

            
            //32->16bit convert
            
            (* mark_debug = "true" *) wire [15:0] sigmoid_out_fixed;
            
            float_to_fixed fixed_bit_convert (
              .aclk(clk),                                  // input wire aclk
              .s_axis_a_tvalid(1),            // input wire s_axis_a_tvalid
              .s_axis_a_tdata(sigmoid_out),              // input wire [31 : 0] s_axis_a_tdata
              .m_axis_result_tvalid(),  // output wire m_axis_result_tvalid
              .m_axis_result_tdata(sigmoid_out_fixed)    // output wire [15 : 0] m_axis_result_tdata
            );
            
            //maxpool
            (* mark_debug = "true" *) reg [15:0] reg_array[0:15];
            (* mark_debug = "true" *) reg [4:0] column, row;
            (* mark_debug = "true" *) reg max_pool_on_off;
            (* mark_debug = "true" *) reg en;
            
            always @(posedge clk) begin
                if(max_pool_on_off) begin
                    if(en) begin
                        column <= column +1;
                        reg_array[0]<=sigmoid_out_fixed;
                        reg_array[1]<=reg_array[0]; reg_array[2]<=reg_array[1]; reg_array[3]<=reg_array[2];
                        reg_array[4]<=reg_array[3]; reg_array[5]<=reg_array[4]; reg_array[6]<=reg_array[5];
                        reg_array[7]<=reg_array[6]; reg_array[8]<=reg_array[7]; reg_array[9]<=reg_array[8];
                        reg_array[10]<=reg_array[9]; reg_array[11]<=reg_array[10]; reg_array[12]<=reg_array[11];
                        reg_array[13]<=reg_array[12]; reg_array[14]<=reg_array[13]; reg_array[15]<=reg_array[14];
                        
                        if(column==5'b11100) begin row<=row+1; column <=5'b00000; end
                        if(row==5'b11100) row<=5'b00000;
                        if(column[0]==1&&row[0]==1) begin
                            max1=max(reg_array[14], reg_array[15]);
                            max2=max(reg_array[1], max1);
                            max_pool_out=max(reg_array[0],max2);
//                            addr_x_Write<=addr_x_Write+1;
//                            wea<=1;
                        end
                    end
                end
                else max_pool_out<=sigmoid_out_fixed;
            end
            
            function [15:0] max;
                input [15:0] a,b;
                if(a<b) max=b; else max=a;
            endfunction
            
            //FSM
            (* mark_debug = "true" *) reg [4:0] i,j,k;
            (* mark_debug = "true" *) reg [2:0] l,m;
            (* mark_debug = "true" *) reg [1:0] n, image;
            
            (* mark_debug = "true" *) reg [6:0] fc1;
            (* mark_debug = "true" *) reg [4:0] o;
            (* mark_debug = "true" *) reg [3:0] p,q;
            
            (* mark_debug = "true" *) reg [3:0] fc2;
            (* mark_debug = "true" *) reg [6:0] r;
           
            (* mark_debug = "true" *) reg en2; //result max operation enable variable
            
            always @(posedge clk) begin
                case(s_fsm)
                    2'b00: begin s_mux<=1; last<=0; wea<=1; max_pool_on_off<=0;  en<=0;//convolution operation
                           
                            if(addr_i>12287) addr_i<=0;
                            if(m==4) begin
                                m<=0;
                                if(l==4) begin
                                    l<=0;
                                    if(n==2) begin
                                        n<=0;
                                        last<=1;
                                        if(k==27) begin
                                            k<=0;
                                            if(j==27) begin
                                                j<=0;
                                                if(i==24) begin
                                                    i<=0;
                                                    s_fsm<=2'b01;
                                                    addr_w<=addr_w+1;
                                                    addr_bias<=addr_bias+1;
                                                    if(image==3) begin
                                                        image<=0;
                                                        addr_i<=0;
                                                    end else begin
                                                    image<=image+1;
                                                    addr_i<=addr_i+1;
                                                    addr_x_Read<=0;
                                                    end
                                                end else begin
                                                i<=i+1;
                                                addr_w<=75*i;
                                                addr_i<=addr_i-3071;
                                                addr_bias<=addr_bias+1;
//                                                addr_x_Write<=addr_x_Write+1;
//                                                wea<=1;
                                                end
                                            end else begin
                                            j<=j+1;
                                            addr_i<=addr_i-2175; addr_w<=75*i; //addr_i<=image*3072+32*j;
                                            end 
                                        end else begin
                                        k<=k+1;
                                        addr_i<=addr_i-2179; addr_w<=75*i; //addr_i<=image*3072+32*j+k;
                                        addr_x_Write<=addr_x_Write+1;
                                        max_pool_on_off<=1; en<=1;
                                        end
                                    end else begin
                                    n<=n+1; 
                                    addr_i<=addr_i+892; addr_w<=addr_w+1; //addr_i<=image*3072+32*j+k+1024*n;
                                    end
                                end else begin
                                l<=l+1;
                                addr_i<=addr_i+28; addr_w<=addr_w+1; //image*3072+32*j+k+1024*n+32*l;
                                end
                            end else begin
                            m<=m+1;
                            addr_i<=addr_i+1; addr_w<=addr_w+1;
                            end
                            
                          end
                          
                    2'b01: begin s_mux<=0; max_pool_on_off<=0; wea<=1; en<=0;//fully-connected 1
                            if(addr_x_Write==4990) addr_x_Write<=0;
                            if(addr_x_Write < 4900) addr_x_Write<=4900;
                            
                            if(q==13) begin
                                q<=0;
                                if(p==13) begin
                                    p<=0;
                                    if(o==24) begin
                                        o<=0;
                                        if(fc1==79) begin
                                            fc1<=0;
                                            addr_x_Read<=addr_x_Read+1;
                                            addr_w<= addr_w+1;
                                            addr_bias<=addr_bias+1;
                                            addr_x_Write<=0;
                                            s_fsm<=2'b10;
                                        end
                                        else begin
                                            fc1<=fc1+1;
                                            addr_x_Read <= 0;
                                            addr_w<= addr_w+1;
                                            addr_bias<=addr_bias+1;
                                            addr_x_Write<=addr_x_Write+1;
                                            wea<=1;
                                        end
                                    end else begin
                                        o<=o+1;
                                        last<=1; 
                                        addr_x_Read<=addr_x_Read+1;
                                        addr_w<=addr_w+1;
                                    end
                                end else begin
                                    p<=p+1;
                                    addr_x_Read<=addr_x_Read+1;
                                    addr_w<=addr_w+1;
                                end
                            end else begin
                                q<=q+1;
                                addr_x_Read<=addr_x_Read+1;
                                addr_w<=addr_w+1;
                            end
                           end
                            
                    2'b10: begin wea<=0; en2<=0;  max_pool_on_off<=0; en<=0;//fully-connected 2           
                                                        
                            if(r==79) begin
                                r<=0; 
                                if(fc2==9) begin
                                    fc2<=0;
                                    addr_x_Read<=0;
                                    addr_bias<=0;
                                    addr_w<=0;
                                    s_fsm<=2'b00;
                                end
                                else begin
                                    fc2<=fc2+1;
                                    addr_bias<=addr_bias+1;
                                    addr_x_Read<=4900;
                                    addr_w<=addr_w+1;
                                    en2<=1;
                                end
                            end else begin
                                r<=r+1;
                                addr_x_Read<=addr_x_Read+1;
                                addr_w<=addr_w+1;         
                            end
                           end
                endcase
            end 
            
            //result
            reg [15:0] resultReg[0:9];
            (* mark_debug = "true" *) reg [15:0] max_result;
            reg [15:0] max1a,max2a,max3a,max4a,max5a,max6a,max7a,max8a;
            
            (* mark_debug = "true" *) reg [3:0] resultcount;
            always @(posedge clk) begin
                if(en2) begin
                    resultReg[0]<=max_pool_out;
                    resultReg[1]<=resultReg[0];
                    resultReg[2]<=resultReg[1];
                    resultReg[3]<=resultReg[2];
                    resultReg[4]<=resultReg[3];
                    resultReg[5]<=resultReg[4];
                    resultReg[6]<=resultReg[5];
                    resultReg[7]<=resultReg[6];
                    resultReg[8]<=resultReg[7];
                    resultReg[9]<=resultReg[8];
                    
                    resultcount<=resultcount+1;
                    if(resultcount==4'b1010) begin
                        max1a<=max(resultReg[0],resultReg[1]); max2a<=max(max1a,resultReg[2]);
                        max3a<=max(max2a,resultReg[3]); max4a<=max(max3a,resultReg[4]);
                        max5a<=max(max4a,resultReg[5]); max6a<=max(max5a,resultReg[6]);
                        max7a<=max(max6a,resultReg[7]); max8a<=max(max7a,resultReg[8]);
                        max_result<=max(max8a,resultReg[9]);
                    end
                end
            end
            
            assign outp = max_result;
    endmodule