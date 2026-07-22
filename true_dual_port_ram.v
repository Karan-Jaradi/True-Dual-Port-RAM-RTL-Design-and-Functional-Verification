module true_dual_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
) (
    // ---------------- Port A ----------------
    input  wire                     clka,
    input  wire                     ena,     // port A enable
    input  wire                     wea,     // port A write enable
    input  wire [ADDR_WIDTH-1:0]    addra,
    input  wire [DATA_WIDTH-1:0]    dina,
    output reg  [DATA_WIDTH-1:0]    douta,
 
    // ---------------- Port B ----------------
    input  wire                     clkb,
    input  wire                     enb,     // port B enable
    input  wire                     web,     // port B write enable
    input  wire [ADDR_WIDTH-1:0]    addrb,
    input  wire [DATA_WIDTH-1:0]    dinb,
    output reg  [DATA_WIDTH-1:0]    doutb
);
 
    localparam DEPTH = 1 << ADDR_WIDTH;
 
    // Shared memory array - inferred as a single dual-port Block RAM
    // by synthesis tools when written this way.
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
 
    // ------------------------------------------------------------------
    // Port A process
    // ------------------------------------------------------------------
    always @(posedge clka) begin
        if (ena) begin
            if (wea) begin
                mem[addra]  <= dina;
                douta       <= dina;        // write-first
            end else begin
                douta       <= mem[addra];  // normal read
            end
        end
    end
 
    // ------------------------------------------------------------------
    // Port B process
    // ------------------------------------------------------------------
    always @(posedge clkb) begin
        if (enb) begin
            if (web) begin
                mem[addrb]  <= dinb;
                doutb       <= dinb;        // write-first
            end else begin
                doutb       <= mem[addrb];  // normal read
            end
        end
    end
 
endmodule