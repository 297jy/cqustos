
; 给编译器指定物理基地址
[org 0x7c00]

mov ax, 3
int 0x10

mov ax,0
mov dx,ax
mov es,ax
mov ss,ax
mov sp,0x7c00

; 0xb8000 文本显示器的内存区域
mov ax, 0xb800
mov ds, ax
mov byte [0], 'H'

jmp $

; 填充0
times 510 - ($-$$) db 0

; 主引导扇区最后两个字节必须是 0x55 0xaa
db 0x55, 0xaa

