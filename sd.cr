require "option_parser"

OptionParser.parse! do |parser|
	parser.banner = "sd - Smart Directory"

	if ARGV.empty?
		sd
	end

	parser.on(long_flag: "--lock DIR", short_flag: "-l DIR", description: "Enables directory lock.") do |dir|
		lock dir
	end

	parser.missing_option do |flag|
		case flag
		when "-l", "--lock"
			lock(ENV["PWD"])
		else
			STDERR.puts "#{flag} requires a parameter."
			STDERR.puts parser
			exit(1)
		end
	end

	parser.invalid_option do |flag|
		STDERR.puts "#{flag} is not a valid option."
		STDERR.puts parser
		exit(1)
	end
end

def sd
end

def lock(directory : String)
	puts directory
	puts config_exists?
end

def config_exists?
	File.exists?("~/.config/sd/lockfile")
end
