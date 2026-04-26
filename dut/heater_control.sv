module heater_control #(
    parameter HEAT_ON_TSH = 30, // 5 grade Celsius
    parameter HEAT_OFF_TSH = 35, // 10 grade Celsius
    parameter HEAT_ERR_CNT_TSH = 1000
)
(
    input  logic            clk_i,			
    input  logic            rst_ni,
    input  logic [7 - 1:0]  temp_value_i,	// 0=-25C, 100=75C (Offset 25)
    
    output logic            heat_o,			// Comandă rezistență (1 = ON)
    output logic            error_o
);

logic                                   heat_err_cnt_tick;
logic [$clog2(HEAT_ERR_CNT_TSH) - 1:0]  heat_err_cnt;
logic [7 - 1:0]                         prev_temp;
logic                                   heat_d;
logic                                   heat_tick;

assign heat_err_cnt_tick = (heat_err_cnt == HEAT_ERR_CNT_TSH - 1);

// Control incalzire
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni)                        heat_o <= 1'b0; else // la reset dorim ca incalzirea auxiliara sa fie dezactivata
    if (error_o)                        heat_o <= 1'b0; else // vrem sa oprim incalzirea daca avem o eroare
    if (temp_value_i > HEAT_OFF_TSH)    heat_o <= 1'b0; else
    if (temp_value_i < HEAT_ON_TSH)     heat_o <= 1'b1;
end

//Detector de front pentru heat: detectam momentul in care s-a pornit incalzirea
assign heat_tick = ~heat_d & heat_o;
always_ff @(posedge clk_i or negedge rst_ni) begin
    if(!rst_ni) heat_d <= 1'b0; else
                heat_d <= heat_o;
end

// Monitorizare incalzire / trimitere eroare
// Verificam daca a crescut temperatura doar dupa un anumit timp setat, daca nu a crescut, returnam o eroare
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni)                                    heat_err_cnt <= '0; 
    else if(heat_o) begin
        if (heat_err_cnt == HEAT_ERR_CNT_TSH - 1)   heat_err_cnt <= '0; else
                                                    heat_err_cnt <= heat_err_cnt + 1;
    end
    else if(!heat_o)                                heat_err_cnt <= '0;
end

// Salvam temperatura din momentul in care incalzirea auxiliara este activata
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni)                    prev_temp <= '0;
    else if(heat_tick)              prev_temp <= temp_value_i;
end

always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni)                        error_o <= 1'b0;
    else if(heat_o & heat_err_cnt_tick) begin
        if(temp_value_i <= prev_temp)   error_o <= 1'b1; else
                                        error_o <= 1'b0;
    end
end

endmodule