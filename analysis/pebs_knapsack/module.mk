MODULE_NAME := analysis/pebs_knapsack
SUBMODULES := 

$(MODULE_NAME)% : NUM_OF_REPEATS := $(PEBS_KNAPSACK_NUM_OF_REPEATS)

include $(COMMON_ANALYSIS_MAKEFILE)

