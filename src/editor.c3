module milo::editor;
import libc;
import mlibc;
import std::io;

//===------------------------------===//
//           Milo \ Editor            //
//===------------------------------===//

fn void fatal(ZString message)
{
    libc::perror(message);
    libc::exit(libc::errno());
}

/*=== BEGIN SECTION 'Terminal Control' ===*/

/* Original terminal state */
Termios original;

/* Disables raw mode */
fn void disableRawMode() @finalizer @private
{
    if (tcsetattr(STDIN, TCSAFLUSH, &original) == -1)
        { fatal("termios::tcsetattr -- disableRawMode"); }
}

/* Enables raw mode */
fn void enableRawMode() @init @private
{
    if (tcgetattr(STDIN, &original) == -1)
        { fatal("termios::tcgetattr -- enableRawMode"); }

    Termios raw;
    raw.c_iflag &= ~(BRKINT | ICRNL | INPCK | ISTRIP | IXON);
    raw.c_oflag &= ~(OPOST);
    raw.c_cflag |= (CS8);
    raw.c_lflag &= ~(ECHO | ICANON | IEXTEN | ISIG);
    raw.c_cc[VMIN] = 0;
    raw.c_cc[VTIME] = 1;

    if (tcsetattr(STDIN, TCSAFLUSH, &raw) == -1)
        { fatal("termios::tcsetattr -- enableRawMode"); }
}

/*=== END SECTION 'Terminal Control' ===*/