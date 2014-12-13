%use altreg

%macro spush 0
    push r7
    push r6
    push r2
    push r10
    push r8
    push r9
    push r3
    push r1
%endmacro

%macro spop 0
    pop r1
    pop r3
    pop r9
    pop r8
    pop r10
    pop r2
    pop r6
    pop r7
%endmacro

%define SYS_READ    0x00
%define SYS_WRITE   0x01
%define SYS_OPEN    0x02
%define SYS_CLOSE   0x03
%define SYS_LSEEK   0x08
%define SYS_EXIT    0x3C

%define STD_IN      0x00
%define STD_OUT     0x01
%define STD_ERR     0x02

%define LSEEK_SET   0x00
%define O_RDONLY    0x00


section .data
    EINVALID_PNG        db 'error: invalid png', 0x0A
    EINVALID_PNG_LEN    equ $-EINVALID_PNG
    EOPEN_PNG           db 'error: unable to open png', 0x0A
    EOPEN_PNG_LEN       equ $-EOPEN_PNG
    USAGE               db 'usage: pngsize <PNG>', 0x0A
    USAGE_LEN           equ $-USAGE

    PNG_HEADER          equ 0x474E5089
    PNG_HEADER_LEN      equ 0x04
    PNG_OFFSET          equ 0x10
    PNG_WH_LEN          equ 0x04

    BUFFER_LEN          equ 0x0A

    NEWLINE             db 0x0A
    SPACE               db 0x20

section .bss
    width resb 0x04
    height resb 0x04
    in_header resb 0x04
    buffer resb 0x0A

section .text
global _start

_start:
    mov r0, [r4]
    cmp r0, 0x02
    jne usage

    mov r7, [r4 + 0x10]
    call sys_open

    cmp r0, 0x00
    jle err_open_png

    mov r7, r0
    call read_png

    xor r7, r7
    mov r7d, [width]
    mov r6, buffer
    mov r2, BUFFER_LEN
    call int_to_str

    mov r7, buffer
    mov r6, BUFFER_LEN
    call sys_write

    mov r7, SPACE
    mov r6, 0x01
    call sys_write

    xor r7, r7
    mov r7d, [height]
    mov r6, buffer
    mov r2, BUFFER_LEN
    call int_to_str

    mov r7, buffer
    mov r6, BUFFER_LEN
    call sys_write

    mov r7, NEWLINE
    mov r6, 0x01
    call sys_write

    mov r7, 0x00
    jmp sys_exit

read_png:
    spush

    mov r6, in_header
    mov r2, PNG_HEADER_LEN
    call sys_read

    cmp r0, PNG_HEADER_LEN
    jne sys_exit

    cmp dword [in_header], PNG_HEADER
    jne err_invalid_png

    mov r6, PNG_OFFSET
    mov r2, LSEEK_SET
    call sys_lseek

    cmp r0, PNG_OFFSET
    jne sys_exit

    mov r6, width
    mov r2, PNG_WH_LEN
    call sys_read

    cmp r0, PNG_WH_LEN
    jne sys_exit

    mov r6, height
    mov r2, PNG_WH_LEN
    call sys_read

    cmp r0, PNG_WH_LEN
    jne sys_exit

    mov r0d, [width]
    bswap r0d
    mov [width], r0d

    mov r0d, [height]
    bswap r0d
    mov [height], r0d

    call sys_close

    spop
    ret

int_to_str:
    spush
    mov r15, r7

    xor r0, r0
    mov r1, r2
    mov r7, r6
    rep stosb

    mov r0, r15
    xor r12, r12
    mov r3, 0x0A
    jmp int_to_str_loop

int_to_str_loop:
    xor r2, r2
    div r3
    add r2, 0x30
    add r2, 0x00
    mov [r6 + r12], r2l
    inc r12
    cmp r0, 0x00
    jne int_to_str_loop
    jmp int_to_str_end

int_to_str_end:
    mov r0d, [r6]
    bswap r0d
    mov [r6], r0d

    spop
    ret

usage:
    mov r7, USAGE
    mov r6, USAGE_LEN
    call sys_write

    mov r7, 0x01
    call sys_exit

err_open_png:
    mov r7, EOPEN_PNG
    mov r6, EOPEN_PNG_LEN
    call sys_write

    call usage


err_invalid_png:
    call sys_close

    mov r7, EINVALID_PNG
    mov r6, EINVALID_PNG_LEN
    call sys_write

    call usage

sys_lseek:
    spush
    mov r0, SYS_LSEEK
    syscall
    spop
    ret

sys_open:
    spush
    mov r6, O_RDONLY
    mov r0, SYS_OPEN
    syscall
    spop
    ret

sys_close:
    spush
    mov r0, SYS_CLOSE
    syscall
    spop
    ret

sys_read:
    spush
    mov r0, SYS_READ
    syscall
    spop
    ret

sys_write:
    spush
    mov r2, r6
    mov r6, r7
    mov r7, STD_OUT
    mov r0, SYS_WRITE
    syscall
    spop
    ret

sys_exit:
    mov r0, SYS_EXIT
    syscall
