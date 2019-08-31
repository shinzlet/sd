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
				navigate
			end

			# If only one argument has been provided, it is likely the user is
			# trying to use sd in cd mode - eg "sd ~/Documents". Here, we check
			# if this is the case, and act accordingly.
			if ARGV.size == 1
				unless ARGV[0][0] == '-'
					navigate_to ARGV[0]
				end
			end


			parser.banner = "sd - Smart Directory"
		
			parser.on(long_flag: "--default DIR", short_flag: "-d DIR", description: "Specifies the default directory. Note that this is always enabled, whereas the lock directory is toggleable and project specific.") do |dir|
				set_default dir
				exit 0
			end
			
			parser.on(long_flag: "--lock DIR", short_flag: "-l DIR", description: "Enables directory lock.") do |dir|
				enable_lock dir
				exit 0
			end
			
			parser.on(long_flag: "--unlock", short_flag: "-u", description: "Disables directory lock.") do
				disable_lock
				exit 0
			end

			parser.on(flag: "--lock-status", description: "Prints the status of the lock, specifically if the lock is enabled, and the directory it points to.") do
				print_lock_status
				exit 0
			end

			parser.on(long_flag: "--create-shortcut NAME DIR", short_flag: "-s NAME DIR", description: "Creates a shortcut with the given name and directory. If the directory is not specified, the current directory is used.") do |name|
				puts "hmm"
				if ARGV.size > 0
					if Dir.exists? (path = ARGV.delete_at(0))
						create_shortcut name, path
					else
						puts "Refusing to create shortcut for non-existent path '#{path}'."
					end
				else
					create_shortcut name, ENV["PWD"]
				end
				exit 0
			end

			parser.on(long_flag: "--shortcut NAME", short_flag: "-n NAME", description: "Forces sd to recognize NAME as a shortcut, not a local directory.") do |name|

			end

			parser.on(short_flag: "-h", long_flag: "--help", description: "Prints this help menu.") do
				puts parser
			end

			parser.missing_option do |flag|
				case flag
				when "-l", "--lock"
					enable_lock directory: ENV["PWD"]
					exit 0
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
	def navigate
		if @data.lock.locked
			execute "cd #{@data.lock.location}"
		else
			if @data.default
				execute "cd #{@data.default}"
			else
				execute "cd #{ENV["HOME"] || "~"}"
			end
		end
	end

	# The function that is called when sd is invoked with a single string that is not a flag.
	# That is, `name` is either a directory, shortcut name, or malformed command.
	def navigate_to(name : String)
		# Check if the directory exists - directories have priority over shortcut names.
		if Dir.exists? ARGV[0]
			execute "cd #{ARGV[0]}"
		else
			begin
				result = @data.shortcuts[name]
				execute "cd #{result}"
			rescue ex
				puts "#{ARGV[0]} is not a valid directory or shortcut."
				exit 1
			end
		end
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
			execute "cd #{@data.lock.location}"
		end
	end

	def print_lock_status
		if @data.lock.locked
			puts "Lock enabled"
		else
			puts "Lock disabled"
		end

		puts "Lock directory: #{@data.lock.location}"
	end

	def create_shortcut(name : String, dir : String)
		@data.shortcuts[name] = dir
		@data.save
	end

	# Normal methods of executing a shell command all happen within a subshell.
	# Thus, the only way to actually execute a command inside the invoking shell is
	# to run
	# eval $(program)
	# in their shell. As a result of this limitation, sd is rather contrived. This program
	# (the binary), when executed, prints the command it wishes to run in the invoking shell
	# through STDERR, and normal output through STDOUT. Then, a function which is defined or
	# sourced from the user's bashrc, config.fish, or equivalent, is created which does the
	# following: 
	# 1) run sd_bin
	# 2) print the stdout to the screen
	# 3) eval STDERR
	# This is all done inside sd.* files.
	def execute(cmd : String)
		STDERR.puts cmd
	end
end

# Creates an instance of the class, invokes initialize()
SmartDirectory.new
