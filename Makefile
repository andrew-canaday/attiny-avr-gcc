.PHONY: \
	vars \
	help \
	clean \
	compile \
	link \
	upload \
	fuses \
	check-fuses

# Hack to get the directory this makefile is in:
MKFILE_PATH   := $(lastword $(MAKEFILE_LIST))
MKFILE_DIR    := $(notdir $(patsubst %/,%,$(dir $(MKFILE_PATH))))
MKFILE_ABSDIR := $(abspath $(MKFILE_DIR))

# Hack to get all *.h files into compile dependencies:
HEADERS        = $(shell find $(MKFILE_DIR) -name "*.h")


BUILDTMP         ?= $(MKFILE_DIR)/build-tmp
OPTIMIZATION     ?= -Os
AVRCC            ?= avr-gcc
AVRDUDE          ?= avrdude
#---------------------------------------------------------
# AVRDUDE_FLASHARG:
# This preserves the chip memory when updating the fuses.
# To erase the chip when setting fuses, do:
#
#     make AVRDUDE_FLASHARG=-e fuses
#
AVRDUDE_FLASHARG ?= -D
#---------------------------------------------------------
AVR_SIZE         ?= avr-size
AVR_OBJCOPY      ?= avr-objcopy
DEVICE           ?= attiny85
CLOCK            ?= 8000000L
PROGRAMMER       ?= stk500v1
BAUD             ?= 19200
UNIT             ?= main.c
FUSE_EXT         ?= 0xff
FUSE_HIGH        ?= 0xdf
FUSE_LOW         ?= 0xe2

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
	@printf  "%-20.20s%s\n"  "UNIT:"           "$(UNIT)"

help: ## Print this makefile help menu
	@echo "TARGETS:"
	@grep '^[a-z_\-]\{1,\}:.*##' $(MAKEFILE_LIST) \
		| sed 's/^\([a-z_\-]\{1,\}\): *\(.*[^ ]\) *## *\(.*\)/\1:\t\3 (\2)/g' \
		| sed 's/^\([a-z_\-]\{1,\}\): *## *\(.*\)/\1:\t\2/g' \
		| awk '{$$1 = sprintf("%-$(help_spacing)s", $$1)} 1' \
		| sed 's/^/  /'
	@printf "\nUsage:\n    make \\ \n    %s \\ \n    %s \\ \n    %s \\ \n    %s\n" \
		"USBDEVICE=/dev/cu.usbserial-1234" \
		"UNIT=my_source.c" \
		"DEVICE=<mcu>" \
		"<make target>"

clean: ## Clean build artifacts
	rm -rf $(BUILDTMP)/*
	rm -vf *.s

compile: $(UNIT) $(HEADERS) ## Compile project
	$(AVRCC) \
	     -c \
	     -Wall \
	     $(OPTIMIZATION) \
	     -DF_CPU=$(CLOCK) \
	     -mmcu=$(DEVICE) \
	     -I$(MKFILE_DIR) \
 	     $(UNIT) \
	     -o $(BUILDTMP)/$(UNIT).o

link: compile ## Link compilation artifacts and package for upload
	$(AVRCC) \
	    -w \
	    $(OPTIMIZATION) \
	    -flto \
	    -fuse-linker-plugin \
	    -Wl,--gc-sections \
	    -mmcu=$(DEVICE) \
	    -o $(BUILDTMP)/$(UNIT).elf \
	    $(BUILDTMP)/$(UNIT).o \
	    -L$(BUILDTMP) \
	    $(LDFLAGS)
	$(AVR_OBJCOPY) \
	    -O ihex \
	    -j .eeprom \
	    --set-section-flags=.eeprom=alloc,load \
	    --no-change-warnings \
	    --change-section-lma .eeprom=0 \
	    $(BUILDTMP)/$(UNIT).elf \
	    $(BUILDTMP)/$(UNIT).eep
	$(AVR_OBJCOPY) \
	    -O ihex \
	    -R .eeprom \
	    $(BUILDTMP)/$(UNIT).elf \
	    $(BUILDTMP)/$(UNIT).hex
	$(AVR_SIZE) \
	    -A $(BUILDTMP)/$(UNIT).elf

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
	    -Uflash:w:$(BUILDTMP)/$(UNIT).hex:i


fuses: ## Flash the fuses
ifndef USBDEVICE
	$(error 'USBDEVICE not defined! Please set USBDEVICE env var!')
endif # USBDEVICE
	$(AVRDUDE) \
	    $(AVRDUDE_OPTS) \
	    -v \
	    -D \
	    -p$(DEVICE) \
	    -c$(PROGRAMMER) \
	    -P$(USBDEVICE) \
	    -b$(BAUD) \
	    -Uefuse:w:$(FUSE_EXT):m \
	    -Uhfuse:w:$(FUSE_HIGH):m \
	    -Ulfuse:w:$(FUSE_LOW):m

check-fuses: ## Verify device signature and check fuse values
	$(AVRDUDE) \
	    $(AVRDUDE_OPTS) \
	    -p$(DEVICE) \
	    -c$(PROGRAMMER) \
	    -P$(USBDEVICE) \
	    -b$(BAUD)
