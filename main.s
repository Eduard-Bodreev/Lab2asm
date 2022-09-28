
    .arch armv8-a

    .data

    .balign 8 // байт
matrix:
    .8byte 1, 2, -5
    .8byte 1, 1, 0
    .8byte 8, 3, 1

size:
    .set cols, 3 // #define cols = 3
    .set rows, 3 // #define rows = 3
    .byte rows, cols // byte size[2] = {rows, cols};

    .bss
    .balign 8
temp_values:
    .if cols > rows // ny > nx
        .skip 8*cols // выделение памяти для массива при сортировке
    .else
        .skip 8*rows
    .endif
temp_index:
    .skip cols+1

    .text
    .balign 4

    .global _start
    .type _start, %function
_start:
    adr x0, size
    ldrb w1, [x0]     // загружаем size[0] в w1
    ldrb w2, [x0, #1] // загружаем size[1] в w1
    adr x0, matrix // адрес матрицы

    mov x3, xzr       // столбец = 0
    adr x5, temp_values
    adr x6, temp_index
    
    sum_cols:
        cmp x3, x2 // сравниваем х3 и х2 --- столбец < cols
        beq end_sum_cols // branch equal - если i == cols то перехожу в end_sum_cols
        strb w3, [x6, x3] // index[x] = x // записываю *(х6 + х3) = w3 

        ldr x7, [x0, x3, lsl 3] // sum // загружаю в х7 из х0+х3*2^3 -- matrix[строка]
        mov x4, #1       // столбец cols
        add x8, x3, x2   // matrix index = x + cols

        // максимум в столбце
        sum_col:
            cmp x4, x1 // столбец < cols
            beq end_sum_col // если столбец == cols, переход к end_sum_col 

            ldr x9, [x0, x8, lsl 3] // x9 = *(x0 + x8*2^3)
            add x7, x7, x9 

            add x8, x8, x2   // i += cols
            add x4, x4, #1   // y += 1
            b sum_col
        end_sum_col:
        str x7, [x5, x3, lsl 3] // sum_arr[x] = sum (x5 +x3*2^3)

        add x3, x3, #1   // x += 1
        b sum_cols
    end_sum_cols:

    // https://formal.kastel.kit.edu/ulbrich/verifythis2017/challenge1.pdf
    sub x2, x2, 1
    mov x4, #0  // index to sort
    sort:
        cmp x4, x2
        bge sorted // index == cols
    // загружаем два соседних элемента
        ldr x8, [x5, x4, lsl 3] // a
        ldrb w10, [x6, x4]      // a_index
        add x12, x4, 1
        ldr x9, [x5, x12, lsl 3] // b
        ldrb w11, [x6, x12]      // b_index

        cmp x8, x9 // сравниваем
        .ifdef reverse // флаг при компиляции для сортировки по убыванию
        ble 1f // if a > b
        .else
        bge 1f // if a < b
        .endif
            // swap a and b
            mov x12, x8
            mov x8, x9
            mov x9, x12
            mov x12, x10
            mov x10, x11
            mov x11, x12
        1:

        sub x3, x4, #1 // j = i - 1
        shift_a:
            cmp x3, #0 // j >= 0
            bmi insert_a

            ldr x7, [x5, x3, lsl 3]
            cmp x7, x8
            .ifdef reverse
            bge insert_a // x7 >= x8
            .else
            ble insert_a // x7 <= x8 : insert x8 after x3
            .endif

            // move [x3] to [x3 + 2]
            add x12, x3, #2
            str x7, [x5, x12, lsl 3]
            ldrb w7, [x6, x3]
            strb w7, [x6, x12]

            sub x3, x3, #1 // j -= 1
            b shift_a
        insert_a:
        // store a to [j+2]
        add x12, x3, #2
        str x8, [x5, x12, lsl 3]
        strb w10, [x6, x12]

        shift_b:
            cmp x3, #0 // j >= 0
            bmi insert_b

            ldr x7, [x5, x3, lsl 3]
            cmp x7, x9
            .ifdef reverse
            bge insert_b // x7 >= x9
            .else
            ble insert_b // x7 <= x9 : insert x9 after x3
            .endif

            // move [x3] to [x3 + 1]
            add x12, x3, #1
            str x7, [x5, x12, lsl 3]
            ldrb w7, [x6, x3]
            strb w7, [x6, x12]

            sub x3, x3, #1 // j -= 1
            b shift_b
        insert_b:
        // store b to [j+1]
        add x12, x3, #1
        str x9, [x5, x12, lsl 3]
        strb w11, [x6, x12]

        add x4, x4, #2 // i += 2
        b sort
    sorted:

    cmp x4, x2
    bne 1f // sort last element if cols is odd
        ldr x8, [x5, x4, lsl 3]  // a
        ldrb w10, [x6, x4] // a_index

        sub x3, x4, #1 // j = i - 1
        shift_last:
            cmp x3, #0 // j >= 0
            bmi insert_last

            ldr x7, [x5, x3, lsl 3]
            cmp x7, x8
            .ifdef reverse
            bge insert_last // x7 >= x8
            .else
            ble insert_last // x7 <= x8 : insert x8 after x3
            .endif

            // move [x3] to [x3 + 1]
            add x12, x3, #1
            str x7, [x5, x12, lsl 3]
            ldrb w7, [x6, x3]
            strb w7, [x6, x12]

            sub x3, x3, #1 // j -= 1
            b shift_last
        insert_last:
        // store b to [j+1]
        add x3, x3, #1
        str x8, [x5, x3, lsl 3]
        strb w10, [x6, x3]
    1:

    add x2, x2, 1

    // x0: matrix, x1: cols, x2: rows, x3: ..., x4: i
    // x5: temp_values, x6: temp_index
    // x7: sub
    mov x3, 0
    mov x4, 0
    substitution:
        cmp x4, x2 
        beq finish

        ldrb w7, [x6, x4]
        cmp x4, x7
        beq unit_cycle           // пропускаем единичные циклы

        strb w4, [x6, x4] // ставим единичный цикл (unnecessary)

        mov x8, x4 // копируем первый столбец цикла во временный массив
        mov x9, 0 // i2
        50:
            cmp x9, x1 // i2 >= rows
            beq 51f
            ldr x10, [x0, x8, lsl 3]
            str x10, [x5, x9, lsl 3] // temp[i2] = matrix[i]
            add x8, x8, x2 // i += cols
            add x9, x9, #1 // i2 += 1
            b 50b
        51:
        mov x8, x4
// идем по циклу и копируем текущий столбец в предыдущий
        cycle:
            cmp x7, x4
            beq end_cycle

            // mov row at `sub` to the free row
            mov x9, x0
            mov x11, 0
            50:
                cmp x11, x1 // i >= rows
                beq 51f
                ldr x10, [x9, x7, lsl 3]
                str x10, [x9, x8, lsl 3]

                lsl x10, x2, 3
                add x9, x9, x10 // row addr += cols * 8
                add x11, x11, #1
                b 50b
            51:
            mov x8, x7 // x8 = x9 -- the freed row

            ldrb w10, [x6, x7]
            strb w7, [x6, x7] // ставим единичный цикл чтобы потом пропустить
            mov x7, x10
            b cycle
        end_cycle:

        // копируем временный массив в последний столбец
        mov x9, xzr
        50:
            cmp x9, x1 // i2 >= rows
            beq 51f
            ldr x10, [x5, x9, lsl 3]
            str x10, [x0, x8, lsl 3]
            add x8, x8, x2 // i += cols
            add x9, x9, #1 // i2 += 1
            b 50b
        51:

        unit_cycle:
        add x4, x4, #1
        b substitution
    finish:

exit:
    mov x0, #0
    mov x8, #93
    svc #0

    .size   _start, (. - _start)
