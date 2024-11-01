# Release Notes

- [Release 0.0.1](<ReleaseNotes#Release 0.0.1>)
- [Release 0.0.2](<ReleaseNotes#Release 0.0.2>)

## Release 0.0.1

This release was the initial commit to the repo. At that point, most of mlibc and the very early test for raw mode were implemented.

## Release 0.0.2

There is now a complete input to output pipeline that currently displays a relatively familiar look if you've ever used the Vi family of editors.

Currently, the only real functionality is the ability to move the cursor around.

Keybindings:
- HOME -- Move cursor to the beginning of the current row
- END -- Move cursor to the end of the current row
- PAGE UP -- Move cursor to the top of the current column
- PAGE DOWN -- Move cursor to the bottom of the current column
- DELETE -- Was just added at the end of the chapter, does nothing.

I have learned a lot messing around with this. There are already some key differences in how I handle things like the output buffer. I also abstracted most of the individual sequences into their own functions.

That being said, my goal is to try and lean more into C3's features and standard library over using libc directly (minus termios, it is required for now). So far, the only thing that has been difficult to replace in functionality has been the ```read()``` and ```write()``` functions from libc.

The main issue I have with leaning into libc is I am in some ways forced into using errno. Ideally, I would like to use C3's fault system for error reporting and recovery.