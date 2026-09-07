module baud_rate_generator
#( parameter clk_freq = 50000000,
   parameter baud = 9600
 )
 (
    input clk,rst,
    output reg baud16_tick
);

localparam divisor = clk_freq/(baud*16);

reg[15:0]count;

always@(posedge clk)begin
    if(rst)
    begin
        count<=1'b0;
        baud16_tick<=1'b0;
    end
    else if(count == divisor-1)
        begin
            count<=1'b0;
            baud16_tick<=1'b1;
        end
        else 
        begin
            count<=count+1'b1;
            baud16_tick<=1'b0;
        end
    end
    endmodule
