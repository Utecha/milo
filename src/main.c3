module milo;
import milo::editor @public;

//===------------------------------===//
//            Milo \ Main             //
//===------------------------------===//

fn void main(String[] args)
{
    editor::initialize();

    while (true)
    {
        editor::refreshScreen();
        editor::processKeypress();
    }
}