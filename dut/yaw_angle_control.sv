module yaw_angle_control #(
    parameter YAW_ERR_CNT_TSH = 2000
) (
    input  logic        clk_i,			// Semnal de ceas
    input  logic        rst_ni,			// Reset activ pe 0 (low)
    input  logic [9:0]  wind_dir_i,		// Directia vantului
    input  logic [9:0]  yaw_angle_i,	// Poziția actuală a nacelei
    output logic [9:0]  yaw_pos_o,		// Unghiul tinta
    output logic        error_o			// Eroare daca nu ajunge la tinta în 1 min
);

logic                                 yaw_err_cnt_tick;
logic [$clog2(YAW_ERR_CNT_TSH) - 1:0] yaw_err_cnt;
logic                                 yaw_aligned;

assign yaw_aligned      = (yaw_pos_o == yaw_angle_i);
assign yaw_err_cnt_tick = (yaw_err_cnt == YAW_ERR_CNT_TSH - 1);

assign yaw_pos_o        = (wind_dir_i < 720) ? wind_dir_i : yaw_angle_i; // protectie impotriva posibilelor erori ale senzorului de directie

always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni)            yaw_err_cnt <= '0; else
    if (!yaw_aligned)       begin
        if(yaw_err_cnt < YAW_ERR_CNT_TSH - 1) yaw_err_cnt <= yaw_err_cnt + 1;
    end else                                  yaw_err_cnt <= '0;
end

always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni)            error_o <= 1'b0; else
    if (yaw_err_cnt_tick)   begin
        if(!yaw_aligned)    error_o <= 1'b1;
    end
    else                    error_o <= 1'b0;
end

endmodule