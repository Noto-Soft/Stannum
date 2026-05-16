#/usr/bin/env bash
rm -f os.img
mkdir -p build

fasm src/boot.asm build/boot.bin
fasm src/kernel.asm build/kernel.bin
fasm src/serial.asm build/serial.drv
fasm src/pcspk.asm build/pcspk.drv
fasm src/scli.asm build/scli.com
fasm src/hello.asm build/hello.com
fasm src/repeat.asm build/repeat.com
fasm src/tell.asm build/tell.com
fasm src/testsrl.asm build/testsrl.com

touch os.img
truncate -s 1440k os.img
mkfs.fat -n STANNUM -F 12 -f 1 os.img

dd if=build/boot.bin of=os.img count=3 bs=1 conv=notrunc status=none
dd if=build/boot.bin of=os.img seek=72 skip=72 count=440 bs=1 conv=notrunc status=none

mcopy -i os.img build/kernel.bin "::kernel.bin"
mcopy -i os.img build/serial.drv "::serial.drv"
mcopy -i os.img build/pcspk.drv "::pcspk.drv"
mcopy -i os.img build/scli.com "::scli.com"

mcopy -i os.img build/hello.com "::hello.com"
mcopy -i os.img build/repeat.com "::repeat.com"
mcopy -i os.img build/tell.com "::tell.com"
mcopy -i os.img build/testsrl.com "::testsrl.com"

mcopy -i os.img src/reminder.txt "::reminder.txt"
mcopy -i os.img src/woohey.txt "::woohey.txt"

if [[ "$1" == "test" ]]; then
    qemu-system-i386 --drive file=os.img,if=floppy,format=raw -machine pcspk-audiodev=spk -audiodev pa,id=spk
else
    echo "[build.sh] Run \"bash build.sh test\" to build and then boot into qemu (qemu-system-x86 package required)"
fi