

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

$(BUILD)/boot/%.bin: $(SRC)/boot/%.asm
	$(shell mkdir -p $(dir $@))
	nasm -f bin $< -o $@

$(BUILD)/kernel/%.o: $(SRC)/kernel/%.asm
	$(shell mkdir -p $(dir $@))
	nasm -f elf32 $< -o $@

# $^表示所有的依赖文件
$(BUILD)/kernel/kernel.bin: $(BUILD)/kernel/start.o
	$(shell mkdir -p $(dir $@))
	ld -m elf_i386 -static $^ -o $@ -Ttext $(ENTRYPOINT)

$(BUILD)/system.bin: $(BUILD)/kernel/kernel.bin
	objcopy -O binary $< $@


$(BUILD)/system.map: $(BUILD)/kernel/kernel.bin
	nm $< | sort > $@

$(BUILD)/cqustos.img: $(BUILD)/boot/boot.bin $(BUILD)/boot/loader.bin $(BUILD)/system.bin $(BUILD)/system.map
	$(V)dd if=/dev/zero of=$@ count=10000
	$(V)dd if=$(BUILD)/boot/boot.bin of=$@ conv=notrunc
	$(V)dd if=$(BUILD)/boot/loader.bin of=$@ seek=2 conv=notrunc
	$(V)dd if=$(BUILD)/system.bin of=$@ seek=10 count=200 conv=notrunc

test: $(BUILD)/kernel/kernel.bin

qemu: $(BUILD)/cqustos.img
	$(V)$(QEMU) -no-reboot -parallel stdio -hda $< -serial null

.PHONY: clean
clean:
	rm -rf $(BUILD)
	rm -rf *.img
