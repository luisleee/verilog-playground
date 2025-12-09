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
ALL_TARGETS = $(patsubst $(TB_DIR)/tb_%.v,%,$(TESTBENCHES))
EXECUTABLES = $(addprefix $(SIM_DIR)/,$(ALL_TARGETS))
WAVEFORMS = $(addprefix $(SIM_DIR)/,$(addsuffix .vcd,$(ALL_TARGETS)))

# 编译选项
CFLAGS = -g2012 -Wall
VFLAGS = --Wall --cc --exe --build

# 默认目标
all: run

# 二级指令支持
ifneq ($(filter-out all compile run view clean list,$(MAKECMDGOALS)),)
TARGET := $(firstword $(filter-out all compile run view clean list,$(MAKECMDGOALS)))
endif

# 编译特定目标
$(SIM_DIR)/%: $(TB_DIR)/tb_%.v $(SOURCES)
	@mkdir -p $(SIM_DIR)
	$(COMPILER) $(CFLAGS) -o $@ $< $(SOURCES)

# 运行特定目标的仿真
$(SIM_DIR)/%.vcd: $(SIM_DIR)/%
	cd $(SIM_DIR) && ../$<

# 主目标定义
.PHONY: all run view clean list

compile: 
ifdef TARGET
	@if [ -f "$(SRC_DIR)/$(TARGET).v" ]; then \
		echo "Compiling and running $(TARGET)"; \
		$(COMPILER) $(CFLAGS) -o $(SIM_DIR)/$(TARGET) $(SRC_DIR)/$(TARGET).v; \
	else \
		echo "Error: source for $(TARGET) not found in $(SRC_DIR)/"; \
		false; \
	fi
endif

# 如果有指定目标，则编译运行特定目标；否则运行所有目标
run: 
ifdef TARGET
	@if [ -f "$(TB_DIR)/tb_$(TARGET).v" ]; then \
		echo "Compiling and running $(TARGET)"; \
		$(MAKE) $(SIM_DIR)/$(TARGET).vcd; \
	else \
		echo "Error: Testbench for $(TARGET) not found in $(TB_DIR)/"; \
		echo "Available targets: $(ALL_TARGETS)"; \
		false; \
	fi
else
	@echo "Running all testbenches"
	@for target in $(ALL_TARGETS); do \
		echo "Running $$target"; \
		$(MAKE) $(SIM_DIR)/$$target.vcd; \
	done
endif

# 查看波形（支持特定目标）
view:
ifdef TARGET
	@if [ -f "$(SIM_DIR)/$(TARGET).vcd" ]; then \
		echo "Viewing waveform for $(TARGET)"; \
		$(VIEWER) $(SIM_DIR)/$(TARGET).vcd & \
	else \
		echo "Error: Waveform file for $(TARGET) not found"; \
		false; \
	fi
else
	@echo "Error: Please specify a target to view (e.g., make view a)"
	@echo "Available targets: $(ALL_TARGETS)"
	@false
endif

# 清理特定目标或所有目标
clean:
ifdef TARGET
	@echo "Cleaning $(TARGET)"
	rm -f $(SIM_DIR)/$(TARGET) $(SIM_DIR)/$(TARGET).vcd
else
	@echo "Cleaning all"
	rm -rf $(SIM_DIR)/*
endif

# 列出可用目标
list:
	@echo "Available targets: $(ALL_TARGETS)"

# 忽略不存在的目标（用于处理命令行参数）
%:
	@:
