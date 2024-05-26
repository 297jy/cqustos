[org 0x7c00]

;设置屏幕为文本模式，清楚屏幕
mov ax,3
int 0x10

; 初始化段寄存器
mov ax,0
mov ds,ax
mov es,ax
mov ss,ax
mov sp,0x7c00

mov si, booting
call print

mov edi, 0x1000; 读取的目标内存,参考实模式的内存布局
mov ecx, 2; 起始扇区
mov bl, 4;扇区数量
call read_disk

;cmp word[0x1000],0x55aa
;jnz error
;jmp 0:0x1002
jmp 0:0x1000

jmp $

read_disk:
    ; 设置读写扇区的数量
    mov dx, 0x1f2
    mov al, bl
    out dx, al

    inc dx; 0x1f3
    mov al, cl;起始扇区的前八位
    out dx, al

    inc dx; 0x1f4
    shr ecx, 8
    mov al, cl;起始扇区的中八位
    out dx, al

    inc dx;0x1f5
    shr ecx, 8
    mov al,cl
    out dx,al

    inc dx;0x1f6
    shr ecx,8
    and cl, 0b1111;将高四位置为0
    
    mov al, 0b1110_0000;
    or al, cl
    out dx, al; 主盘 -LBA 模式

    inc dx;0x1f7
    mov al, 0x20
    out dx,al

    xor ecx, ecx
    mov cl,bl; 得到读写扇区的数量
    .read:
        push cx
        call .waits;等待数据准备完毕
        call .reads;读取一个扇区
        pop cx
        loop .read
        ret

    .waits:
        mov dx, 0x1f7
        .check:
            in al, dx
            jmp $+2;直接跳转到下一行
            jmp $+2;一点点延迟
            jmp $+2;
            and al, 0b1000_1000
            cmp al, 0b0000_1000
            jnz .check
        ret
    
    .reads:
        mov dx, 0x1f0
        mov cx, 256;一个扇区是 256
        .readw:
            in ax, dx
            jmp $+2;直接跳转到下一行
            jmp $+2;一点点延迟
            jmp $+2;
            mov [edi], ax
            add edi, 2
            loop .readw
        ret


print:
    mov ah, 0x0e
.next:
    mov al, [si]
    cmp al, 0
    jz .done
    int 0x10
    inc si
    jmp .next
.done:
    ret

booting:
    db "Booting Onix...", 10, 13, 0;

error:
    mov si, .msg
    call print
    hlt;让cpu停止
    jmp $
    .msg db "Booting Error!!!",10,13,0



;填充0
times 510 - ($ - $$) db 0

;主引导扇区的最后两个字节
db 0x55, 0xaa

;nasm -f bin boot.asm -o boot.bin
