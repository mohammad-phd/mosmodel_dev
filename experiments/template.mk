include $(EXPERIMENTS_VARS_TEMPLATE)

define MEASUREMENTS_template =
$(EXPERIMENT_DIR)/$(1)/$(2)/perf.out: %/perf.out: $(EXPERIMENT_DIR)/layouts/$(1).csv | experiments-prerequisites 
	echo ========== [INFO] allocate/reserve hugepages ==========
	$$(SET_CPU_MEMORY_AFFINITY) $$(BOUND_MEMORY_NODE) $$(RUN_MOSALLOC_TOOL) --library $$(MOSALLOC_TOOL) -cpf $$(ROOT_DIR)/$$< /bin/date
	echo ========== [INFO] start producing: $$@ ==========
	$$(RUN_BENCHMARK) --num_threads=$$(NUMBER_OF_THREADS) \
		--submit_command \
		"$$(MEASURE_GENERAL_METRICS) $$(SET_CPU_MEMORY_AFFINITY) $$(BOUND_MEMORY_NODE) \
		$$(RUN_MOSALLOC_TOOL) --library $$(MOSALLOC_TOOL) -cpf $$(ROOT_DIR)/$$< $$(EXTRA_ARGS_FOR_MOSALLOC)" -- \
		$$(BENCHMARK_PATH) $$*
endef

define VANILLA_template =
$(EXPERIMENT_DIR)/$(1)/$(2)/perf.out: %/$(2)/perf.out: $(EXPERIMENT_DIR)/layouts/$(1).csv | experiments-prerequisites 
	echo ========== [INFO] start producing: $$@ ==========
	$$(RUN_BENCHMARK) \
		--prefix="sudo -E cset shield --exec" \
		--num_threads=$$(NUMBER_OF_THREADS) \
		--num_repeats=$$(NUM_OF_REPEATS) \
		--submit_command "$$(RUN_WITH_CONDA) -- $$(MEASURE_GENERAL_METRICS)" \
			-- $$(BENCHMARK_PATH) $$*
endef

define SLURM_EXPS_template =
$(EXPERIMENT_DIR)/$(1)/$(2)/perf.out: %/$(2)/perf.out: $(EXPERIMENT_DIR)/layouts/$(1).csv | experiments-prerequisites 
	echo ========== [INFO] allocate/reserve hugepages ==========
	for ((i=0; i < $$(NUMBER_OF_SOCKETS); i++)) do
		srun -- $$(RUN_MOSALLOC_TOOL) --library $$(MOSALLOC_TOOL) -cpf $$(ROOT_DIR)/$$< sleep 2 &
	done
	wait
	echo ========== [INFO] hugepages allocation is done for all nodes ==========
	echo ========== [INFO] start producing: $$@ ==========
	$$(RUN_BENCHMARK_WITH_SLURM) --num_threads=$$(NUMBER_OF_THREADS) --num_repeats=$$(NUM_OF_REPEATS) \
		--submit_command "$$(MEASURE_GENERAL_METRICS)  \
		$$(RUN_MOSALLOC_TOOL) --library $$(MOSALLOC_TOOL) -cpf $$(ROOT_DIR)/$$< $$(EXTRA_ARGS_FOR_MOSALLOC)" -- \
		$$(BENCHMARK_PATH) $$*
endef

define CSET_SHIELD_EXPS_template =
$(EXPERIMENT_DIR)/$(1)/$(2)/perf.out: %/$(2)/perf.out: $(EXPERIMENT_DIR)/layouts/$(1).csv | experiments-prerequisites 
	echo ========== [INFO] reserve hugepages before start running: $$@ ==========
	sudo -E cset shield --exec \
		$$(RUN_WITH_CONDA) -- $$(RUN_MOSALLOC_TOOL) --library $$(MOSALLOC_TOOL) -cpf $$(ROOT_DIR)/$$< $$(EXTRA_ARGS_FOR_MOSALLOC) -- sleep 1
	echo ========== [INFO] start producing: $$@ ==========
	$$(RUN_BENCHMARK) \
		--prefix="sudo -E cset shield --exec" \
		--num_threads=$$(NUMBER_OF_THREADS) \
		--num_repeats=$$(NUM_OF_REPEATS) \
		--submit_command "$$(RUN_WITH_CONDA) -- $$(MEASURE_GENERAL_METRICS)  \
			$$(RUN_MOSALLOC_TOOL) --library $$(MOSALLOC_TOOL) -cpf $$(ROOT_DIR)/$$< $$(EXTRA_ARGS_FOR_MOSALLOC) --debug" \
			-- $$(BENCHMARK_PATH) $$*
endef

ifdef VANILLA_RUN
$(foreach layout,$(LAYOUTS),$(foreach repeat,$(REPEATS),$(eval $(call VANILLA_template,$(layout),$(repeat)))))
else # VANILLA_RUN
ifdef SERIAL_RUN
$(foreach layout,$(LAYOUTS),$(foreach repeat,$(REPEATS),$(eval $(call MEASUREMENTS_template,$(layout),$(repeat)))))
else # SERIAL_RUN
ifdef SLURM
$(foreach layout,$(LAYOUTS),$(foreach repeat,$(REPEATS),$(eval $(call SLURM_EXPS_template,$(layout),$(repeat)))))
else # SLURM
$(foreach layout,$(LAYOUTS),$(foreach repeat,$(REPEATS),$(eval $(call CSET_SHIELD_EXPS_template,$(layout),$(repeat)))))
endif # SLURM
endif # SERIAL_RUN
endif # VANILLA_RUN
