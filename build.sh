#/usr/bin/env bash
rm -f os.img
mkdir -p build

fasm src/boot/boot.asm build/boot.bin

fasm src/kernel/kernel.asm build/kernel.bin

fasm src/drivers/high.asm build/high.drv
fasm src/drivers/serial.asm build/serial.dev
fasm src/drivers/pcspk.asm build/pcspk.dev
fasm src/drivers/vga.asm build/vga.dev

fasm src/userspace/scli.asm build/scli.com
fasm src/userspace/hello.asm build/hello.com
fasm src/userspace/repeat.asm build/repeat.com
fasm src/userspace/tell.asm build/tell.com
fasm src/userspace/write.asm build/write.com
fasm src/userspace/beeper.asm build/beeper.com
fasm src/userspace/video12.asm build/video12.com
fasm src/userspace/video13.asm build/video13.com

fasm src/tunes/mouth.asm build/mouth.tun
fasm src/tunes/scale.asm build/scale.tun
fasm src/tunes/pb95.asm build/pb95.tun
fasm src/tunes/852.asm build/852.tun

# gcc -m16 -ffreestanding -nostdlib -fno-pie -fno-pic -Wl,--oformat=binary -s -o build/ctest.bin src/ctest.c

touch os.img
truncate -s 1440k os.img
mkfs.fat -n STANNUM -F 12 -f 1 os.img

dd if=build/boot.bin of=os.img count=3 bs=1 conv=notrunc status=none
dd if=build/boot.bin of=os.img seek=72 skip=72 count=440 bs=1 conv=notrunc status=none

mcopy -i os.img build/kernel.bin "::kernel.bin"

mcopy -i os.img build/high.drv "::high.drv"
mcopy -i os.img build/serial.dev "::serial.dev"
mcopy -i os.img build/pcspk.dev "::pcspk.dev"
mcopy -i os.img build/vga.dev "::vga.dev"

mcopy -i os.img build/scli.com "::scli.com"
mcopy -i os.img build/hello.com "::hello.com"
mcopy -i os.img build/repeat.com "::repeat.com"
mcopy -i os.img build/tell.com "::tell.com"
mcopy -i os.img build/write.com "::write.com"
mcopy -i os.img build/beeper.com "::beeper.com"
mcopy -i os.img build/video12.com "::video12.com"
mcopy -i os.img build/video13.com "::video13.com"

mcopy -i os.img src/userspace/docs/reminder.txt "::reminder.txt"
mcopy -i os.img src/userspace/docs/woohey.txt "::woohey.txt"
mcopy -i os.img spec/extensions.txt "::extens.txt"
mcopy -i os.img LICENSE "::license.txt"

mcopy -i os.img build/mouth.tun "::mouth.tun"
mcopy -i os.img build/scale.tun "::scale.tun"
mcopy -i os.img build/pb95.tun "::pb95.tun"
mcopy -i os.img build/852.tun "::852.tun"

if [[ "$1" == "test" ]]; then
    qemu-system-x86_64 -name Stannum --drive file=os.img,if=floppy,format=raw -machine pcspk-audiodev=spk -audiodev pa,id=spk -vga std --enable-kvm
else
    echo "[build.sh] Run \"bash build.sh test\" to build and then boot into qemu (qemu-system-x86 package required)"
fi