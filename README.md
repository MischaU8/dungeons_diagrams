# Dungeons & Diagrams Solver

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
![Stability: experimental](https://img.shields.io/badge/stability-experimental-orange.svg)

## Building & Testing

### Prerequisites

* A recent version of Nim
  * We use version 1.2.6 of https://nim-lang.org/
  * Follow the Nim installation instructions or use [choosenim](https://github.com/dom96/choosenim) to manage your Nim versions
* treeform's [vmath](https://github.com/treeform/vmath) (installed via nimble)

### Build & Install

We use [Nimble](https://github.com/nim-lang/nimble) to manage dependencies and run tests.

To build the solver just execute:

```bash
nimble build
```

### Usage

Run the solver with one (or more) of the dungeon files as command line argument:

```bash
./solver data/01_brightleaf_iron_mine.txt
```

Output:
```
Loading data/01_brightleaf_iron_mine.txt
Starting grid:
  | 1 4 2 7 0 4 4 4
--------------------
3 | . . . . . . . .
2 | . . . . . . . M
5 | . . M . . . . .
3 | . . . . . . . M
4 | . . . . . . . .
1 | . T . . . . . M
4 | . . . . . . . .
4 | . . . . . . . M

Solution:
  | 1 4 2 7 0 4 4 4
--------------------
3 |           # # #
2 |   #   #       M
5 |   # M #   # # #
3 |   # # #       M
4 |       #   # # #
1 |   T   #       M
4 |       #   # # #
4 | # # # #       M

data/01_brightleaf_iron_mine.txt
Solved: true
cpuTime: 0.001857
False positives: 0
```

## License

Licensed under the MIT license: [LICENSE](LICENSE) or http://opensource.org/licenses/MIT
