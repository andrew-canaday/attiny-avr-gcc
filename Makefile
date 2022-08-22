.PHONY: vars help clean compile link upload bootloader 

# Hack to get the directory this makefile is in:
MKFILE_PATH := $(lastword $(MAKEFILE_LIST))
MKFILE_DIR := $(notdir $(patsubst %/,%,$(dir $(MKFILE_PATH))))
MKFILE_ABSDIR := $(abspath $(MKFILE_DIR))


BUILDTMP ?= $(MKFILE_DIR)/build-tmp

OPTIMIZATION ?= -Ofast
AVRCC        ?= avr-gcc
AVRDUDE      ?= avrdude
AVR_SIZE     ?= avr-size
AVR_OBJCOPY  ?= avr-objcopy
DEVICE       ?= attiny85
CLOCK        ?= 8000000L
PROGRAMMER   ?= stk500v1
BAUD         ?= 19200
SRC_MAIN     ?= main.c

# Misc target info:
help_spacing  := 12

.DEFAULT_GOAL := compile

#---------------------------------------------------------
# Ensure temp directories.
#
# In order to ensure temp dirs exit, we include a file
# that doesn't exist, with a target declared as PHONY
# (above), and then have the target create our tmp dirs.
#---------------------------------------
-include ensure-tmp
ensure-tmp:
	@mkdir -p $(BUILDTMP)

vars: ## Print relevant environment vars
	@printf  "%-20.20s%s\n"  "MKFILE_PATH:"    "$(MKFILE_PATH)"
	@printf  "%-20.20s%s\n"  "MKFILE_DIR:"     "$(MKFILE_DIR)"
	@printf  "%-20.20s%s\n"  "MKFILE_ABSDIR:"  "$(MKFILE_ABSDIR)"
	@printf  "%-20.20s%s\n"  "BUILDTMP:"       "$(BUILDTMP)"
	@printf  "%-20.20s%s\n"  "OPTIMIZATION:"   "$(OPTIMIZATION)"
	@printf  "%-20.20s%s\n"  "AVRCC:"          "$(AVRCC)"
	@printf  "%-20.20s%s\n"  "AVRDUDE:"        "$(AVRDUDE)"
	@printf  "%-20.20s%s\n"  "AVRDUDE_OPTS:"   "$(AVRDUDE_OPTS)"
	@printf  "%-20.20s%s\n"  "AVR_SIZE:"       "$(AVR_SIZE)"
	@printf  "%-20.20s%s\n"  "AVR_OBJCOPY:"    "$(AVR_OBJCOPY)"
	@printf  "%-20.20s%s\n"  "DEVICE:"         "$(DEVICE)"
	@printf  "%-20.20s%s\n"  "CLOCK:"          "$(CLOCK)"
	@printf  "%-20.20s%s\n"  "PROGRAMMER:"     "$(PROGRAMMER)"
	@printf  "%-20.20s%s\n"  "BAUD:"           "$(BAUD)"
	@printf  "%-20.20s%s\n"  "SRC_MAIN:"       "$(SRC_MAIN)"

help: ## Print this makefile help menu
	@echo "TARGETS:"
	@grep '^[a-z_\-]\{1,\}:.*##' $(MAKEFILE_LIST) \
		| sed 's/^\([a-z_\-]\{1,\}\): *\(.*[^ ]\) *## *\(.*\)/\1:\t\3 (\2)/g' \
		| sed 's/^\([a-z_\-]\{1,\}\): *## *\(.*\)/\1:\t\2/g' \
		| awk '{$$1 = sprintf("%-$(help_spacing)s", $$1)} 1' \
		| sed 's/^/  /'

clean: ## Clean build artifacts
	rm -rf $(BUILDTMP)/*
	rm -vf *.s

compile: $(SRC_MAIN) ## Compile project
	$(AVRCC) \
	     -c \
	     -Wall \
	     $(OPTIMIZATION) \
	     -DF_CPU=$(CLOCK) \
	     -mmcu=$(DEVICE) \
	     -I$(MKFILE_DIR) \
 	     $(SRC_MAIN) \
	     -o $(BUILDTMP)/$(SRC_MAIN).o

link: compile ## Link compilation artifacts and package for upload
	$(AVRCC) \
	    -w \
	    $(OPTIMIZATION) \
	    -flto \
	    -fuse-linker-plugin \
	    -Wl,--gc-sections \
	    -mmcu=$(DEVICE) \
	    -o $(BUILDTMP)/$(SRC_MAIN).elf \
	    $(BUILDTMP)/$(SRC_MAIN).o \
	    -L$(BUILDTMP) \
	    -lm
	$(AVR_OBJCOPY) \
	    -O ihex \
	    -j .eeprom \
	    --set-section-flags=.eeprom=alloc,load \
	    --no-change-warnings \
	    --change-section-lma .eeprom=0 \
	    $(BUILDTMP)/$(SRC_MAIN).elf \
	    $(BUILDTMP)/$(SRC_MAIN).eep
	$(AVR_OBJCOPY) \
	    -O ihex \
	    -R .eeprom \
	    $(BUILDTMP)/$(SRC_MAIN).elf \
	    $(BUILDTMP)/$(SRC_MAIN).hex
	$(AVR_SIZE) \
	    -A $(BUILDTMP)/$(SRC_MAIN).elf

upload: link ## Upload (NOTE: USBDEVICE must be set)
ifndef USBDEVICE
	$(error 'USBDEVICE not defined! Please set USBDEVICE env var!')
endif # USBDEVICE
	$(AVRDUDE) \
	    $(AVRDUDE_OPTS) \
	    -v \
	    -p$(DEVICE) \
	    -c$(PROGRAMMER) \
	    -P$(USBDEVICE) \
	    -b$(BAUD) \
	    -Uflash:w:$(BUILDTMP)/$(SRC_MAIN).hex:i


bootloader: ## Flash the bootloader
ifndef USBDEVICE
	$(error 'USBDEVICE not defined! Please set USBDEVICE env var!')
endif # USBDEVICE
	$(AVRDUDE) \
	    $(AVRDUDE_OPTS) \
	    -v \
	    -v \
	    -v \
	    -v \
	    -p$(DEVICE) \
	    -c$(PROGRAMMER) \
	    -P$(USBDEVICE) \
	    -b$(BAUD) \
	    -e \
	    -Uefuse:w:0xff:m \
	    -Uhfuse:w:0xdf:m \
	    -Ulfuse:w:0xe2:m
	$(AVRDUDE) \
	    $(AVRDUDE_OPTS) \
	    -v \
	    -v \
	    -v \
	    -v \
	    -p$(DEVICE) \
	    -c$(PROGRAMMER) \
	    -P$(USBDEVICE) \
	    -b$(BAUD)

