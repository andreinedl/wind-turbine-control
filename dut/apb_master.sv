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

// Automat de stari pentru protocolul APB 
typedef enum logic [1:0] { 
	IDLE,
	SETUP,
	ACCESS,
	PAUSE   // Stare intermediara folosita pentru a evalua daca mai sunt pachete de trimis din cei 96 de biti
} state_t;
state_t state, next_state;

assign paddr_o = 1'b1; // Avem o singura adresa = server-ul nostru
assign penable_o = (state == ACCESS) ? 1'b1 : 1'b0;
assign pwrite_o  = (state == IDLE) ? 1'b0 : 1'b1;
assign pwdata_o  = data_shift_reg[31:0];

// Counter-ul tine evidenta numarului de tranzactii APB de 32 de biti trimise cu succes.
// Un transfer complet necesita 3 tranzactii (3 * 32 = 96 biti).
always_ff @(posedge clk_i or negedge rst_ni) begin							
	if(~rst_ni)							counter <= 0;			else	
	if(state == IDLE)					counter <= 0;			else		// il resetam cat asteptam o noua tranzactie
	if((state == ACCESS) && pready_i)	counter <= counter + 1;
end

// Registrul de deplasare stocheaza intregul pachet de informatii.
// La fiecare tranzactie validata de slave (pready_i=1), datele sunt deplasate 
// spre dreapta cu 32 de biti, pregatind urmatorul cuvant pentru pwdata_o.
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
			// Asteptam confirmarea de la Slave (pready).
			if(pready_i) begin
				// Daca Slave-ul raporteaza o eroare, abandonam tranzactia
				if(pslverr_i) next_state = IDLE;  
				else          next_state = PAUSE; // Tranzactia curenta s-a incheiat cu succes
			end else begin
				next_state = ACCESS;
			end
		end

		PAUSE: begin
			// Verificam daca am trimis toate cele 3 fragmente de 32 de biti.
			if(counter == 3) next_state = IDLE; else
							 next_state = SETUP;
		end

		default: next_state = IDLE;

	endcase
end

// Semnalul PSEL marcheaza o tranzactie activa pe magistrala. Acesta trebuie sa fie 1 la setup si la access
always_comb begin
	case (state)
		SETUP:	 psel_o = 1'b1;
		ACCESS:  psel_o = 1'b1;
		default: psel_o = 1'b0;
	endcase
end

endmodule	//apb_master