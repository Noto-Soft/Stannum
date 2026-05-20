#/usr/bin/env bash
rm -f os.img,other.img
mkdir -p build

fasm src/boot/boot.asm build/boot.bin

fasm src/kernel/kernel.asm build/kernel.bin

fasm src/drivers/high.asm build/high.drv
fasm src/drivers/serial.asm build/serial.dev
fasm src/drivers/pcspk.asm build/pcspk.dev
fasm src/drivers/vga.asm build/vga.dev

fasm src/userspace/scli.asm build/scli.com
fasm src/userspace/hello.asm build/hello.com
fasm src/userspace/write.asm build/write.com
fasm src/userspace/copyf.asm build/copyf.com
fasm src/userspace/beeper.asm build/beeper.com
fasm src/userspace/video12.asm build/video12.com
fasm src/userspace/video13.asm build/video13.com
fasm src/userspace/image.asm build/image.com

fasm src/tunes/mouth.asm build/mouth.tun
fasm src/tunes/scale.asm build/scale.tun
fasm src/tunes/pb95.asm build/pb95.tun
fasm src/tunes/852.asm build/852.tun

# gcc -m16 -ffreestanding -nostdlib -fno-pie -fno-pic -Wl,--oformat=binary -s -o build/ctest.bin src/ctest.c

touch os.img
truncate -s 1440k os.img
mkfs.fat -n STANNUM -F 12 -f 1 os.img

touch other.img
truncate -s 1440k other.img
mkfs.fat -n DATA -F 12 -f 1 other.img

dd if=build/boot.bin of=os.img count=3 bs=1 conv=notrunc status=none
dd if=build/boot.bin of=os.img seek=72 skip=72 count=440 bs=1 conv=notrunc status=none

mcopy -i os.img build/kernel.bin "::kernel.bin"

mcopy -i os.img build/high.drv "::high.drv"
mcopy -i os.img build/serial.dev "::serial.dev"
mcopy -i os.img build/pcspk.dev "::pcspk.dev"
mcopy -i os.img build/vga.dev "::vga.dev"

mcopy -i os.img build/scli.com "::scli.com"
mcopy -i os.img build/hello.com "::hello.com"
mcopy -i os.img build/write.com "::write.com"
mcopy -i os.img build/copyf.com "::copyf.com"

mcopy -i os.img LICENSE "::license.txt"

mcopy -i other.img build/beeper.com "::beeper.com"
mcopy -i other.img build/video12.com "::video12.com"
mcopy -i other.img build/video13.com "::video13.com"
mcopy -i other.img build/image.com "::image.com"

mcopy -i other.img src/userspace/docs/abc.txt "::abc.txt"
mcopy -i other.img spec/extensions.txt "::extens.txt"

mcopy -i other.img build/mouth.tun "::mouth.tun"
mcopy -i other.img build/scale.tun "::scale.tun"
mcopy -i other.img build/pb95.tun "::pb95.tun"
mcopy -i other.img build/852.tun "::852.tun"

mcopy -i other.img assets/079.raw "::079.raw"

if [[ "$1" == "test" ]]; then
    qemu-system-x86_64 -name Stannum -fda os.img -fdb other.img -machine pcspk-audiodev=spk -audiodev pa,id=spk -vga std --enable-kvm -cpu host
else
    echo "[build.sh] Run \"bash build.sh test\" to build and then boot into qemu (qemu-system-x86 package required)"
fi