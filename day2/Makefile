default: clean run

clean:
	$(RM) ./hd0/copper out.bin

run: ./hd0/copper
	fs-uae --base-dir=./fs-uae

./hd0/copper: out.bin
	vlink $<        \
		-o $@       \
		-bamigahunk \
		-mrel       \
		-Bstatic

out.bin: hello.s include/baremetal_cli.i include/numerics.i include/font.i
	vasmm68k_mot $< \
		-o $@       \
		-Fhunk      \
		-esc        \
		-spaces     \
		-m68000

