default: cleanup build install

# package version
VERSION=1.1.0

# command line tools
PYTHON ?= python
PIP ?= pip
NIMPORTER ?= nimporter

CFLAGS="-w"

cleanup:
	rm -rf textformats.egg-info build dist MANIFEST.in nim-extensions __pycache__

build:
	env CFLAGS=${CFLAGS} ${PYTHON} setup.py build -f

install:
	if ${PIP} show nimporter > /dev/null; then \
		VER=$$(${PIP} show nimporter | grep -P -o "(?<=Version: ).*"); \
		if test "$$VER" != "1.0.2"; then \
		  ${PIP} install nimporter==1.0.2; \
		fi; \
	else \
		${PIP} install nimporter==1.0.2; \
	fi
	${PYTHON} setup.py install -f
	${PYTHON} -c "import textformats"

test:
	pytest

SRCDIST=dist/textformats-${VERSION}.tar.gz

${SRCDIST}:
	${NIMPORTER} bundle src

install_src: ${SRCDIST}
	${PIP} install $<

WHEEL_BUILT=dist/textformats.wheel_built
WHEEL=$(shell ls dist/textformats*.whl)

${WHEEL_BUILT}:
	${NIMPORTER} bundle bin
	touch ${WHEEL_BUILT}

install_wheel: ${WHEEL_BUILT}
	${PIP} install ${WHEEL}

uninstall:
	${PIP} uninstall textformats
