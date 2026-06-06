# push_swap_tester

*This tester has been created as part of the 42 curriculum by mide-fre*

A bash tester for the **push_swap** project at 42 school, by **mide-fre** @ 42Porto — [@mdfpva](https://github.com/mdfpva) on GitHub.

It automatically compiles the project, runs all mandatory and bonus evaluation tests, and cleans up — printing a clear `[OK]` in green or `[KO]` in red for every test.

---

## Repository contents

```
push_swap_tester/
├── push_swap_tester.sh   # The tester script
├── checker_linux         # Official 42 checker binary (Linux x86_64)
└── README.md
```

---

## Requirements

- Linux x86_64
- `bash`
- `make` and `gcc` (to compile the project under test)
- `shuf` (standard on most Linux distros — part of `coreutils`)
- `norminette` (optional — skipped automatically if not installed)

---

## Installation

Clone this repository **directly inside the root of your push_swap project**:

```bash
cd your_push_swap
git clone https://github.com/mdfpva/push_swap_tester.git
```

Your project directory should look like this:

```
your_push_swap/
├── push_swap_tester/
│   ├── push_swap_tester.sh
│   ├── checker_linux
│   └── README.md
├── Makefile
├── push_swap.h  (or equivalent)
└── src/
    └── ...
```

---

## Usage

```bash
cd your_push_swap/push_swap_tester
chmod +x push_swap_tester.sh checker_linux
./push_swap_tester.sh
```

That's it. The script automatically detects the project in the parent folder and handles everything — no arguments needed.

---

## Quick one-liner

If you just want to run the tests without keeping the tester around, paste this single line into your terminal from the **root of your push_swap project**:

```bash
clear && git clone https://github.com/mdfpva/push_swap_tester.git && chmod +x push_swap_tester/push_swap_tester.sh push_swap_tester/checker_linux && push_swap_tester/push_swap_tester.sh; rm -rf push_swap_tester
```

This will: clear the terminal → clone the tester → run all tests → delete the cloned folder.

---

## What the tester does

The script follows the exact order of the official 42 evaluation sheet.

### 1 — Build

| Step | What happens |
|------|-------------|
| `make` | Compiles the project. If it fails, the tester stops immediately. |
| `make bonus` | Compiles the bonus `checker` executable (failure is non-fatal). |
| `make clean` | Removes intermediate object files. |

### 2 — Makefile verification

Checks that all required rules exist in the Makefile (`all`, `clean`, `fclean`, `re`) and that the compilation flags `-Wall -Wextra -Werror` are present.

### 3 — Norminette

Runs `norminette .` on the entire project and reports any style errors. Skipped automatically if `norminette` is not installed.

### 4 — Error management

Tests that `push_swap` handles bad input correctly:

| Input | Expected behaviour |
|-------|--------------------|
| Non-numeric argument (`abc`) | Prints `Error\n` to stderr |
| Duplicate number (`1 2 1`) | Prints `Error\n` to stderr |
| Value greater than MAXINT (`2147483648`) | Prints `Error\n` to stderr |
| No arguments | No output, clean exit |

### 5 — Strategy flags

Tests each sorting strategy flag with `5 4 3 2 1` and verifies the output sorts correctly via `checker_linux`:

- `--simple`
- `--medium`
- `--complex`
- `--adaptive`
- No flag (should default to adaptive behaviour)

### 6 — Identity tests (already sorted inputs)

Verifies that `push_swap` produces **no output** when the input is already sorted:

- `42`
- `2 3`
- `0 1 2 3`
- `0 1 2 3 4 5 6 7 8 9`

### 7 — Small inputs (3 numbers)

Tests correctness and operation count for 3-number inputs:

| Input | Threshold |
|-------|-----------|
| `2 1 0` | ≤ 3 ops excellent, ≤ 5 acceptable |
| `0 2 1` | ≤ 3 ops excellent, ≤ 5 acceptable |
| `1 0 2` | ≤ 3 ops excellent, ≤ 5 acceptable |

### 8 — Medium inputs (5 numbers)

Tests correctness and operation count for 5-number inputs:

| Input | Threshold |
|-------|-----------|
| `1 5 2 4 3` | ≤ 12 ops good, ≤ 15 acceptable |
| `5 1 4 2 3` | ≤ 12 ops good, ≤ 15 acceptable |
| `3 5 1 4 2` | ≤ 12 ops good, ≤ 15 acceptable |

### 9 — Benchmark mode

Tests the `--bench` flag:

- Verifies that sorting instructions appear on **stdout**
- Verifies that benchmark stats appear on **stderr**
- Checks that the output contains a **disorder percentage**
- Checks that the output contains an **operation count**
- Prints the disorder value for a sorted input (`1 2 3 4 5` → expected ~`0.00%`) and a reverse-sorted input (`5 4 3 2 1` → expected ~`100.00%`) as informational notes

### 10 — Large inputs (100 numbers)

Runs **2 random tests** with 100 numbers drawn from `shuf -i 1-500 -n 100`:

| Operations | Rating |
|-----------|--------|
| < 700 | Excellent |
| < 1500 | Good |
| < 2000 | Acceptable |
| ≥ 2000 | KO (too slow) |

### 11 — Strategy comparison (50 numbers)

Runs the same 50 random numbers through `--simple`, `--medium`, and `--complex` and reports the operation count for each — useful to visually confirm that more complex strategies are more efficient.

### 12 — Very large inputs (500 numbers)

Runs **2 random tests** with 500 numbers drawn from `shuf -i 1-1000 -n 500`:

| Operations | Rating |
|-----------|--------|
| < 5500 | Excellent |
| < 8000 | Good |
| < 12000 | Acceptable |
| ≥ 12000 | KO (too slow) |

### 13 — Bonus: checker error management

Only runs if `./checker` exists (built by `make bonus`). Tests that the bonus checker handles all error cases:

- Non-numeric argument → `Error\n` on stderr
- Duplicate argument → `Error\n` on stderr
- Value > MAXINT → `Error\n` on stderr
- No arguments → no output
- Invalid instruction during instruction phase → `Error\n` on stderr
- Instruction with leading/trailing spaces → `Error\n` on stderr

### 14 — Bonus: checker false tests

Verifies that the checker correctly outputs `KO` when a valid instruction list does **not** sort the stack:

- `[sa, pb, rrr]` on `0 9 1 8 2 7 3 6 4 5` → expected `KO`

### 15 — Bonus: checker correct tests

Verifies that the checker correctly outputs `OK` when a valid instruction list sorts the stack:

- No instructions on `0 1 2` → expected `OK`
- `[pb, ra, pb, ra, sa, ra, pa, pa]` on `0 9 1 8 2` → expected `OK`

### 16 — Final cleanup

Runs `make fclean` to leave the project directory clean after testing.

---

## Output format

```
╔══════════════════════════════════════════╗
║       push_swap TESTER — 42 Porto        ║
╚══════════════════════════════════════════╝

▶ BUILD
  »  A correr 'make'...
  [OK]  make → push_swap compilado com sucesso
  ...

▶ GESTÃO DE ERROS
  [OK]  Parâmetro não numérico → 'Error\n' no stderr
  [KO]  Parâmetro duplicado → esperado 'Error\n' no stderr
  ...

╔══════════════════════════════════════════╗
║              RESULTADO FINAL             ║
╠══════════════════════════════════════════╣
║  OK: 38 / 42  |  KO: 4 / 42             ║
╚══════════════════════════════════════════╝
```

- `[OK]` in **green** — test passed
- `[KO]` in **red** — test failed
- `NOTE:` in **yellow** — informational, not a pass/fail

---

## Notes

- If `checker_linux` is not present, all tests that require it are skipped gracefully.
- If `./checker` (bonus) is not present, the bonus section is skipped entirely.
- The large and very large input tests use `shuf` to generate random numbers, so results vary between runs — this is expected.
- The tester must be run from **inside the `push_swap_tester/` folder**, which should be cloned into the root of your push_swap project.
