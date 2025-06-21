// Assembly example using all required instructions
// The #number before each instruction indicates the instruction line number (address) in memory

#0  loadi  r0, 0x00        // r0 = 0 (zero reference)
#4  loadi  r1, 0x03        // r1 = 3 (loop counter)
#8  loadi  r2, 0x01        // r2 = 1 (increment)
#12 loadi  r3, 0x00        // r3 = 0 (accumulator)
#16 loadi  r6, 0x0F        // r6 = 15 (for shift/rotate)

loop_start:
#20 add    r3, r3, r2      // r3 = r3 + r2

#24 sll    r4, r6, #1      // r4 = r6 << 1 (logical shift left)
#28 srl    r5, r6, #1      // r5 = r6 >> 1 (logical shift right)
#32 sra    r7, r6, #1      // r7 = r6 >>> 1 (arithmetic shift right)
#36 ror    r6, r6, #1      // r6 = r6 rotated right by 1

#40 sub    r1, r1, r2      // r1 = r1 - r2
#44 bne    loop_start, r1, r0 // if r1 != 0, repeat loop (jump to loop_start)

#48 beq    after_block, r1, r0 // if r1 == 0, skip next block

#52 mul    r5, r3, r4      // r5 = r3 * r4
#56 ror    r7, r5, #2      // r7 = r5 rotated right by 2
#60 j      end_program     // jump to end

after_block:
#64 sub    r5, r4, r3      // r5 = r4 - r3
#68 sll    r7, r5, #1      // r7 = r5 << 1 (logical shift left)

end_program:
#72 // ...end of program...