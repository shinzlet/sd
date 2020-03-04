#! /bin/zsh
function sd {
	eval `sd_bin $@ 2>&1 >/tmp/sd_out`
	cat /tmp/sd_out
}

sd