module mlibc;
import libc;

//===------------------------------===//
//               mlibc                //
//===------------------------------===//

/*
 * I'm writing this module as a standalone library to bypass naming conflicts
 * from naming it, say 'milo::libc'.
 *
 * This module defines and redefines structures, flags, and functions within
 * the libc and termios libraries, to make them more convenient to use (or to
 * introduce them if they don't exist already).
 *
 * This mostly applies to the termios library, as there is a weird type
 * discrepancy between the 'Tcflags' and 'CInt' types defined for certain
 * flags. They're effectively backwards.
 *
 * Again, since this library is largely defined for convenience, most
 * definitions will be marked as '@builtin', and each section (libc, termios)
 * will be denoted via comments rather than being actual separate modules.
*/

//===------------------------------===//
//               libc                 //
//===------------------------------===//

/*=== BEGIN SECTION 'libc' ===*/

/*
 * Bit flags used to determine the size of the window.
 *
 * The first one (CG) is the window size getter bit.
 * The second one (CS) is the window size setter bit.
 *
 * On linux, these are defined in '/usr/include/asm-generic/ioctls.h'.
*/
const CInt TIOCGWINSZ @builtin = 0x5413;
const CInt TIOCSWINSZ @builtin = 0x5414;

/* Redefinitions of the standard IO file descriptors, for convenience */
const Fd STDIN  @builtin = libc::STDIN_FD;
const Fd STDOUT @builtin = libc::STDOUT_FD;
const Fd STDERR @builtin = libc::STDERR_FD;

/*
 * The below functions exist to call the original corresponding functions
 * without having to qualify it with 'libc::'.
 * This does add some overhead due to the extra function call so I need to
 * find a better solution eventually. Maybe function pointers?
*/

fn isz read(Fd fd, void *buf, usz nbyte) @builtin
    => libc::read(fd, buf, nbyte);

fn Errno errno() @builtin
    => libc::errno();

/*=== END SECTION 'libc' ===*/

//===------------------------------===//
//              termios               //
//===------------------------------===//

/*=== BEGIN SECTION 'termios' ===*/

/*
 * The 'winsize' struct.
 *
 * On linux, this is defined in '/usr/include/asm-generic/termios.h'.
*/
struct Winsize @extern("winsize")
{
    ushort ws_row;
    ushort ws_col;
    ushort ws_xpixel;   /* unused, legacy */
    ushort ws_ypixel;   /* unused, legacy */
}

/*
 * The below constants are type casts from 'CInt' -> 'Tcflags'.
*/

/* Control Flags (Termios.c_cflag) */
const Tcflags CS8       @builtin = (Tcflags)termios::CS8;

/* Input Flags (Termios.c_iflag) */
const Tcflags BRKINT    @builtin = (Tcflags)termios::BRKINT;
const Tcflags ICRNL     @builtin = (Tcflags)termios::ICRNL;
const Tcflags INPCK     @builtin = (Tcflags)termios::INPCK;
const Tcflags ISTRIP    @builtin = (Tcflags)termios::ISTRIP;
const Tcflags IXON      @builtin = (Tcflags)termios::IXON;

/* Local Flags (Termios.c_lflag) */
const Tcflags ECHO      @builtin = (Tcflags)termios::ECHO;
const Tcflags ICANON    @builtin = (Tcflags)termios::ICANON;
const Tcflags IEXTEN    @builtin = (Tcflags)termios::IEXTEN;
const Tcflags ISIG      @builtin = (Tcflags)termios::ISIG;

/* Output Flags (Termios.c_oflag) */
const Tcflags OPOST     @builtin = (Tcflags)termios::OPOST;

/*
 * The below constants are type casts from 'Tcflags' -> 'CInt'.
*/

const CInt TCSANOW      @builtin = (CInt)termios::TCSANOW;
const CInt TCSADRAIN    @builtin = (CInt)termios::TCSADRAIN;
const CInt TCSAFLUSH    @builtin = (CInt)termios::TCSAFLUSH;

/* Shorteners for the (c_cc) characters */
const CInt VMIN         @builtin = termios::VMIN;
const CInt VTIME        @builtin = termios::VTIME;

/*
 * The below functions exist to call the original corresponding functions
 * without having to qualify it with 'termios::'.
 * This does add some overhead due to the extra function call so I need to
 * find a better solution eventually. Maybe function pointers?
*/

fn CInt tcgetattr(Fd fd, Termios *termios) @builtin
    => termios::tcgetattr(fd, termios);

fn CInt tcsetattr(Fd fd, CInt optional_actions, Termios *termios) @builtin
    => termios::tcsetattr(fd, optional_actions, termios);

/*=== END SECTION 'termios' ===*/