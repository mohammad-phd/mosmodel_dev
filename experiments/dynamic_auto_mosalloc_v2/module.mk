DYNAMIC_AUTO_MOSALLOC_V2_EXPERIMENT_NAME := dynamic_auto_mosalloc_v2
MODULE_NAME := experiments/$(DYNAMIC_AUTO_MOSALLOC_V2_EXPERIMENT_NAME)

DYNAMIC_AUTO_MOSALLOC_V2_EXPERIMENT := $(MODULE_NAME)
DYNAMIC_AUTO_MOSALLOC_V2_RESULTS := $(subst experiments,results,$(DYNAMIC_AUTO_MOSALLOC_V2_EXPERIMENT))
DYNAMIC_AUTO_MOSALLOC_V2_NUM_OF_REPEATS := 4
NUM_LAYOUTS := 50
NUM_OF_REPEATS := $(DYNAMIC_AUTO_MOSALLOC_V2_NUM_OF_REPEATS)
undefine LAYOUTS #allow the template to create new layouts based on the new NUM_LAYOUTS

include $(EXPERIMENTS_TEMPLATE)

CREATE_DYNAMIC_AUTO_MOSALLOC_V2_LAYOUTS_SCRIPT := $(MODULE_NAME)/createLayouts.py
$(LAYOUT_FILES): $(DYNAMIC_AUTO_MOSALLOC_V2_EXPERIMENT)/layouts/%.csv: $(MEMORY_FOOTPRINT_FILE) analysis/pebs_tlb_miss_trace/mem_bins_2mb.csv
	mkdir -p results/$(DYNAMIC_AUTO_MOSALLOC_V2_EXPERIMENT_NAME)
	$(COLLECT_RESULTS) --experiments_root=$(DYNAMIC_AUTO_MOSALLOC_V2_EXPERIMENT) --repeats=$(NUM_OF_REPEATS) \
		--output_dir=$(DYNAMIC_AUTO_MOSALLOC_V2_RESULTS) --skip_outliers
	$(CREATE_DYNAMIC_AUTO_MOSALLOC_V2_LAYOUTS_SCRIPT) \
		--memory_footprint=$(MEMORY_FOOTPRINT_FILE) \
		--pebs_mem_bins=$(MEM_BINS_2MB_CSV_FILE) \
		--layout=$* \
		--exp_dir=$(dir $@)/.. \
		--results_file=$(DYNAMIC_AUTO_MOSALLOC_V2_RESULTS)/median.csv

override undefine NUM_LAYOUTS
override undefine NUM_OF_REPEATS
override undefine LAYOUTS
