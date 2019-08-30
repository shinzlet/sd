all: build

build:
	crystal build sd.cr -o sd_bin --threads=1

clean:
	rm -rf ~/.config/sd

status:
	ls ~/.config/sd

install: build
	cp sd_bin /usr/bin/sd_bin

.PHONY: clean build status install autoconfig
