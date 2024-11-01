module milo::buffer;

//===------------------------------===//
//           Milo \ Buffer            //
//===------------------------------===//

struct OutBuffer
{
    usz len;
    char *chars;
}

fn void OutBuffer.init(&self)
{
    self.len = 0;
    self.chars = null;
}

fn bool OutBuffer.append(&self, char *string, uint len)
{
    char *new = mem::realloc(self.chars, self.len + len);
    if (!new) return false;

    mem::copy(&new[self.len], string, len);
    self.chars = new;
    self.len += len;

    return true;
}

fn void OutBuffer.free(&self)
{
    mem::free(self.chars);
    self.init();
}