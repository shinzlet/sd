require "option_parser"

OptionParser.parse! do |parser|
	parser.banner = "sd - Smart Directory"
	parser.on(long_flag: "--lock DIR", short_flag: "-l DIR", description: "Enables directory lock.") do |dir|
		puts "Directory lock enabled in #{dir}."
	end

	parser.missing_option do |flag|
		case flag
		when "-l", "--lock"
			puts "Directory lock enabled in local dir."
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
