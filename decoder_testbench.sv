// Mandatory file to be able to launch SVUT flow
`include "svut_h.sv"
// Specify the module to load or on files.f
`include "decoder(.sv"
`timescale 1 ns / 100 ps

module decoder(_testbench();

    `SVUT_SETUP

    [31:0] instruction;
    [4:0] rs1;
    [4:0] rs2;
    [4:0] rd;
    [31:0] imm;
    [6:0] funct7;
    [2:0] funct3;
    [5:0] opcode;
    [2:0] instr_type;

    decoder( 
    dut 
    (
    .instruction (instruction),
    .rs1         (rs1),
    .rs2         (rs2),
    .rd          (rd),
    .imm         (imm),
    .funct7      (funct7),
    .funct3      (funct3),
    .opcode      (opcode),
    .instr_type  (instr_type)
    );


    // To create a clock:
    // initial aclk = 0;
    // always #2 aclk = !aclk;

    // To dump data for visualization:
    // initial begin
    //     Default wavefile name with VCD format
    //     $dumpfile("decoder(_testbench.vcd");
    //     Or use FST format with -fst argument
    //     $dumpfile("decoder(_testbench.fst");
    //     Dump all the signals of the design
    //     $dumpvars(0, decoder(_testbench);
    // end

    // Setup time format when printing with $realtime()
    initial $timeformat(-9, 1, "ns", 8);

    task setup(msg="");
    begin
        // setup() runs when a test begins
    end
    endtask

    task teardown(msg="");
    begin
        // teardown() runs when a test ends
    end
    endtask

    `TEST_SUITE("TESTSUITE_NAME")

    //  Available macros:"
    //
    //    - `MSG("message"):       Print a raw white message
    //    - `INFO("message"):      Print a blue message with INFO: prefix
    //    - `SUCCESS("message"):   Print a green message if SUCCESS: prefix
    //    - `WARNING("message"):   Print an orange message with WARNING: prefix and increment warning counter
    //    - `CRITICAL("message"):  Print a purple message with CRITICAL: prefix and increment critical counter
    //    - `FAILURE("message"):   Print a red message with FAILURE: prefix and do **not** increment error counter
    //    - `ERROR("message"):     Print a red message with ERROR: prefix and increment error counter
    //
    //    - `FAIL_IF(aSignal):                 Increment error counter if evaluaton is true
    //    - `FAIL_IF_NOT(aSignal):             Increment error coutner if evaluation is false
    //    - `FAIL_IF_EQUAL(aSignal, 23):       Increment error counter if evaluation is equal
    //    - `FAIL_IF_NOT_EQUAL(aSignal, 45):   Increment error counter if evaluation is not equal
    //    - `ASSERT(aSignal):                  Increment error counter if evaluation is not true
    //    - `ASSERT(aSignal == 0):           Increment error counter if evaluation is not true
    //
    //  Available flag:
    //
    //    - `LAST_STATUS: tied to 1 if last macro did experience a failure, else tied to 0

    `UNIT_TEST("TESTCASE_NAME")

        // Describe here the testcase scenario
        //
        // Because SVUT uses long nested macros, it's possible
        // some local variable declaration leads to compilation issue.
        // You should declare your variables after the IOs declaration to avoid that.

    `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
