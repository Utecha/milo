# Milo

Milo is a terminal-based text editor heavily inspired by [Kilo](https://viewsourcecode.org/snaptoken/kilo/), and of course the best editor: neovim.

One major difference is that it is written in [C3](https://c3-lang.org/) rather than C. C3 is, as the website states, an 'evolution' on C. The language is still in early development, however it is very promising and has become my new favourite language over C itself. It is, in many ways, already well beyond that of C in terms of its features and capabilities without being too dissimilar.

Anyways, enough glazing... Early versions of Milo will be largely identical to Kilo in order to remind myself how all of this works, and also because my final goal is not currently possible...

The final goal is to actually implement a similar system with modal editing much like the Vi family, except in ncurses rather than termios. The problem is that there are currently no C3 bindings for ncurses, and I haven't currently figured out how to take advantage of the feature to include C code in C3 code. I'm currently figuring out how exactly I might go about writing the bindings myself.

## Build

To build the application, run:

```sh
$ c3c build
```

You can also use:

```sh
$ c3c run
```

To build and immediately run Milo.

If you used the 'build' option, you can find the executable in the ```build/``` directory.

## License

This project is licensed under the [MIT License](#ADDLATER).