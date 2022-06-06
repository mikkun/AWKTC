# AWKTC

![GitHub top language](https://img.shields.io/github/languages/top/mikkun/AWKTC)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/mikkun/AWKTC)
![GitHub license](https://img.shields.io/github/license/mikkun/AWKTC)

> :joystick: **A**WKTC is **W**orkable **K**lutzy **T**ime-wasting **C**ommand

## Description

**AWKTC** is a Tetris-like tile-matching puzzle game written in AWK.

![AWKTC screenshot (width: 12)](./md-images/screenshot-width12.png)

## Requirements

- `gawk` or `nawk`
- [GNU coreutils](https://www.gnu.org/software/coreutils/) or equivalent BSD command (`dd`, `echo`, `sleep`, `stty`)

## Installation

```shell
git clone https://github.com/mikkun/AWKTC.git
```

## How to Play

### Running the Game

```shell
cd /path/to/AWKTC
./awktc.awk
```

### Controls

- <kbd>a</kbd>: Move left
- <kbd>d</kbd>: Move right
- <kbd>k</kbd>: Rotate left
- <kbd>l</kbd>: Rotate right
- <kbd>s</kbd>: Fall faster
- <kbd>p</kbd>: Pause
- <kbd>q</kbd>: Quit

### Beneficial Item

- ![Black piece](./md-images/special_piece.png) - **Special Piece** - Destroys horizontal lines even if they have gaps of blocks.

### All Clear Bonus

If you clear all the blocks, then you will get an "All Clear Bonus".

## Changing the Playfield Width

You can change the playfield width between 4 and 24 cells. By default, the playfield width is 12 cells.

### Example Minimum Width

```shell
./awktc.awk 4
```

![AWKTC screenshot (width: 4)](./md-images/screenshot-width04.png)

### Example Maximum Width

```shell
./awktc.awk 24
```

![AWKTC screenshot (width: 24)](./md-images/screenshot-width24.png)

## License

[MIT License](./LICENSE)

## Author

[KUSANAGI Mitsuhisa](https://github.com/mikkun)
