
`timescale 1 ps / 1 ps


module tb_top;

    // -------------------------------------------------------------------------
    // Parameters
    // -------------------------------------------------------------------------
    localparam CLK_HALF_PS  = 5_000;          // 100 MHz  → half-period 5 000 ps
//    localparam BIT_PS       = 8_680_000;      // 115 200 baud bit period in ps
    localparam BIT_PS       = 17_260_000;
    localparam RESET_CYCLES = 50;

    // -------------------------------------------------------------------------
    // Signals
    // -------------------------------------------------------------------------
    reg  clk  = 0;
    reg  rst  = 1;
    reg  rxd  = 1;           // UART idle = high
    wire txd;

    // 100 MHz clock
    always #CLK_HALF_PS clk = ~clk;


    initial begin
        rst = 1;
        repeat (RESET_CYCLES) @(posedge clk);
        rst = 0;
    end

    mb_design_wrapper DUT (
        .diff_clock_rtl_clk_p (clk  ),
        .diff_clock_rtl_clk_n (~clk ),
        .reset_rtl             (rst  ),
        .uart_rtl_rxd          (rxd  ),
        .uart_rtl_txd          (txd  )
    );

    task uart_send_byte;
        input [7:0] byte_val;
        integer i;
        begin
            // Start bit
            rxd = 1'b0;
            #BIT_PS;

            // 8 data bits, LSB first
            for (i = 0; i < 8; i = i + 1) begin
                rxd = byte_val[i];
                #BIT_PS;
            end

            // Stop bit
            rxd = 1'b1;
            #BIT_PS;
        end
    endtask


    task uart_send_line;
        input [7:0] ch;
        begin
            uart_send_byte(ch);
            uart_send_byte(8'h0D);   // CR  (\r)
        end
    endtask

    task wait_ms;
        input integer ms;
        integer i;
        begin
            for (i = 0; i < ms; i = i + 1)
                #(2_000_000_000); // was 1ms 
        end
    endtask

    //  Stimulus
    initial begin
        @(negedge rst);


        wait_ms(10);   // 5 ms


        $display("[TB %0t] Sending 'R'", $time);
        uart_send_byte("R");
        uart_send_byte(8'h0D);
        wait_ms(2);

 
        $display("[TB %0t] Sending x_min = -2", $time);
        uart_send_byte("-");
        uart_send_byte("2");
        uart_send_byte(".");
        uart_send_byte("0");
        uart_send_byte(8'h0D);
        wait_ms(2);


        $display("[TB %0t] Sending x_max = 1", $time);
        uart_send_byte("1");
        uart_send_byte(".");
        uart_send_byte("0");
        uart_send_byte(8'h0D);
        wait_ms(2);

        // -----------------------------------------------------------------
        $display("[TB %0t] Sending coeff[0] = 0.0", $time);
        uart_send_byte("0");
        uart_send_byte(".");
        uart_send_byte("0");
        uart_send_byte(8'h0D);
        wait_ms(2);

        // -----------------------------------------------------------------
        $display("[TB %0t] Sending coeff[1] = -2.0", $time);
        uart_send_byte("-");
        uart_send_byte("2");
        uart_send_byte(".");
        uart_send_byte("0");
        uart_send_byte(8'h0D);
        wait_ms(2);

        // -----------------------------------------------------------------
        $display("[TB %0t] Sending coeff[2] = 1.0", $time);
        uart_send_byte("1");
        uart_send_byte(".");
        uart_send_byte("0");
        uart_send_byte(8'h0D);
        wait_ms(2);

        // -----------------------------------------------------------------
        $display("[TB %0t] Sending coeff[3] = 0.0", $time);
        uart_send_byte("0");
        uart_send_byte(".");
        uart_send_byte("0");
        uart_send_byte(8'h0D);
        wait_ms(2);

        // -----------------------------------------------------------------
        $display("[TB %0t] Sending coeff[4] = 5.0", $time);
        uart_send_byte("5");
        uart_send_byte(".");
        uart_send_byte("0");
        uart_send_byte(8'h0D);
        wait_ms(2);

        // -----------------------------------------------------------------
        $display("[TB %0t] Sending coeff[5] = 8.0", $time);
        uart_send_byte("8");
        uart_send_byte(".");
        uart_send_byte("0");
        uart_send_byte(8'h0D);

        // Wait for MinMax IP to finish and MicroBlaze to print MIN= / MAX=.
        // Increase if your hardware takes longer.
        wait_ms(50);   // 50 ms

        // -----------------------------------------------------------------
        // 10. Send "Q\r"  - quit
        // -----------------------------------------------------------------
        $display("[TB %0t] Sending 'Q'", $time);
        uart_send_byte("Q");
        uart_send_byte(8'h0D);

        // Let "Bye." finish printing on TXD.
        wait_ms(5);

        $display("[TB %0t] Simulation complete.", $time);
        $finish;
    end

    // =========================================================================
    //  TXD monitor - decode each byte MicroBlaze sends and print to transcript
    // =========================================================================
    // BIT_PS = 8_680_000 fits in 32 bits (< 2^31), so individual #BIT_PS
    // delays are safe. The only overflow risk was the multi-ms literals above.
    reg        rx_active = 0;
    reg  [7:0] rx_shift;

    always @(negedge txd) begin
        if (!rx_active) begin
            rx_active = 1;
            rx_shift  = 8'h00;
            // Wait to centre of first data bit: 1.5 bit periods from start edge
            #(BIT_PS + BIT_PS/2);   // BIT_PS + BIT_PS/2  (both < 2^31)
            repeat (8) begin
                rx_shift = {txd, rx_shift[7:1]};
                #(BIT_PS);
            end
            $write("%c", rx_shift);
            rx_active = 0;
        end
    end

endmodule