module receiver#(parameter integer clock = 30000000, baudrate = 115200)
(input clk,
input rst,
input rx,
input parity_en,
input parity_type,
output reg [7:0] rx_data,
output reg rx_valid,
output reg rx_error
);

localparam integer t_bit = clock/baudrate;
localparam integer half_bit = t_bit/2;


reg [2:0] state,next;
reg [12:0] baudcount;
reg [2:0] bitcount;
reg [7:0] shift_reg;
reg parity;
reg parity_error;

parameter rx_idle = 3'd0,rx_start_check = 3'd5,rx__data = 3'd2,rx_parity = 3'd3,rx_stop = 3'd4;

always@(posedge clk or posedge rst) begin
	if(rst)
		state <= rx_idle;
	else 
		state <= next;
	end

always@(posedge clk or posedge rst) begin
	if(rst) begin
		baudcount <= 0;
		bitcount <= 0;
	end
	else if(state == rx_idle)begin
			baudcount <= 0;
			bitcount <= 0;
	end
	else if(state == rx_start_check)begin
		if(baudcount == half_bit-1) begin
			baudcount <= 0;
		end
		else
			baudcount <= baudcount +1;
			
	end
	else begin
		if(baudcount == t_bit-1)begin
			baudcount <= 0;
			if(state == rx__data) begin
				if(bitcount < 3'd7)
					bitcount <= bitcount +1;
			end
	end
		else begin
			baudcount <= baudcount +1;
		end
	end
end

always@(posedge clk or posedge rst ) begin
        if(rst)
                parity <= 0;
        else if(state == rx__data && baudcount == t_bit-1 && bitcount == 3'd7)begin
                if(parity_en) begin
                        if(parity_type)
                                parity <= ~^{rx,shift_reg};
                        else
                                parity <= ^{rx,shift_reg};
                end
                else
                        parity <= 0;
        end
end

always@(posedge clk or posedge rst) begin
	if(rst) begin
		shift_reg <= 0;
	end
	else if(state == rx__data && baudcount == t_bit-1) begin
		shift_reg <= {rx,shift_reg[7:1]};
	end
end

always@(*) begin
	next = state;
	parity_error = 0;
	case(state)
		rx_idle : begin
			if(rx == 0)
				next = rx_start_check;
			else	
				next = rx_idle;
		end
		
		rx_start_check : begin
			if(baudcount == half_bit-1) begin
				if(rx == 0)
					next = rx__data;
				else 
					next = rx_idle;
			end
			else
				next = rx_start_check;
		end
		rx__data : begin
			if(baudcount == t_bit-1) begin
						if (bitcount == 3'd7) begin
                                if(parity_en)
                                     next = rx_parity;
                                else
									next = rx_stop;
						end
				else begin
					next = rx__data;
				end
			end
			else begin
				next = rx__data;
			end
		end

		rx_parity : begin
                        if(baudcount == t_bit-1) begin
                            if(rx != parity)
                                parity_error = 1;
                             else
                                parity_error = 0;
                               
                                
                                next = rx_stop;
                        end
                        else
                                next = rx_parity;
                end
		
		rx_stop: begin
    			if (baudcount == t_bit-1) begin
    			 if (rx == 1'b1) 
        			next = rx_idle;
        		else 
        			next = rx_stop;
    		    end
    		    else
    		      next = rx_stop;
		end
		default : begin 
			next = rx_idle;
		end
	endcase
end
always @(posedge clk or posedge rst) begin
    if (rst) begin
        rx_data  <= 8'd0;
        rx_valid <= 1'b0;
        rx_error <= 1'b0;
    end
    else begin
        if (state == rx_stop && baudcount == t_bit-1) begin
            if (rx == 1'b1) begin
                rx_data  <= shift_reg;
                rx_valid <= 1'b1;
                rx_error <= parity_error;
            end
            else begin
                rx_error <= 1'b1;
                rx_valid <= 1'b0;
            end
        end
    end
end
endmodule 
