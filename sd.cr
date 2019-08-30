require "option_parser"
require "yaml"
require "./data.cr"

# outputs commands on STDERR,
# outputs text on STDOUT
class SmartDirectory
	# sd only creates files inside of the config directory.
	@@config_dir : String = Path["~/.config/sd"].expand.to_s

	@data : Data

	def initialize
		@data = Data.load @@config_dir, "data.yml"

		OptionParser.parse! do |parser|
			# If no arguments have been provided, sd will just navigate to
			# the defualt directory. This is much like how running `$ cd`
			# will navigate to `~`, but sd allows you to configure that
			# directory.
			if ARGV.empty?
				navigate_to_default
			end

			# If only one argument has been provided, it is likely the user
			if ARGV.size == 1
				puts ARGV[0]
			end


			parser.banner = "sd - Smart Directory"
		
			parser.on(long_flag: "--default DIR", short_flag: "-d DIR", description: "Specifies the default directory. Note that this is always enabled, whereas the lock directory is toggleable and project specific.") do |dir|
				set_default dir
			end
			
			parser.on(long_flag: "--lock DIR", short_flag: "-l DIR", description: "Enables directory lock.") do |dir|
				enable_lock dir
			end
			
			parser.on(long_flag: "--unlock", short_flag: "-u", description: "Disables directory lock.") do
				disable_lock
			end

			parser.on(flag: "--lock-status", description: "Prints the status of the lock, specifically if the lock is enabled, and the directory it points to.") do
				print_lock_status
			end

			parser.on(short_flag: "-h", long_flag: "--help", description: "Prints this help menu.") do
				puts parser
			end

			parser.missing_option do |flag|
				case flag
				when "-l", "--lock"
					enable_lock directory: ENV["PWD"]
				else
					puts "#{flag} requires a parameter."
					puts parser
					exit 1
				end
			end
		
			parser.invalid_option do |flag|
				puts "#{flag} is not a valid option."
				puts parser
				exit 1
			end
		end
	end

	# The function that is called when sd is invoked without parameters.
	def navigate_to_default
		if @data.lock.locked
			STDERR.puts "cd #{@data.lock.location}"
		else
			if @data.default
				STDERR.puts "cd #{@data.default}"
			else
				STDERR.puts "cd #{ENV["HOME"] || "~"}"
			end
		end

		exit 0
	end

	# This function is invoked when the lock flag is recieved.
	def enable_lock(directory : String)
		unless Dir.exists? directory
			puts "Refusing to lock on non-existent directory '#{directory}'."
			exit 1
		end

		@data.lock.locked = true
		@data.lock.location = directory

		@data.save
		
		puts "locked to '#{directory}'."
	end

	def disable_lock()
		if @data.lock.locked
			@data.lock.locked = false
			@data.save
		end

		puts "lock disabled."
	end

	# This function is invoked when the default flag is recieved.
	def set_default(directory : String)
		unless Dir.exists? directory
			puts "Refusing to set default on non-existent directory '#{directory}'."
			exit 1
		end

		@data.default = directory

		@data.save

		puts "set default directory to '#{directory}'."
	end

	def cd_if_locked
		if @data.lock.locked
			STDERR.puts "cd #{@data.lock.location}"
			exit 0
		end
	end

	def print_lock_status
		if @data.lock.locked
			puts "Lock enabled"
		else
			puts "Lock disabled"
		end

		puts "Lock directory: #{@data.lock.location}"

		exit 0
	end
end

# Creates an instance of the class, invokes initialize()
SmartDirectory.new
