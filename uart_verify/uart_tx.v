module transmiter #(parameter integer clock = 50000000,baudrate = 115200)
(input clk,
input rst,
input tx_start,
input [7:0] tx_data,
input parity_en,
input parity_type,
output reg tx,
output reg tx_busy);

localparam integer t_bit = (clock/baudrate);

reg [2:0] state,next;
reg [12:0] baudcount;
reg [2:0] bitcount;
reg [7:0] shift_reg;
reg parity;

parameter tx_idle=3'd0,tx__start=3'd1,tx__data=3'd2,tx_parity=3'd3,tx_stop=3'd4;

always@(posedge clk or posedge rst) begin
if(rst)
state <= tx_idle;
else 
state <= next;
end

always @(posedge clk or posedge rst) begin

    if (rst) begin
        baudcount <= 0;
        bitcount  <= 0;
    end

    else if (state == tx_idle) begin
    	     baudcount <= 0;
    	     bitcount <=0;
	end
    else begin
          if (baudcount == t_bit-1) begin

            baudcount <= 0;
           
	  if(state == tx__data)begin
             if (bitcount < 3'd7)
                bitcount <= bitcount + 1;
	    end
	  end
	 else begin
                baudcount <= baudcount +1;
         end  
	end
    end

always@(posedge clk or posedge rst) begin
        if(rst)
                parity <= 0;
        else if(state == tx_idle && tx_start) begin
                if(parity_en) begin
                        if(parity_type)
                                parity <= ~^tx_data;
                        else
                                parity <= ^tx_data;
                end
                else
                        parity <= 0;
        end
end

always@(posedge clk or posedge rst ) begin
	if(rst)
		shift_reg <= 0;
	else begin
		if (state == tx_idle && tx_start)
    			shift_reg <= tx_data;
		else if (baudcount == t_bit-1 && state == tx__data)
    			shift_reg <= {1'b0,shift_reg[7:1]};
	end	
end

always@(*) begin
case(state)
tx_idle: begin
    tx = 1;
    tx_busy = 0;

    if (tx_start) begin
        next = tx__start;
    end
    else begin
        next = tx_idle;
    end
end

tx__start: begin
    tx = 0;
    tx_busy = 1;

    if (baudcount == t_bit-1) begin
        next = tx__data;
    end
    else begin
        next = tx__start;
    end
end

tx__data: begin

    tx = shift_reg[0];
    tx_busy = 1;

    if (baudcount == t_bit-1) begin
        if (bitcount == 4'd7) begin
            if (parity_en)
                next = tx_parity;
            else
                next = tx_stop;
        end
        else begin
            next = tx__data;
        end

    end
    else begin
        next = tx__data;
    end

end

tx_parity: begin
        tx = parity;
        tx_busy = 1;
        
        if(baudcount == t_bit-1)
                next = tx_stop;
        else
                next = tx_parity;
end

tx_stop: begin
		 tx = 1;
    	tx_busy = 1;

    if (baudcount == t_bit-1) begin
        next = tx_idle;
    end
    else begin
        next = tx_stop;
    end
end
	default : begin
		tx = 1;
		tx_busy = 0;
		next = tx_idle;
	end
 endcase
end

endmodule
		
