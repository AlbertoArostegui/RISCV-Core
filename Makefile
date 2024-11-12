TARGET = alu_testbench

SOURCES = tests/alu_testbench.cpp

VERILATOR_FLAGS = --cc --trace

all: $(TARGET)

$(TARGET): $(SOURCES)
	verilator $(VERILATOR_FLAGS) $(SOURCES)
	make -C obj_dir -f V$(TARGET).mk V$(TARGET)

run: $(TARGET)
	./obj_dir/V$(TARGET)

clean:
	rm -rf obj_dir $(TARGET) *.o *.vcd *.log