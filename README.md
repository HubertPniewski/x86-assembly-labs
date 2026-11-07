# x86-assembly-labs
MASM (Microsoft Macro Assembler) programs created for university laboratories and for learning purposes. 

## Programs:
### 1. Pythagorean Theorem Calculator (`tw_pitagorasa.asm`)
- **Tech:** 32-bit x86 Assembly (MASM), x87 FPU, Console I/O (`__read` / `__write`)
- **Description:** A program calculating the hypotenuse of a right-angled triangle given two catheti lengths.
  - Reads input from the keyboard and parses ASCII characters into an integer.
  - Computes the sum of squares ($a^2 + b^2$) using standard integer instructions.
  - Uses the x87 FPU coprocessor (`finit`, `fsqrt`) for hardware-level square root calculation.
  - Formats and writes the final result back to the console.

### 2. Number Base Converter (`dec_to_bin_hex.asm`)
- **Tech:** 32-bit x86 Assembly (MASM), Bit manipulation (`bt`, `rol`)
- **Description:** A number base conversion utility that reads a decimal number from the keyboard and outputs its hexadecimal and binary representations:
  - Uses cyclic bit rotation (`rol`) and a decoder lookup table for hex formatting.
  - Utilizes the bit test instruction (`bt`) to extract individual bit states from CPU registers and format them into a binary string.

### 3. C & x86 Assembly Interoperability (`max_abs`)
- **Files:** `max_abs/program.asm`, `max_abs/program1.c`
- **Tech:** C, 32-bit x86 Assembly (MASM), Calling Conventions (`ebp`/`esp`), Bit manipulation (`bt`)
- **Description:** A project showing calling an assembly function from C to find the maximum absolute value in an integer array.
  - Manually sets up the stack frame (`push ebp`, `mov ebp, esp`) to read parameters passed from C (`tabl` pointer and `n` size).
  - Checks the sign bit directly using `bt eax, 31` and handles negative values with `neg`.
  - Loops through the array, tracks the highest absolute value, and returns it via the `eax` register.
