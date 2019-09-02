SD_PATH = "src/sd.cr"
BIN_PATH = "bin/sd_bin"
INSTALL_PATH = "/usr/bin/sd_bin"

all: build

build:
	crystal build $(SD_PATH) -o $(BIN_PATH) --threads=1

debug:
	DEBUG=enabled crystal build $(SD_PATH) -o $(BIN_PATH) --threads=1

clean:
	rm -rf ~/.config/sd

status:
	cat ~/.config/sd/data.yml

install:
	cp $(BIN_PATH) /usr/bin/sd_bin

.PHONY: clean build status install debug
