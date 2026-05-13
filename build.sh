rm -f os.img
mkdir -p build

fasm src/boot.asm build/boot.bin
fasm src/kernel.asm build/kernel.bin
fasm src/scli.asm build/scli.com
fasm src/hello.asm build/hello.com
fasm src/repeat.asm build/repeat.com
fasm src/dir.asm build/dir.com
fasm src/tell.asm build/tell.com
fasm src/tsrtest.asm build/tsrtest.com

touch os.img
truncate -s 1440k os.img
mkfs.fat -F 12 -f 1 os.img

dd if=build/boot.bin of=os.img count=3 bs=1 conv=notrunc > /dev/null
dd if=build/boot.bin of=os.img seek=72 skip=72 count=440 bs=1 conv=notrunc > /dev/null
echo "[DD] Wrote bootloader"
mcopy -i os.img build/kernel.bin "::kernel.bin"
mcopy -i os.img build/scli.com "::scli.com"

mcopy -i os.img build/hello.com "::hello.com"
mcopy -i os.img build/repeat.com "::repeat.com"
mcopy -i os.img build/dir.com "::dir.com"
mcopy -i os.img build/tell.com "::tell.com"
mcopy -i os.img build/tsrtest.com "::tsrtest.com"

mcopy -i os.img src/blep.txt "::blep.txt"