#!/usr/bin/env bash

b_name="$( git symbolic-ref --short HEAD )"
d_name="${1:-"attiny-avr-gcc"}"

git archive \
    --format tar \
    --output "${d_name}.tar" \
    --prefix "${d_name}/" \
    "${b_name}"

# EOF

