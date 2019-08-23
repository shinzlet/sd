require "option_parser"
require "yaml"
require "./data.cr"

class SmartDirectory
	# sd only creates files inside of the config directory.
	@@config_dir : String = Path["~/.config/sd"].expand.to_s

	def initialize
		OptionParser.parse! do |parser|
			# If no arguments have been provided, sd will just navigate to
			# the defualt directory. This is much like how running `$ cd`
			# will navigate to `~`, but sd allows you to configure that
			# directory.
			if ARGV.empty?
				sd
			end

			parser.banner = "sd - Smart Directory"
		
			parser.on(long_flag: "--lock DIR", short_flag: "-l DIR", description: "Enables directory lock.") do |dir|
				lock dir
			end
		
			parser.missing_option do |flag|
				case flag
				when "-l", "--lock"
					lock ENV["PWD"]
				else
					STDERR.puts "#{flag} requires a parameter."
					STDERR.puts parser
					exit 1
				end
			end
		
			parser.invalid_option do |flag|
				STDERR.puts "#{flag} is not a valid option."
				STDERR.puts parser
				exit 1
			end
		end
	end

	# The function that is called when sd is invoked without parameters.
	def sd
		data = Data.load @@config_dir, "data.yml"
		puts data.to_yaml
		exit 0
	end

	# This function is invoked when the lock flag is recieved.
	def lock(directory : String)
		unless Dir.exists? directory
			abort "Refusing to lock on non-existent directory '#{directory}'."
		end
	end
end

# Creates an instance of the class, invokes initialize()
SmartDirectory.new
