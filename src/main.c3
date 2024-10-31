module milo;
import libc;
import mlibc;
import std::ascii;
import std::io @norecurse;

//===------------------------------===//
//            Milo \ Main             //
//===------------------------------===//

fn int main(String[] args)
{
    while (true)
    {
        char c = '\0';
        if (read(STDIN, &c, 1) == -1 && errno() != errno::EAGAIN)
            { editor::fatal("libc::read"); }

        if (ascii::is_cntrl(c))
            { io::printf("%d\r\n", c); }
        else
            { io::printf("%d ('%c')\r\n", c, c); }

        if (c == 'q') break;
    }

    return 0;
}