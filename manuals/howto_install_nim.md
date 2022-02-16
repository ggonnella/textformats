
The Nim compiler (>= 1.6.0) must be installed to work with Nim, C or to install
the Python source distribution package.

For installing the Nim compiler there are several options (any will do, but some will only be available on some
systems, thus they are all listed here):

# Option 1: Choosenim current version (requires a recent GLIB_C)
```
curl https://nim-lang.org/choosenim/init.sh -sSf | sh
# if necessary, add NIM to the path, e.g.:
echo 'export PATH="$HOME/.nimble/bin:$PATH"' >> .bashrc
```

# Option 2: Choosenim older version (any GLIB_C)

```
# for Linux
export URL=https://github.com/dom96/choosenim/releases/download/v0.7.2/choosenim-0.7.2_linux_amd64
# for MacOS
export URL=https://github.com/dom96/choosenim/releases/download/v0.7.2/choosenim-0.7.2_macosx_amd64

wget -O choosenim $URL && chmod +x choosenim && ./choosenim 1.6.4
# add NIM to the path, e.g.:
echo 'export PATH="$HOME/.nimble/bin:$PATH"' >> .bashrc
```

# Option 3: Nim homepage 

Install the Nim compiler pre-compiled binaries (or even the source code and compile it according to the instructions there)
from the [Nim homepage](https://nim-lang.org/install_unix.html)

If necessary, add NIM to the path, where you install the software:
```
echo 'export PATH="/path/to/nim/bin:$PATH"' >> .bashrc
```

# Option 4: package managers

If you install nim with a package manager (e.g. brew, conda, apt-get, ...)
make sure that the version installed is >= 1.6.0.

Currently e.g. conda currently installs version 1.4.8, incompatible with TextFormts.
