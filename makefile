SD_PATH = "src/main.cr"
BIN_PATH = "bin/sd_bin"
INSTALL_PATH = "/usr/bin/sd_bin"
LANG = "en"

all: build

build:
	SD_LANG="$(LANG)" crystal build $(SD_PATH) -o $(BIN_PATH) --threads=1

debug:
	SD_LANG="$(LANG)" DEBUG=enabled crystal build $(SD_PATH) -o $(BIN_PATH) --threads=1

clean:
	rm -rf ~/.config/sd

status:
	cat ~/.config/sd/data.yml

install:
	cp $(BIN_PATH) /usr/bin/sd_bin

.PHONY: clean build status install debug
