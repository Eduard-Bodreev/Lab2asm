
    .arch armv8-a

    .data
    .align 2

size:
    .set nx, 3
    .set ny, 3
    .byte ny, nx
matrix:
    .align 3
    .8byte 1, 2, -5
    .8byte 1, 1, 0
    .8byte 8, 3, 1


    .bss
temp_index:
    .align 2
    .skip nx
temp_values:
    .if ny > nx
        .skip 8*ny
    .else
        .skip 8*nx
    .endif

string:
    .skip 21


    .text
    .align 2

    .global _start
    .type _start, %function
_start:
    adr x0, size
    ldrb w1, [x0, #1] // nx
    ldrb w2, [x0]     // ny
    adr x0, matrix

    mov x3, xzr       // x
    adr x5, temp_values
    adr x6, temp_index
    max_rows:
        cmp x3, x2
        beq end_max_rows
        strb w4, [x6, x3] // index[y] = y

        ldr x7, [x0, x3, lsl 3] // max
        mov x4, #1       // y
        mov x8, x3        // matrix index

        max_row:
            cmp x4, x1
            beq end_max_row

            ldr x9, [x0, x8, lsl 3]
            cmp x8, x9
            csel x8, x8, x9, ge // max = max(x8, x9)

            add x8, x8, x1   // i += nx
            add x4, x4, #1   // y += 1
            b max_row
        end_max_row:
        str x7, [x5, x3, lsl 3] // max_arr[y] = max

        add x3, x3, #1   // x += 1
        b max_rows
    end_max_rows:

    sort:
        mov x11, #1 // sorted flag

        mov x3, #1  // index to sort
        swap1:
            cmp x3, x1
            bmi end_swap1

            add x4, x3, #1
            ldr x7, [x5, x3, lsl 3]
            ldr x8, [x5, x4, lsl 3]
            cmp x7, x8
            .ifdef reverse
            bge 10f // x7 >= x8
            .else
            ble 10f // x7 <= x8 : don't swap
            .endif

            // swap 
            str x7, [x5, x4, lsl 3]
            str x8, [x5, x3, lsl 3]
            ldrb w7, [x6, x3]
            ldrb w8, [x6, x4]
            strb w7, [x6, x4]
            strb w8, [x6, x3]
            mov x11, xzr

            10:
            add x3, x3, #2
            b swap1
        end_swap1:

        mov x3, #0  // index to sort
        swap2:
            cmp x3, x1
            bmi end_swap2

            add x4, x3, #1
            ldr x7, [x5, x3, lsl 3]
            ldr x8, [x5, x4, lsl 3]
            cmp x7, x8
            .ifdef reverse
            bge 10f // x7 >= x8
            .else
            ble 10f // x7 <= x8 : don't swap
            .endif

            // swap 
            str x7, [x5, x4, lsl 3]
            str x8, [x5, x3, lsl 3]
            ldrb w7, [x6, x3]
            ldrb w8, [x6, x4]
            strb w7, [x6, x4]
            strb w8, [x6, x3]
            mov x11, xzr

            10:
            add x3, x3, #2
            b swap2
        end_swap2:

        cbz x11, sort // if x11 == 0: break
    sorted:

    // x0: matrix, x1: nx, x2: ny, x3: ..., x4: subs_i
    // x5: temp_values, x6: temp_index
    // x7: sub
    mov x3, xzr
    mov x4, xzr
    substitution:
        cmp x4, x2
        beq finish

        ldrb w7, [x6, x4]
        cmp x4, x7
        beq unit_cycle           // skip unit cycles

        strb w4, [x6, x4] // set to unit cycle (redundant)

        mov x8, x4
        mov x9, xzr
        50:
            cmp x9, x0 // i2 > ny
            beq 51f
            ldr x10, [x0, x8, lsl 3]
            str x10, [x5, x9, lsl 3]
            add x8, x8, x1 // i += nx
            add x9, x9, #1 // i2 += 1
            b 50b
        51:
        mov x8, x4

        cycle:
            cmp x7, x4
            beq end_cycle

            // mov row at `sub` to the free row
            mov x9, x0
            mov x11, xzr
            50:
                cmp x11, x2 // i >= ny
                beq 51f
                ldr x10, [x9, x8, lsl 3]
                str x10, [x9, x7, lsl 3]

                lsl x10, x1, 3
                add x9, x9, x10 // row addr += nx * 8
                add x11, x11, #1
                b 50b
            51:
            mov x8, x7 // x8 = x9 -- the freed row

            ldrh w10, [x6, x7, lsl 1]
            strh w7, [x6, x7, lsl 1] // set to unit cycle
            mov x7, x10
            b cycle
        end_cycle:
        // memcpy

        unit_cycle:
        add x4, x4, #1
        b substitution
    finish:

exit:
    return #0

    .size   _start, (. - _start)
