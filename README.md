# diff — Line-by-Line Text Comparison in x86-64 Assembly

Simplified `diff`-style utility in x86-64 assembly (AT&T syntax, GNU Assembler). Links against libc (`printf`, `exit`).

## Behavior

- Compares two hardcoded text buffers (`file1`, `file2`) line by line, by position (no realignment / LCS).
- Reports differing lines in classic `diff` normal format:
  ```
  <line>c<line>
  < <file1 line>
  ---
  > <file2 line>
  ```
- Handles unequal line counts (trailing lines on either side).
- End-of-string (`\0`) treated as EOF.

## Flags

| Flag | Effect |
|---|---|
| `-i` | Case-insensitive line comparison |
| `-B` | Ignore blank lines |

Parsed from `argv`; order-independent, matched by 2nd character (`i`/`B`) after a leading `-`.

## Function map

| Function | Role |
|---|---|
| `main` | Parses `-i` / `-B` flags, calls `diff` |
| `diff` | Line-by-line comparison driver, prints differences |
| `nextline` | Returns next-line pointer, current-line start, current-line length (`-1` = EOF) |
| `blank` | Returns 1 if a line is empty/whitespace-only |
| `comparelines` | Byte-by-byte line comparison, optional case-insensitive fold |

## Build

```bash
gcc -no-pie -o diff diff.s
```

## Run

```bash
./diff
./diff -i
./diff -B
./diff -i -B
```

## Limitations

- Input text hardcoded in `.data` (`file1`, `file2`) — flags affect comparison only, not file source.
- Positional line comparison only — no insertion/deletion realignment.
- No usage/help output for invalid flags.
