ATTiny / avr-gcc Project Template
=================================

This is my personal ATTiny project base template — basically, just a makefile
that invokes avr-gcc, avrdude, etc.

For target information: `make help`

#### :warning: NOTES

 - The `fuses` target has hard-coded fuse values (TODO).
 - If you have more than one source file, you'll want to update the `compile` target dependencies.

Example
-------

```bash
USBDEVICE=/dev/cu.usbserial-1234 \
AVRDUDE_OPTS="-C/path/to/avrdude.conf" \
make upload
```

For other environment variables/settings, see: `make vars`.

