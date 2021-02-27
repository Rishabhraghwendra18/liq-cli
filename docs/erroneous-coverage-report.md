We spent awhile on trying to get coverage working... tried kcov and bashcov. Initially had issues with bashcov complaining about LINENO or some unicode character being present and attempted to build newer versions. That resulted in a conflict snarl, but then went back and was able to get the 1.8.2 release running.

However, it seems we will need the newer versions because the coverage report (for liq-cli at least) is total bunk. With just 'meta init' and like one help function tested, we managed to achieve like 85% coverage! So, there's something about how the script itself works, deficiencies in the tools, or something.

References:
* [Long discussion on bug similar to our initial problem with shunit2 and bashcov.](https://github.com/infertux/bashcov/issues/31)
* [bashcov project home.](https://github.com/infertux/bashcov)
* [simplecov project home](https://github.com/simplecov-ruby/simplecov); this is the library that does the heavy lifting in bashconv.
