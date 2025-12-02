`timescale 1ns/1ps

module tb_and_gate;
    reg a, b;
    wire y;

    and_gate uut (.a(a), .b(b), .y(y));
    

    initial begin
        $dumpfile("and_gate.vcd");
        $dumpvars(0, tb_and_gate);
    end
    
    initial begin
        $display("Starting simulation at %0t", $time);
        
        a = 0; b = 0; #10;
        $display("Time=%t: a=%b, b=%b, y=%b", $time, a, b, y);
        
        a = 0; b = 1; #10;
        $display("Time=%t: a=%b, b=%b, y=%b", $time, a, b, y);
        
        a = 1; b = 0; #10;
        $display("Time=%t: a=%b, b=%b, y=%b", $time, a, b, y);
        
        a = 1; b = 1; #10;
        $display("Time=%t: a=%b, b=%b, y=%b", $time, a, b, y);
        
        $display("Simulation finished at %0t", $time);
        $finish;
    end
endmodule