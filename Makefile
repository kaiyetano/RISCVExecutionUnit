PROJECT  := FinalProject
REVISION := $(PROJECT)

WIDTH   ?= all
VARIANT ?= all

QUARTUS_SH ?= quartus_sh
QUARTUS_MAP ?= quartus_map
QUARTUS    ?= quartus
POWERSHELL ?= powershell

.PHONY: help sim regress matrix clean synth compile quartus status

help:
	@echo Targets:
	@echo   make sim      - run ModelSim source regression for WIDTH=$(WIDTH), VARIANT=$(VARIANT)
	@echo   make regress  - run all ModelSim source regressions
	@echo   make matrix   - run all Quartus full-compile architecture/width combinations
	@echo   make synth    - run Quartus Analysis and Synthesis
	@echo   make compile  - run full Quartus compile
	@echo   make quartus  - open the Quartus project
	@echo   make clean    - remove generated Quartus and ModelSim files
	@echo   make status   - show git status
	@echo.
	@echo Useful variables:
	@echo   WIDTH=8^|16^|32^|64^|all VARIANT=Baseline^|BKA_BRL^|BKA_SFT^|CSA_BRL^|CSA_SFT^|all

sim:
	$(POWERSHELL) -NoProfile -ExecutionPolicy Bypass -File scripts/run-modelsim-tests.ps1 -Width $(WIDTH) -Variant $(VARIANT)

regress:
	$(MAKE) sim WIDTH=all VARIANT=all

matrix:
	$(POWERSHELL) -NoProfile -ExecutionPolicy Bypass -File scripts/run-quartus-matrix.ps1 -QuartusSh "$(QUARTUS_SH)"

synth:
	"$(QUARTUS_MAP)" $(PROJECT) -c $(REVISION) --read_settings_files=on --write_settings_files=off

compile:
	"$(QUARTUS_SH)" --flow compile $(PROJECT)

quartus:
	"$(QUARTUS)" $(PROJECT).qpf

clean:
	$(POWERSHELL) -NoProfile -ExecutionPolicy Bypass -File scripts/clean.ps1

status:
	git status --short
