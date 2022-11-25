#!/usr/bin/awk -f

# Name    : awktc.awk
# Purpose : AWKTC is Workable Klutzy Time-wasting Command
#
# Author  : KUSANAGI Mitsuhisa <mikkun@mbg.nifty.com>
# License : MIT License

# Usage : ./awktc.awk [width]

BEGIN {
    DEFAULT_INPUT_W = 12
    DEFAULT_INPUT_H = 20
    MIN_INPUT_W     = 4
    MAX_INPUT_W     = 24
    BORDER_W = 2
    BORDER_H = 2

    MAX_NEXT_LEVEL_EXP = 999
    MAX_LEVEL = 99
    MAX_LINES = 999999
    MAX_SCORE = 999999
    SCORE_UNIT = 10

    LEVEL_UNIT = 2
    INITIAL_SKIP = 10
    MIN_SKIP     = 2
    SKIP_STEP    = 1

    PIECE_W = 4
    PIECE_H = 4
    PIECE_DATA_LEN = 8
    PIECE_DATA[0] = "0000010001110000" # J: Red
    PIECE_DATA[1] = "0000002022200000" # L: Green
    PIECE_DATA[2] = "0000003303300000" # S: Yellow
    PIECE_DATA[3] = "0000440004400000" # Z: Blue
    PIECE_DATA[4] = "0000555500000000" # I: Magenta
    PIECE_DATA[5] = "0000060066600000" # T: Cyan
    PIECE_DATA[6] = "0000077007700000" # O: White
    PIECE_DATA[7] = "0000088000000000" # Special piece

    UI_TEXTS_LEN = 22
    UI_TEXTS[0]  =        "                      "
    UI_TEXTS[1]  = "  \033[7m                    \033[0m"
    UI_TEXTS[2]  = "  \033[7m  SCORE  :          \033[0m"
    UI_TEXTS[3]  = "  \033[7m  LINES  :          \033[0m"
    UI_TEXTS[4]  = "  \033[7m  LEVEL  :          \033[0m"
    UI_TEXTS[5]  = "  \033[7m                    \033[0m"
    UI_TEXTS[6]  =        "                      "
    UI_TEXTS[7]  = "  \033[7m                    \033[0m"
    UI_TEXTS[8]  = "  \033[7m  NEXT :            \033[0m"
    UI_TEXTS[9]  = "  \033[7m                    \033[0m"
    UI_TEXTS[10] = "  \033[7m                    \033[0m"
    UI_TEXTS[11] =        "                      "
    UI_TEXTS[12] = "  \033[7m                    \033[0m"
    UI_TEXTS[13] = "  \033[7m  A : MOVE LEFT     \033[0m"
    UI_TEXTS[14] = "  \033[7m  D : MOVE RIGHT    \033[0m"
    UI_TEXTS[15] = "  \033[7m  K : ROTATE LEFT   \033[0m"
    UI_TEXTS[16] = "  \033[7m  L : ROTATE RIGHT  \033[0m"
    UI_TEXTS[17] = "  \033[7m  S : FALL FASTER   \033[0m"
    UI_TEXTS[18] = "  \033[7m  P : PAUSE         \033[0m"
    UI_TEXTS[19] = "  \033[7m  Q : QUIT          \033[0m"
    UI_TEXTS[20] = "  \033[7m                    \033[0m"
    UI_TEXTS[21] =        "                      "

    DELAY_SEC = 0.1
    READING_KEY_CMD \
        = "((while :; do echo ''; sleep " DELAY_SEC "; done) &"       \
          " (while :; do echo $(dd bs=1 count=1 conv=lcase); done)) " \
          "2> /dev/null"

    error_message = ""
    if (system("sleep 0.1 2> /dev/null")) {
        error_message = "'sleep' does not support floating point numbers"
        prog_name = ENVIRON["_"]
        sub(/^.*\//, "", prog_name)
        print prog_name ": " error_message > "/dev/stderr"
        exit 1
    }

    input_w = ARGC < 2 ? DEFAULT_INPUT_W : int(ARGV[ARGC - 1])
    input_w = input_w < MIN_INPUT_W ? MIN_INPUT_W : input_w
    input_w = input_w > MAX_INPUT_W ? MAX_INPUT_W : input_w
    field_w = input_w         + BORDER_W
    field_h = DEFAULT_INPUT_H + BORDER_H + PIECE_H
    initial_x = int((field_w - PIECE_W) / 2)
    initial_y = PIECE_H

    srand()
    printf("\033[?25l")
    printf("\033[1;1H")
    printf("\033[2J")

    stty_cmd = "stty -g"
    stty_cmd | getline prev_term_settings
    close(stty_cmd)
    system("stty raw -echo")

    item_interval = input_w
    level = 0
    lines = 0
    score = 0
    skip_limit = INITIAL_SKIP
    level_up()

    piece_count = 1
    init_field()
    get_next_piece()
    get_curr_piece()
    get_next_piece()

    is_paused = 0
    skip_count = 0

    while (1) {
        READING_KEY_CMD | getline key

        if (is_paused) {
            if (key == "q") { exit 0        }
            else if (key == "p") { is_paused = 0 }
            continue
        }
        else if (key == "q") { exit 0 }
        else if (key == "p") {
            is_paused = 1
            print_message(" PAUSED ", 9)
            continue
        }
        else if (key == "a") {
            curr_piece_x -= 1
            if (has_collision()) { curr_piece_x += 1 }
        }
        else if (key == "d") {
            curr_piece_x += 1
            if (has_collision()) { curr_piece_x -= 1 }
        }
        else if (key == "s") {
            curr_piece_y += 1
            score += 1
            if (has_collision()) {
                curr_piece_y -= 1
                score -= 1
            }
        }
        else if (key == "k") {
            rotate_left()
            if (has_collision()) { rotate_right() }
        }
        else if (key == "l") {
            rotate_right()
            if (has_collision()) { rotate_left() }
        }
        if (key == "" && skip_count >= skip_limit) {
            curr_piece_y += 1
            if (has_collision()) {
                curr_piece_y -= 1
                set_curr_piece()
                update_field()
                get_curr_piece()
                get_next_piece()
            }
            skip_count = 0
        }
        else {
            skip_count += 1
        }

        if (has_collision()) { exit 0 }

        set_curr_piece()
        draw_field()
        clear_curr_piece()
    }
}

END {
    if (error_message) {
        close("/dev/stderr")
        exit 1
    }

    set_curr_piece()
    draw_field()
    print_message(" GAME OVER! ", 9)
    print_message(" PRESS ANY KEY. ", 10)

    printf("\033[2E")
    close(READING_KEY_CMD)
    system("stty " prev_term_settings)

    printf("\033[%d;1H", field_h - PIECE_H + 1)
    printf("\033[?25h")
}

function init_field(    x, y) {
    for (y = 0; y < field_h; y++) {
        for (x = 0; x < field_w; x++) {
            if ( x == 0           \
              || x == field_w - 1 \
              || y <= PIECE_H     \
              || y == field_h - 1 ) {
                field_data[x, y] = 9
            }
            else {
                field_data[x, y] = 0
            }
        }
    }
    for (y = 1; y <= PIECE_H; y++) {
        for (x = initial_x; x < initial_x + PIECE_W; x++) {
            field_data[x, y] = 0
        }
    }
}

function level_up() {
    level += 1
    level = level > MAX_LEVEL ? MAX_LEVEL : level
    item_interval = input_w * (int((level - 1) / LEVEL_UNIT) + 1)
    next_level_exp = (PIECE_H + 1) * level
    next_level_exp = next_level_exp > MAX_NEXT_LEVEL_EXP \
                   ? MAX_NEXT_LEVEL_EXP                  \
                   : next_level_exp
    curr_level_exp = 0
    skip_limit = INITIAL_SKIP - int((level - 1) / LEVEL_UNIT) * SKIP_STEP
    skip_limit = skip_limit < MIN_SKIP ? MIN_SKIP : skip_limit
}

function _delete_line(target_y,    x, y) {
    for (y = target_y; y > PIECE_H - 1; y--) {
        for (x = 1; x < field_w - 1; x++) {
            field_data[x, y] = field_data[x, y - 1]
        }
    }
    for (x = 1; x < field_w - 1; x++) {
        if (field_data[x, PIECE_H + 1] == 9) {
            field_data[x, PIECE_H + 1] = 0
        }
    }
}

function _is_all_clear(    x) {
    for (x = 1; x < field_w - 1; x++) {
        if (field_data[x, field_h - BORDER_H] != 0) {
            return 0
        }
    }
    return 1
}

function update_field(    deleted_lines, is_line_created, points, i, x, y) {
    deleted_lines = 0
    for (i = 0; i < PIECE_H; i++) {
        for (y = field_h - BORDER_H; y > PIECE_H; y--) {
            is_line_created = 1
            for (x = 1; x < field_w - 1; x++) {
                if (field_data[x, y] == 8) {
                    is_line_created = 1
                    break
                }
                is_line_created *= field_data[x, y]
            }
            if (is_line_created) {
                _delete_line(y)
                deleted_lines += 1
            }
        }
    }
    if (deleted_lines > 0) {
        points = input_w * deleted_lines ^ 2 * SCORE_UNIT * level
        curr_level_exp += deleted_lines * 2                  \
                              + int(deleted_lines / PIECE_H) \
                              - 1
        lines += deleted_lines
        score += _is_all_clear() ? points * 10 : points
        if (curr_level_exp >= next_level_exp) {
            level_up()
        }
    }
}

function _build_info() {
    return sprintf("\033[3;15H\033[7m%6d\033[0m", score) \
           sprintf("\033[4;15H\033[7m%6d\033[0m", lines) \
           sprintf("\033[5;19H\033[7m%2d\033[0m", level)
}

function _build_next_piece(row, column,    pixmap, x, y) {
    for (y = 0; y < PIECE_H; y++) {
        pixmap = pixmap sprintf("\033[%d;%dH", row + y, column)
        for (x = 0; x < PIECE_W; x++) {
            if (next_piece_data[x, y] == 0) {
                pixmap = pixmap sprintf("\033[7m  \033[0m")
            }
            else if (next_piece_data[x, y] == 8) {
                pixmap = pixmap sprintf("\033[31;40m[]\033[0m")
            }
            else {
                pixmap = pixmap sprintf("\033[30;4%dm[]\033[0m", \
                                        next_piece_data[x, y])
            }
        }
    }
    return pixmap
}

function draw_field(    buffer, x, y) {
    for (y = PIECE_H; y < field_h; y++) {
        buffer = buffer sprintf("\033[%d;1H", y - PIECE_H + 1)
        if (y - PIECE_H < UI_TEXTS_LEN) {
            buffer = buffer sprintf("%s", UI_TEXTS[y - PIECE_H])
        }
        else {
            buffer = buffer sprintf("                      ")
        }
        for (x = 0; x < field_w; x++) {
            if (field_data[x, y] == 0) {
                buffer = buffer sprintf("\033[7m .\033[0m")
            }
            else if (field_data[x, y] == 8) {
                buffer = buffer sprintf("\033[31;40m[]\033[0m")
            }
            else if (field_data[x, y] == 9) {
                buffer = buffer sprintf("  ")
            }
            else {
                buffer = buffer sprintf("\033[30;4%dm[]\033[0m", \
                                        field_data[x, y])
            }
        }
    }
    printf buffer _build_info() _build_next_piece(8, 13)
    system("")
}

function print_message(message, row,    column) {
    column = 23 + int((field_w * 2 - length(message)) / 2)
    printf("\033[%d;%dH%s", row, column, message)
    system("")
}

function get_next_piece(    data_num, x, y) {
    if (piece_count == item_interval) {
        data_num = PIECE_DATA_LEN - 1
        piece_count = 1
    }
    else {
        data_num = int(rand() * (PIECE_DATA_LEN - 1))
        piece_count += 1
    }
    for (y = 0; y < PIECE_H; y++) {
        for (x = 0; x < PIECE_W; x++) {
            next_piece_data[x, y] \
                = substr(PIECE_DATA[data_num], PIECE_W * y + x + 1, 1) + 0
        }
    }
}

function get_curr_piece(    x, y) {
    curr_piece_x = initial_x
    curr_piece_y = initial_y
    for (y = 0; y < PIECE_H; y++) {
        for (x = 0; x < PIECE_W; x++) {
            curr_piece_data[x, y] = next_piece_data[x, y]
        }
    }
}

function set_curr_piece(    x, y) {
    for (y = 0; y < PIECE_H; y++) {
        if (curr_piece_y + y < 0 || curr_piece_y + y >= field_h) {
            continue
        }
        for (x = 0; x < PIECE_W; x++) {
            if (curr_piece_x + x < 0 || curr_piece_x + x >= field_w) {
                continue
            }
            field_data[curr_piece_x + x, curr_piece_y + y] \
                += curr_piece_data[x, y]
        }
    }
}

function clear_curr_piece(    x, y) {
    for (y = 0; y < PIECE_H; y++) {
        if (curr_piece_y + y < 0 || curr_piece_y + y >= field_h) {
            continue
        }
        for (x = 0; x < PIECE_W; x++) {
            if (curr_piece_x + x < 0 || curr_piece_x + x >= field_w) {
                continue
            }
            field_data[curr_piece_x + x, curr_piece_y + y] \
                -= curr_piece_data[x, y]
        }
    }
}

function has_collision(    x, y) {
    for (y = 0; y < PIECE_H; y++) {
        if (curr_piece_y + y < 0 || curr_piece_y + y >= field_h) {
            continue
        }
        for (x = 0; x < PIECE_W; x++) {
            if (curr_piece_x + x < 0 || curr_piece_x + x >= field_w) {
                continue
            }
            if ( curr_piece_data[x, y] \
                 * field_data[curr_piece_x + x, curr_piece_y + y] != 0 ) {
                return 1
            }
        }
    }
    return 0
}

function rotate_left(    temp_array, x, y) {
    for (y = 0; y < PIECE_H; y++) {
        for (x = 0; x < PIECE_W; x++) {
            temp_array[x, y] = curr_piece_data[PIECE_H - y - 1, x]
        }
    }
    for (y = 0; y < PIECE_H; y++) {
        for (x = 0; x < PIECE_W; x++) {
            curr_piece_data[x, y] = temp_array[x, y]
        }
    }
}

function rotate_right(    temp_array, x, y) {
    for (y = 0; y < PIECE_H; y++) {
        for (x = 0; x < PIECE_W; x++) {
            temp_array[x, y] = curr_piece_data[y, PIECE_W - x - 1]
        }
    }
    for (y = 0; y < PIECE_H; y++) {
        for (x = 0; x < PIECE_W; x++) {
            curr_piece_data[x, y] = temp_array[x, y]
        }
    }
}
