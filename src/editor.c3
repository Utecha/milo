module milo::editor @private;
import milo::buffer;
import libc;
import mlibc;
import std::ascii;
import std::io;

//===------------------------------===//
//           Milo \ Editor            //
//===------------------------------===//

/*=== BEGIN SECTION 'Definitions' ===*/

const String MILO_VERSION = "0.0.1";
const String MILO_WELCOME = "Milo Editor -- Version %s";

macro String getWelcome()
    => string::tformat(MILO_WELCOME, MILO_VERSION);

/* Converts [key] to its Ctrl variant */
macro char ctrlKey(key)
    => (char)(key & 0x1f);

/* Empty Line */
const String NEWLINE = "\r\n";

/* ANSI Terminal Escape Sequences */
/* Cursor Sequences */
const String HIDE_CURSOR        = "\x1b[?25l";
const String SHOW_CURSOR        = "\x1b[?25h";
const String MV_CURSOR_HOME     = "\x1b[H";
const String MV_CURSOR_TO       = "\x1b[%d;%dH";
const String MV_CURSOR_UP_N     = "\x1b[%dA";
const String MV_CURSOR_DOWN_N   = "\x1b[%dB";
const String MV_CURSOR_RIGHT_N  = "\x1b[%dC";
const String MV_CURSOR_LEFT_N   = "\x1b[%dD";
const String MV_CURSOR_NL_N     = "\x1b[%dE";
const String MV_CURSOR_PL_N     = "\x1b[%dF";
const String MV_CURSOR_TO_COL   = "\x1b[%dG";
const String QUERY_CURSOR_POS   = "\x1b[6n";

/* Erase Sequences */
const String ERS_FROM_CURSOR_TO_EOS = "\x1b[J";
const String ERS_FROM_CURSOR_TO_BEG = "\x1b[1J";
const String ERS_ENTIRE_SCREEN      = "\x1b[2J";
const String ERS_IN_LINE            = "\x1b[K";
const String ERS_SOL_TO_CURSOR      = "\x1b[1K";
const String ERASE_ENTIRE_LINE      = "\x1b[2K";

/* Simple Graphics Mode Sequences */
const String RESET_ALL_MODES        = "\x1b[0m";
const String SET_BOLD_MODE          = "\x1b[1m";
const String RESET_BOLD_MODE        = "\x1b[22m";
const String SET_DIM_MODE           = "\x1b[2m";
const String RESET_DIM_MODE         = "\x1b[22m";
const String SET_ITALIC_MODE        = "\x1b[3m";
const String RESET_ITALIC_MODE      = "\x1b[23m";
const String SET_UNDERLINE_MODE     = "\x1b[4m";
const String RESET_UNDERLINE_MODE   = "\x1b[24m";
const String SET_BLINKING_MODE      = "\x1b[5m";
const String RESET_BLINKING_MODE    = "\x1b[25m";
const String SET_INVERTED_MODE      = "\x1b[7m";
const String RESET_INVERTED_MODE    = "\x1b[27m";
const String SET_HIDDEN_MODE        = "\x1b[8m";
const String RESET_HIDDEN_MODE      = "\x1b[28m";

/* Editor Keys */
const int ARROW_UP      = 1000;
const int ARROW_DOWN    = 1001;
const int ARROW_LEFT    = 1002;
const int ARROW_RIGHT   = 1003;
const int PAGE_UP       = 1004;
const int PAGE_DOWN     = 1005;
const int HOME          = 1006;
const int END           = 1007;
const int DELETE        = 1008;

/* Editor Structure */
struct Editor
{
    /* Cursor */
    int cx;
    int cy;

    /* State */
    Termios original;
    int screenRows;
    int screenCols;
}

/* Global Editor */
Editor e;

/* Initialize the Editor */
fn void initialize()
{
    e.cx = 0;
    e.cy = 0;

    if (getWindowSize(&e.screenRows, &e.screenCols) == -1)
        { fatal("getWindowSize"); }
}

/*=== END SECTION 'Definitions' ===*/
/*=== BEGIN SECTION 'Editor Error' ===*/

/* Report a fatal error and yeet */
fn void fatal(ZString message)
{
    write(STDOUT, ERS_ENTIRE_SCREEN, ERS_ENTIRE_SCREEN.len);
    write(STDOUT, MV_CURSOR_HOME, MV_CURSOR_HOME.len);

    libc::perror(message);
    libc::exit(libc::errno());
}

/*=== END SECTION 'Editor Error' ===*/
/*=== BEGIN SECTION 'Terminal Control' ===*/

/* Disables raw mode */
fn void disableRawMode() @finalizer
{
    if (tcsetattr(STDIN, TCSAFLUSH, &e.original) == -1)
        { fatal("termios::tcsetattr -- disableRawMode"); }
}

/* Enables raw mode */
fn void enableRawMode() @init
{
    if (tcgetattr(STDIN, &e.original) == -1)
        { fatal("termios::tcgetattr -- enableRawMode"); }

    Termios raw = e.original;
    raw.c_iflag &= ~(BRKINT | ICRNL | INPCK | ISTRIP | IXON);
    raw.c_oflag &= ~(OPOST);
    raw.c_cflag |= (CS8);
    raw.c_lflag &= ~(ECHO | ICANON | IEXTEN | ISIG);
    raw.c_cc[VMIN] = 0;
    raw.c_cc[VTIME] = 1;

    if (tcsetattr(STDIN, TCSAFLUSH, &raw) == -1)
        { fatal("termios::tcsetattr -- enableRawMode"); }
}

/* Query the position of the cursor and load the result into [rows], [cols] */
fn int getCursorPosition(int *rows, int *cols)
{
    if (write(STDOUT, QUERY_CURSOR_POS, QUERY_CURSOR_POS.len) != 4) return -1;

    char[] buf = mem::temp_new_array(char, MV_CURSOR_TO.len - 1);
    for (int i = 0; i < buf.len; i++)
    {
        if (read(STDIN, &buf[i], 1) != 1) break;
        if (buf[i] == 'R') break;
    }

    if (buf[0] != '\x1b' || buf[1] != '[') return -1;
    if (libc::sscanf(&buf[2], "%d;%d", rows, cols) != 2) return -1;

    return 0;
}

/* Loads the result of querying the window size into [rows], [cols] */
fn int getWindowSize(int *rows, int *cols)
{
    Winsize ws;

    if (ioctl(STDOUT, TIOCGWINSZ, &ws) == -1 || ws.ws_col == 0)
    {
        if (write(STDOUT, "\x1b[999C\x1b[999B", 12) != 12) return -1;
        return getCursorPosition(rows, cols);
    }
    else
    {
        *cols = ws.ws_col;
        *rows = ws.ws_row;
        return 0;
    }
}

/* Read's in [c] from standard input and returns it */
fn int readKey()
{
    isz nread;
    char c;

    while ((nread = read(STDIN, &c, 1)) != 1)
    {
        if (nread == -1 && errno() != errno::EAGAIN)
            { fatal("read"); }
    }

    if (c == '\x1b')
    {
        char[3] seq;

        if (read(STDIN, &seq[0], 1) != 1) return '\x1b';
        if (read(STDIN, &seq[1], 1) != 1) return '\x1b';

        if (seq[0] == '[')
        {
            if (ascii::is_digit(seq[1]))
            {
                if (read(STDIN, &seq[2], 1) != 1) return '\x1b';
                if (seq[2] == '~')
                {
                    switch (seq[1])
                    {
                        case '1':   return HOME;
                        case '3':   return DELETE;
                        case '4':   return END;
                        case '5':   return PAGE_UP;
                        case '6':   return PAGE_DOWN;
                        case '7':   return HOME;
                        case '8':   return END;
                    }
                }
            }
            else
            {
                switch (seq[1])
                {
                    case 'A':   return ARROW_UP;
                    case 'B':   return ARROW_DOWN;
                    case 'C':   return ARROW_RIGHT;
                    case 'D':   return ARROW_LEFT;
                    case 'H':   return HOME;
                    case 'F':   return END;
                }
            }
        }
        else if (seq[0] == 'O')
        {
            switch (seq[1])
            {
                case 'H':   return HOME;
                case 'F':   return END;
            }
        }

        return '\x1b';
    }

    return c;
}

/*=== END SECTION 'Terminal Control' ===*/
/*=== BEGIN SECTION 'Editor Input' ===*/

/* Moves the cursor around the screen */
fn void moveCursor(int key)
{
    switch (key)
    {
        case ARROW_LEFT:
        {
            if (e.cx != 0)
            {
                e.cx--;
            }
        }
        case ARROW_RIGHT:
        {
            if (e.cx != e.screenCols - 1)
            {
                e.cx++;
            }
        }
        case ARROW_UP:
        {
            if (e.cy != 0)
            {
                e.cy--;
            }
        }
        case ARROW_DOWN:
        {
            if (e.cy != e.screenRows - 1)
            {
                e.cy++;
            }
        }
    }
}

/* Processes a single keypress from the user */
fn void processKeypress()
{
    int c = readKey();
    switch (c)
    {
        case ctrlKey('q'):
        {
            write(STDOUT, ERS_ENTIRE_SCREEN, ERS_ENTIRE_SCREEN.len);
            write(STDOUT, MV_CURSOR_HOME, MV_CURSOR_HOME.len);
            libc::exit(0);
        }

        case HOME:
            e.cx = 0;
        case END:
            e.cx = e.screenCols - 1;

        case PAGE_UP:
        case PAGE_DOWN:
        {
            int times = e.screenRows;
            while (times--)
                { moveCursor(c == PAGE_UP ? ARROW_UP : ARROW_DOWN); }
        }

        case ARROW_UP:
        case ARROW_DOWN:
        case ARROW_LEFT:
        case ARROW_RIGHT:
            moveCursor(c);
    }
}

/*=== END SECTION 'Editor Input' ===*/
/*=== BEGIN SECTION 'Editor Output' ===*/

/* Output sequence to move cursor to home position */
fn void moveCursorHome(OutBuffer *buf)
{
    buf.append(MV_CURSOR_HOME, MV_CURSOR_HOME.len);
}

/* Output sequence to hide the cursor */
fn void hideCursor(OutBuffer *buf)
{
    buf.append(HIDE_CURSOR, HIDE_CURSOR.len);
}

/* Output sequence to show the cursor */
fn void showCursor(OutBuffer *buf)
{
    buf.append(SHOW_CURSOR, SHOW_CURSOR.len);
}

/* Output sequences to erase the screen and move cursor back to home */
fn void eraseScreen(OutBuffer *buf)
{
    buf.append(ERS_ENTIRE_SCREEN, ERS_ENTIRE_SCREEN.len);
    moveCursorHome(buf);
}

/* Output sequence to draw the cursor */
fn void drawCursor(OutBuffer *buf)
{
    String pos = string::tformat(MV_CURSOR_TO, e.cy + 1, e.cx + 1);
    buf.append(pos, pos.len);
}

/* Draw the rows on the screen */
fn void drawRows(OutBuffer *buf)
{
    for (int y = 0; y < e.screenRows; y++)
    {
        if (y == e.screenRows / 3)
        {
            String welcome = getWelcome();
            int len = welcome.len;

            if (len > e.screenCols) len = e.screenCols;
            int padding = (e.screenCols - len) / 2;

            if (padding)
            {
                buf.append("~", 1);
                padding--;
            }

            while (padding--) buf.append(" ", 1);
            buf.append(welcome, welcome.len);
        }
        else
        {
            buf.append("~", 1);
        }

        buf.append(ERS_IN_LINE, ERS_IN_LINE.len);
        if (y < e.screenRows - 1)
            { buf.append(NEWLINE, NEWLINE.len); }
    }
}

/* Update the screen with the current output */
fn void refreshScreen()
{
    OutBuffer buf;
    buf.init();

    hideCursor(&buf);
    moveCursorHome(&buf);
    drawRows(&buf);
    drawCursor(&buf);
    showCursor(&buf);

    write(STDOUT, buf.chars, buf.len);
    buf.free();
}

/*=== END SECTION 'Editor Output' ===*/