#/usr/bin/env bash
rm -f os.img
mkdir -p build

fasm src/boot.asm build/boot.bin
fasm src/kernel.asm build/kernel.bin

fasm src/high.asm build/high.drv
fasm src/serial.asm build/serial.dev
fasm src/pcspk.asm build/pcspk.dev
fasm src/vga.asm build/vga.dev

fasm src/scli.asm build/scli.com
fasm src/hello.asm build/hello.com
fasm src/repeat.asm build/repeat.com
fasm src/tell.asm build/tell.com
fasm src/write.asm build/write.com
fasm src/beeper.asm build/beeper.com
fasm src/video.asm build/video.com

fasm src/tunes/mouth.asm build/mouth.tun
fasm src/tunes/scale.asm build/scale.tun

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
mcopy -i os.img build/video.com "::video.com"

mcopy -i os.img src/reminder.txt "::reminder.txt"
mcopy -i os.img src/woohey.txt "::woohey.txt"
mcopy -i os.img spec/extensions.txt "::extens.txt"

mcopy -i os.img build/mouth.tun "::mouth.tun"
mcopy -i os.img build/scale.tun "::scale.tun"

if [[ "$1" == "test" ]]; then
    qemu-system-x86_64 -name Stannum --drive file=os.img,if=floppy,format=raw -machine pcspk-audiodev=spk -audiodev pa,id=spk -vga std
else
    echo "[build.sh] Run \"bash build.sh test\" to build and then boot into qemu (qemu-system-x86 package required)"
fi