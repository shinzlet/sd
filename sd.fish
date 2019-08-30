function sd
	eval (sd_bin $argv 2>&1 >/tmp/sd_out)
	cat /tmp/sd_out
end

sd
