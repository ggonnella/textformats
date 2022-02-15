default: clean install

# package version
VERSION=1.2.0

# command line tools
PYTHON ?= python
PIP ?= pip
NIMBLE ?= nimble

clean:
	rm -rf *.egg-info build dist MANIFEST.in nim-extensions \
		     __pycache__ */__pycache__ */*/__pycache__

cleanup: clean
	${PIP} uninstall textformats

BINDINGS=py_bindings/py_bindings.so
TFBINDINGS=textformats/py_bindings.so
BUILD=build/lib/textformats
WHEEL=dist/textformats-${VERSION}-py3-none-any.whl

${BINDINGS}: py_bindings/py_bindings.nimble \
	           py_bindings/src/py_bindings.nim.cfg \
						 py_bindings/src/py_bindings.nim
	cd py_bindings && ${NIMBLE} build

${TFBINDINGS}: ${BINDINGS}
	cp $< $@

${BUILD}: ${TFBINDINGS}
	${PYTHON} setup.py build -f

${WHEEL}: ${BUILD}
	${PYTHON} setup.py bdist_wheel

install: ${WHEEL}
	${PIP} install ${WHEEL} --force-reinstall

test:
	pytest

# shortcuts for partial execution
bindings: ${BINDINGS}
build: ${BUILD}
wheel: ${WHEEL}
