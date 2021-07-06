default: cleanup build install

# package version
VERSION=0.1.0

# command line tools
PYTHON ?= "python3"
PIP ?= "pip"
NIMPORTER ?= "nimporter"

cleanup:
	rm -rf textformats.egg-info build dist MANIFEST.in nim-extensions __pycache__

build:
	${PYTHON} setup.py build -f

install:
	${PYTHON} setup.py install -f

SRCDIST=dist/textformats-${VERSION}.tar.gz

${SRCDIST}:
	${NIMPORTER} bundle src

install_src: ${SRCDIST}
	${PIP} install $<

WHEEL=dist/textformats-${VERSION}-cp37-cp37m-linux_x86_64.whl

${WHEEL}:
	${NIMPORTER} bundle bin

install_wheel: ${WHEEL}
	${PIP} install $<

uninstall:
	${PIP} uninstall textformats
