module apb_master (

	input logic 		clk_i,
	input logic 		rst_ni,
	
	input logic 		start_i,						// trigger pentru a incepe rafala de 3 tranzactii
	input logic 		pready_i,
	input logic 		pslverr_i,
	input logic  [95:0] info_i,
	
	output logic 		paddr_o,						
	output logic 		pwrite_o,						
	output logic [31:0] pwdata_o,
	output logic 		psel_o,
	output logic		penable_o
);

logic [95:0] data_shift_reg;
logic [1:0] counter;

typedef enum logic [1:0] { // stari conform protocolului APB
	IDLE,
	SETUP,
	ACCESS,
	PAUSE
} state_t;
state_t state, next_state;

assign paddr_o = 1'b1; // Avem o singura adresa = server-ul nostru
assign penable_o = (state == ACCESS) ? 1'b1 : 1'b0;
assign pwrite_o  = (state == IDLE) ? 1'b0 : 1'b1;
assign pwdata_o  = data_shift_reg[31:0];

always_ff @(posedge clk_i or negedge rst_ni) begin							// counter pentru a numara numarul de tranzactii
	if(~rst_ni)							counter <= 0;			else	
	if(state == IDLE)					counter <= 0;			else		// il resetam cat asteptam o noua tranzactie
	if((state == ACCESS) && pready_i)	counter <= counter + 1;
end

always_ff @(posedge clk_i or negedge rst_ni) begin
	if(~rst_ni)							data_shift_reg <= '0;		else
	if((state == IDLE) && start_i)		data_shift_reg <= info_i;	else
	if((state == ACCESS) && pready_i)	data_shift_reg <= {32'h0, data_shift_reg[95:32]};
end

always_ff @(posedge clk_i or negedge rst_ni) begin
	if(~rst_ni)			state <= IDLE;					else
						state <= next_state;
end

always_comb begin
	case(state)
		IDLE: begin  	
			if(start_i) next_state = SETUP; else
						next_state = IDLE;
		end

		SETUP: 	next_state = ACCESS;

		ACCESS: begin
			if(pready_i) begin
				if(pslverr_i) next_state = IDLE; 
				else          next_state = PAUSE; 
			end else begin
				next_state = ACCESS;
			end
		end

		PAUSE: begin
			if(counter == 3) next_state = IDLE; else
							 next_state = SETUP;
		end

		default: next_state = IDLE;

	endcase
end

//psel
always_comb begin
	case (state)
		SETUP:	 psel_o = 1'b1;
		ACCESS:  psel_o = 1'b1;
		default: psel_o = 1'b0;
	endcase
end

endmodule	//apb_master