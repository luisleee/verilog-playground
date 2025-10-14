# 工具定义
COMPILER = iverilog
SIMULATOR = vvp
VIEWER = gtkwave

# 目录定义
SRC_DIR = src
TB_DIR = tb
SIM_DIR = sim
INC_DIR = include

# 文件查找
SOURCES = $(wildcard $(SRC_DIR)/*.v)
TESTBENCHES = $(wildcard $(TB_DIR)/tb_*.v)

# 目标定义
TARGETS = $(patsubst $(TB_DIR)/tb_%.v,%,$(TESTBENCHES))
EXECUTABLES = $(addprefix $(SIM_DIR)/,$(TARGETS))
WAVEFORMS = $(addprefix $(SIM_DIR)/,$(addsuffix .vcd,$(TARGETS)))

# 编译选项
CFLAGS = -g2012 -Wall
VFLAGS = --Wall --cc --exe --build

# 默认目标
all: run

# 编译所有测试
compile: $(EXECUTABLES)

$(SIM_DIR)/%: $(TB_DIR)/tb_%.v $(SOURCES)
	@mkdir -p $(SIM_DIR)
	$(COMPILER) $(CFLAGS) -o $@ $< $(SOURCES)

# 运行仿真
run: $(WAVEFORMS)

$(SIM_DIR)/%.vcd: $(SIM_DIR)/%
	cd $(SIM_DIR) && ../$<

# 查看波形
view: $(WAVEFORMS)
	$(VIEWER) $(SIM_DIR)/wave.vcd &

# 清理
clean:
	rm -rf $(SIM_DIR)/*

# 列出可用目标
list:
	@echo "Available targets: $(TARGETS)"

.PHONY: all compile run view clean list verilate