#!/usr/bin/env bash
qemu-system-x86_64 -name Stannum -drive file=os.img,if=floppy,format=raw -machine pcspk-audiodev=spk -audiodev pa,id=spk -vga std # --enable-kvm -cpu host
