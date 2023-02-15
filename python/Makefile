default: clean install

# package version
VERSION=1.2.3

# command line tools
PYTHON ?= python
PIP ?= pip
NIMBLE ?= nimble

# use Bash commands instead of Sh:
SHELL := /bin/bash

clean:
	rm -rf *.egg-info build dist MANIFEST.in nim-extensions \
		     __pycache__ */__pycache__ */*/__pycache__ README.md

cleanup: clean
	rm -rf py_bindings/*.so
	${PIP} uninstall textformats

# Compute PEP 425 compatibility tag
PYTHON_IMPLEMENTATION_CODE="py"
PYTHON_VERSION_CODE=`${PYTHON} --version | grep -o -P '\d+\.\d+' | sed 's/\.//'`
PYTHON_TAG="${PYTHON_IMPLEMENTATION_CODE}${PYTHON_VERSION_CODE}"
ABI_TAG="none"
PLATFORM_TAG="manylinux1_x86_64"
PEP425_TAG="${PYTHON_TAG}-${ABI_TAG}-${PLATFORM_TAG}"

install:
	${PYTHON} setup.py bdist_wheel
	mv dist/textformats-${VERSION}-py3-none-any.whl \
		dist/textformats-${VERSION}-${PEP425_TAG}.whl
	${PIP} install dist/*.whl --force-reinstall

test:
	pytest

NIM_SOURCES_CFG = py_bindings/src/py_bindings.nim.cfg
NIM_SOURCES = py_bindings/py_bindings.nimble \
				   	  py_bindings/src/py_bindings.nim \
					    ${NIM_SOURCES_CFG}

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
	cp ${NIM_SOURCES_CFG} ${NIM_SOURCES_CFG}.orig
	if [[ "$$(arch)" == "arm64" ]]; then \
	  echo '--passC:"-arch arm64 -flto"' >> ${NIM_SOURCES_CFG}; \
	  echo '--passL:"-arch arm64 -flto"' >> ${NIM_SOURCES_CFG}; \
	else \
	  echo '--passC:"-flto"' >> ${NIM_SOURCES_CFG}; \
	  echo '--passL:"-flto"' >> ${NIM_SOURCES_CFG}; \
	fi
	cd py_bindings && ${NIMBLE} build
	cp ${NIM_SOURCES_CFG}.orig ${NIM_SOURCES_CFG}

bindings_cp: ${BINDINGS}
	mkdir -p ${OUT}
	cp ${BINDINGS} ${OUT}/py_bindings.so

${BUILD}: ${TFBINDINGS} README.md
	rm -f dist/*.whl
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
