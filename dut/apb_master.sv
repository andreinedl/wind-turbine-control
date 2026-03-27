module apb_master (

	input logic 		clk_i,
	input logic 		rst_ni,
	
	input logic 		start_i,						//trigger pentru a incepe rafala de 3 tranzactii (asta o sa fie un semnal periodic care zice cand se trimit datele)
	input logic 		pready_i,
	input logic  [95:0] info_i,
	
	output logic 		paddr_o,						//paddr 1 bit in cazul nostru (trimitem la aceeasi adresa mereu,
	output logic 		pwrite_o,						//ar fi useless sa fie o adresa de 32 biti)
	output logic [31:0] pwdata_o,
	output logic 		psel_o,
	output logic		penable_o
);

logic [95:0] data_shift_reg = info_i;
logic [1:0] counter;

typedef enum logic [1:0] {
	IDLE,
	SETUP,
	ACCESS,
	PAUSE
} state_t;
state_t state, next_state;

always_ff @(posedge clk_i or negedge rst_ni) begin					//counter pentru a numara nr de tranzactii
	if(~rst_ni)							counter <= 0;			else
	if(state == IDLE)					counter <= 0;			else	//il resetam cat stam degeaba
	if((state == ACCESS) && pready_i)	counter <= counter + 1;
end

always_ff @(posedge clk_i or negedge rst_ni) begin
	if(~rst_ni)							data_shift_reg <= '0;	else		//date random, aici o sa fie intrarile de la senzori concatenate
	if((state == IDLE) && start_i)		data_shift_reg <= info_i;	else
	if((state == ACCESS) && pready_i)	data_shift_reg <= {32'h0000, data_shift_reg[95:32]};
end

always_ff @(posedge clk_i or negedge rst_ni) begin
	if(~rst_ni)			state <= IDLE;					else
						state <= next_state;
end

always_comb begin
	next_state = state;
	psel_o = 0;
	penable_o = 0;
	paddr_o = 1;
	pwdata_o = data_shift_reg[31:0];
	pwrite_o = 1;
	
	case(state)
		IDLE:	begin		if(start_i)			next_state = SETUP;				//modulul sta in IDLE pana cand se primeste semnalul de start
				end
		SETUP:	begin		psel_o = 1;								
							next_state = ACCESS;
				end
		ACCESS:	begin		penable_o = 1;
							psel_o = 1;											
							if(pready_i)		next_state = PAUSE;	else		//daca pready == 1, inseamna ca s-a finalizat o tranzactie deci urmeaza pauza de 1 tact
												next_state = ACCESS;			//daca nu, inseamna ca slave-ul are nevoie de mai mult timp, deci asteptam pana pready == 1
				end
		PAUSE:	begin		if(counter == 2'd3)	next_state = IDLE;	else		//cand counter-ul nostru ajunge la 3, inseamna ca s-au finalizat cele 3 tranzactii
												next_state = SETUP;				//daca nu, mergem iar in SETUP si pregatim urmatoarea tranzactie
				end
	endcase
end

endmodule	//apb_master