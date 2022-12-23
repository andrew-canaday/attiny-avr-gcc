ATTiny / avr-gcc Project Template
=================================

This is my personal ATTiny project base template — basically, just a makefile
that invokes avr-gcc, avrdude, etc.

For target information: `make help`

Example
-------

```bash
# TARGETS:
#   vars:        Print relevant environment vars
#   help:        Print this makefile help menu
#   clean:       Clean build artifacts
#   compile:     Compile project ($(UNIT) $(HEADERS))
#   link:        Link compilation artifacts and package for upload (compile)
#   upload:      Upload (NOTE: USBDEVICE must be set) (link)
#   fuses:       Flash the fuses
#   check-fuses: Verify device signature and check fuse values
# 
# Usage:
#     make \
#     USBDEVICE=/dev/cu.usbserial-1234 \
#     UNIT=my_source.c \
#     DEVICE=<mcu> \
#     <make target>

# Example:
USBDEVICE=/dev/cu.usbserial-1234 \
AVRDUDE_OPTS="-C/path/to/avrdude.conf" \
make upload
```

For other environment variables/settings, see: `make vars`.

For help, see: `make help`.

