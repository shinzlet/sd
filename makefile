all: build

build:
	crystal build sd.cr -o sd_bin --threads=1

debug:
	DEBUG=enabled crystal build sd.cr -o sd_bin --threads=1

clean:
	rm -rf ~/.config/sd

status:
	cat ~/.config/sd/data.yml

install: build
	cp sd_bin /usr/bin/sd_bin

debug_install: debug
	cp sd_bin /usr/bin/sd_bin

.PHONY: clean build status install debug
