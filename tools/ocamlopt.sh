#!/bin/bash -e
if test "$(basename "$(dirname $OTOP)")" != "ocaml_stuff"; then
    COMM="$OTOP/boot/ocamlrun$EXE $OTOP/ocamlopt -I $OTOP/stdlib"
else
    COMM=ocamlopt$OPT
fi
echo $COMM $*
$COMM $*
