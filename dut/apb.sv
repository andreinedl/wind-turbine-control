module apb_master #(
    parameter ADDR_W = 3,
    parameter DATA_W = 32
) (
    input  logic              clk,
    input  logic              rst_n,
    
    // Interfața cu logica de control
    input  logic              execute,    // Puls pentru a porni o tranzacție
    input  logic              write_en,   // 1-Write, 0-Read
    input  logic [ADDR_W-1:0] addr_in,
    input  logic [DATA_W-1:0] data_in,
    output logic [DATA_W-1:0] data_out,
    output logic              ready,      // Masterul e liber
    
    // Interfața APB (se leagă la Slave)
    output logic [ADDR_W-1:0] PADDR,
    output logic              PSEL,
    output logic              PENABLE,
    output logic              PWRITE,
    output logic [DATA_W-1:0] PWDATA,
    input  logic [DATA_W-1:0] PRDATA,
    input  logic              PREADY
);

    typedef enum logic [1:0] {ST_IDLE, ST_SETUP, ST_ACCESS} state_t;
    state_t state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= ST_IDLE;
            PSEL    <= 0;
            PENABLE <= 0;
            ready   <= 1;
        end else begin
            case (state)
                ST_IDLE: begin
                    ready <= 1;
                    if (execute) begin
                        state   <= ST_SETUP;
                        PSEL    <= 1;
                        PWRITE  <= write_en;
                        PADDR   <= addr_in;
                        PWDATA  <= data_in;
                        ready   <= 0;
                    end
                end

                ST_SETUP: begin
                    PENABLE <= 1;
                    state   <= ST_ACCESS;
                end

                ST_ACCESS: begin
                    if (PREADY) begin
                        if (!PWRITE) data_out <= PRDATA;
                        PSEL    <= 0;
                        PENABLE <= 0;
                        state   <= ST_IDLE;
                    end
                end
            endcase
        end
    end
endmodule