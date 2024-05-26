

ifndef QEMU
QEMU := $(shell if which qemu-system-i386 > /dev/null; \
	then echo 'qemu-system-i386'; exit; \
	elif which i386-elf-qemu > /dev/null; \
	then echo 'i386-elf-qemu'; exit; \
	elif which qemu > /dev/null; \
	then echo 'qemu'; exit; \
	else \
	echo "***" 1>&2; \
	echo "*** Error: Couldn't find a working QEMU executable." 1>&2; \
	echo "*** Is the directory containing the qemu binary in your PATH" 1>&2; \
	echo "***" 1>&2; exit 1; fi)
endif

BUILD := build
SRC := src

ENTRYPOINT := 0X10000

#CFLAGS:= -m32
CFLAGS:= -fno-builtin -Wall -ggdb -m32 -gstabs -nostdinc -fno-stack-protector

DEBUG:=-g

INCLUDE:=-I$(SRC)/include/

$(kernel): tools/kernel.ld

$(BUILD)/boot/%.bin: $(SRC)/boot/%.asm
	$(shell mkdir -p $(dir $@))
	nasm -f bin $< -o $@

$(BUILD)/loader/%.o: $(SRC)/loader/%.S
	$(shell mkdir -p $(dir $@))
	gcc $(CFLAGS) $(DEBUG)  $(INCLUDE) -c $< -o $@

$(BUILD)/loader/%.o: $(SRC)/loader/%.c
	$(shell mkdir -p $(dir $@))
	gcc $(CFLAGS) $(DEBUG)  $(INCLUDE) -c $< -o $@

# $^表示所有的依赖文件
$(BUILD)/loader/loader.out: $(BUILD)/loader/loader.o $(BUILD)/loader/loadermain.o
	$(shell mkdir -p $(dir $@))
	ld -m elf_i386 -N -e start -static -Ttext 0x1000  $^ -o $@

$(BUILD)/loader/loader.bin: $(BUILD)/loader/loader.out
	objcopy -O binary $^ $@

$(BUILD)/kernel/%.o: $(SRC)/kernel/%.asm
	$(shell mkdir -p $(dir $@))
	nasm -f  elf32 $(DEBUG) $< -o $@

$(BUILD)/kernel/%.o: $(SRC)/kernel/%.c
	$(shell mkdir -p $(dir $@))
	gcc $(CFLAGS) $(DEBUG)  $(INCLUDE) -c $< -o $@

# $^表示所有的依赖文件
#$(BUILD)/kernel/kernel.bin: $(BUILD)/kernel/start.o $(BUILD)/kernel/init.o
#	$(shell mkdir -p $(dir $@))
#	ld -m elf_i386 -static $^ -o $@ -Ttext $(ENTRYPOINT)

$(BUILD)/kernel/kernel.bin: $(BUILD)/kernel/init.o
	$(shell mkdir -p $(dir $@))
	ld -m elf_i386 -nostdlib -T tools/kernel.ld $^ -o $@

$(BUILD)/system.bin: $(BUILD)/kernel/kernel.bin
	objcopy -O binary $< $@


$(BUILD)/system.map: $(BUILD)/kernel/kernel.bin
	nm $< | sort > $@

#$(BUILD)/cqustos.img: $(BUILD)/boot/boot.bin $(BUILD)/boot/loader.bin $(BUILD)/system.bin $(BUILD)/system.map
$(BUILD)/cqustos.img: $(BUILD)/boot/boot.bin $(BUILD)/loader/loader.bin $(BUILD)/kernel/kernel.bin $(BUILD)/system.map
	$(V)dd if=/dev/zero of=$@ count=10000
	$(V)dd if=$(BUILD)/boot/boot.bin of=$@ conv=notrunc
	$(V)dd if=$(BUILD)/loader/loader.bin of=$@ seek=2 conv=notrunc
	$(V)dd if=$(BUILD)/kernel/kernel.bin of=$@ seek=10  conv=notrunc

test: $(BUILD)/cqustos.img

qemu: $(BUILD)/cqustos.img
	$(V)$(QEMU) -no-reboot -parallel stdio -hda $< -serial null

TERMINAL        :=gnome-terminal

debug: $(BUILD)/cqustos.img
	$(V)$(QEMU) -S -s -parallel stdio -hda $< -serial null
#	$(V)sleep 2
#	$(V)$(TERMINAL) -e "gdb -q -tui -x tools/gdbinit"

debug-nox: $(BUILD)/cqustos.img
	$(V)$(QEMU) -S -s -serial mon:stdio -hda $< -nographic

.PHONY: clean
clean:
	rm -rf $(BUILD)
	rm -rf *.img
