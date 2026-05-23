#!/usr/bin/env bash
qemu-system-x86_64 -name Stannum -fda os.img -machine pcspk-audiodev=spk -audiodev pa,id=spk -vga std --enable-kvm -cpu host