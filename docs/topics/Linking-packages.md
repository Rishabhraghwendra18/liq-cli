# Linking packages

This discussion is within the context of the react dev server and the
react-scripts toolchain configuration as of 2019-01-26. All statements of fact
should be understood to be "as of" that date and should not be assumed true in
the future.

Linking a package essentially replaces the `node_modules` installation with a
link to a clone of the project folder so that changes in the local folder are
reflected immediately in the consuming package. E.g.:

    playground/
      app-a/
        node_modules/
          lib-b/
      lib-b/

Where `lib-b` is an independent installation of the 'lib-b' package, becomes:

    playground/
      app-a/
        node_modules/
          lib-b/ -> playground/lib-b
      lib-b/

In theory, that's it. In practice, however, the basic `npm link` is not
reliable.

## Bind instead

Rather than link the module, we bind it instead with `bindfs`. A bound directory
looks like any other directory, `node` will not try to de-reference the "link",
and everything will work fine.

## Downsides

Because OSX no longer supports hard links (see below) and the built-in
`mount -t bind` doesn't work (error message unclear), it's necessary to use OSX
Fuse plus `bindfs`. The first issue is that while `bindfs` can be installed with
Homebrew, OSX Fuse cannot. While the command-line install process could be
automated, it would be fragile. So, this does require that the user install
OSX Fuse.

## The problem with links

The problem with the simple link described above is that `node` will look to
`playground/lib-b/node_modules` to resolve imports. The problem seems to be that
when `node` looks at `playground/app-a/node_modules/lib-b`, it doesn't treat it
as a regular directory but recognizes it's a link and then tries to resolve
packages from `playground/lib-b`. This breaks if `lib-b` has any peer dependency
(as many libraries will) which relies on packages installed in `app-a`.

The first thought might be to use hard links instead of soft links. This would
presumably work, except that [hard links are no longer supported in OSX as of
2018](https://stackoverflow.com/a/52754343/929494) (through at least
2019-01-26). On the plus side, by mounting the bound directory with "read only",
we avoid the problem of accidentally deleting everything in the source directory
which would be inherent with the use of hard links. (Note, `rm -rf` with as root
can still cause problems.)

## Other approaches

We tried a number of other approaches before coming to the bind solution. These
all involved some soft-link scheme and mostly failed for the [reason above](#the-problem-with-links).
