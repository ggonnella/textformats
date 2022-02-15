default: clean install

# package version
VERSION=1.2.1

# command line tools
PYTHON ?= python
PIP ?= pip
NIMBLE ?= nimble

clean:
	rm -rf *.egg-info build dist MANIFEST.in nim-extensions \
		     __pycache__ */__pycache__ */*/__pycache__ README.md

cleanup: clean
	rm -rf textformats/*.so
	${PIP} uninstall textformats

install:
	${PYTHON} setup.py bdist_wheel
	${PIP} install dist/*.whl --force-reinstall

test:
	pytest

NIM_SOURCES = py_bindings/py_bindings.nimble \
				   	  py_bindings/src/py_bindings.nim \
					    py_bindings/src/py_bindings.nim.cfg

PY_SOURCES = textformats/__init__.py \
					textformats/error.py \
					textformats/textformats.py

SOURCES = ${NIM_SOURCES} ${PY_SOURCES}

README.md:
	ln -s ../README.md .

### BINARY WHEEL ###

BINDINGS=py_bindings/py_bindings.so
TFBINDINGS=textformats/py_bindings.so
BUILD=build/lib/textformats

${BINDINGS}: ${PY_SOURCES}
	cd py_bindings && ${NIMBLE} build; \
	if [ "${OUT}" != "" ]; then \
	  mkdir -p ${OUT}; \
		echo $$PWD;\
		ls .;\
	  cp py_bindings.so ${OUT}/py_bindings.so; \
	fi

${BUILD}: ${TFBINDINGS} README.md
	rm -f dist/*.whl
	${PYTHON} setup.py build
	${PYTHON} setup.py bdist_wheel

install_wheel: ${BUILD}
	${PIP} install dist/*.whl --force-reinstall

# shortcuts for partial execution
bindings: ${BINDINGS}
build: ${BUILD}
wheel: ${WHEEL}

### SOURCE PACKAGE ###

SRCDISTRI=dist/textformats-${VERSION}.tar.gz

${SRCDISTRI}: ${SOURCES} README.md
	${PYTHON} setup.py sdist

install_src: ${SRCDISTRI}
	${PIP} install ${SRCDISTRI} --force-reinstall
