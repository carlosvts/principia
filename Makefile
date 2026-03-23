# principia/Makefile

TARGET  = x86_64-elf
CC      = $(TARGET)-gcc
AS      = nasm
LD      = $(TARGET)-ld

CFLAGS  = -ffreestanding -fno-stack-protector -fno-pic -mno-red-zone -m64 -O2 -Wall -Wextra -mcmodel=kernel -fno-asynchronous-unwind-tables 
LDFLAGS = -T linker.ld -nostdlib

OBJS = kernel/entry.o kernel/kernel.o

all: principia.iso

kernel/entry.o: kernel/entry.asm
	$(AS) -f elf64 $< -o $@

kernel/kernel.o: kernel/kernel.c
	$(CC) $(CFLAGS) -c $< -o $@

kernel.elf: $(OBJS)
	$(LD) $(LDFLAGS) $(OBJS) -o $@

principia.iso: kernel.elf
	mkdir -p iso_root/boot/limine
	mkdir -p iso_root/EFI/BOOT
	cp kernel.elf          iso_root/boot/principia
	cp limine.conf          iso_root/
	cp limine.conf          iso_root/boot/limine/
	cp limine/limine-bios.sys      iso_root/
	cp limine/limine-bios.sys      iso_root/boot/limine/
	cp limine/limine-bios-cd.bin   iso_root/boot/limine/
	cp limine/limine-uefi-cd.bin   iso_root/boot/limine/
	cp limine/BOOTX64.EFI          iso_root/EFI/BOOT/
	xorriso -as mkisofs \
		-b boot/limine/limine-bios-cd.bin \
		-no-emul-boot -boot-load-size 4 -boot-info-table \
		--efi-boot boot/limine/limine-uefi-cd.bin \
		-efi-boot-part --efi-boot-image --protective-msdos-label \
		iso_root -o principia.iso
	./limine/limine bios-install principia.iso

run:
	qemu-system-x86_64 -drive format=raw,file=principia.iso -m 256M

clean:
	rm -rf iso_root kernel/*.o kernel.elf principia.iso
