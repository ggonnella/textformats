default: cleanup build install

cleanup:
	rm -rf textformats.egg-info build dist MANIFEST.in nim-extensions __pycache__

build:
	python3 setup.py build -f

install:
	python3 setup.py install -f

VERSION=0.1.0

SRCDIST=dist/textformats-${VERSION}.tar.gz

${SRCDIST}:
	nimporter bundle src

install_src: ${SRCDIST}
	pip install $<

WHEEL=dist/textformats-${VERSION}-cp37-cp37m-linux_x86_64.whl

${WHEEL}:
	nimporter bundle bin

install_wheel: ${WHEEL}
	pip install $<

uninstall:
	pip uninstall textformats
