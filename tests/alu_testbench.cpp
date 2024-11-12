#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Valu.h"

int main(int argc, char** argv, char** env) {
    Verilated::commandArgs(argc, argv);
    Valu* top = new Valu;
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("alu_testbench.vcd");

    top->a = 5;
    top->b = 3;
    top->eval();
    assert(top->result == 8);

    top->a = 10;
    top->b = 2;
    top->eval();
    assert(top->result == 12);

    tfp->close();
    delete top;
    delete tfp;
    return 0;
}