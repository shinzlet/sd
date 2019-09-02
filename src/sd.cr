require "option_parser"
require "yaml"
require "./data.cr"

# This macro can be uesd to wrap debug code to only compile it if
# the DEBUG=enabled environment variable exists.
macro debug_only(code)
	{%if env("DEBUG") == "enabled"%}
		{{code}}
	{%end%}
end

# outputs commands on STDERR,
# outputs text on STDOUT
class SmartDirectory
	# sd only creates files inside of the config directory.
	@@config_dir : String = Path["~/.config/sd"].expand.to_s

	@data : Data

	def initialize
		@data = Data.load @@config_dir, Data.filename

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
			
			debug_only(
				parser.on(long_flag: "--dump-yaml", short_flag: "-y", description: "") do
					puts @data.to_yaml
				end
			)
		
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
				@data.lock.print_status
				exit 0
			end

			parser.on(long_flag: "--create-shortcut NAME DIR", short_flag: "-s NAME DIR", description: "Creates a shortcut with the given name and directory. If the directory is not specified, the current directory is used.") do |name|
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

			parser.on(long_flag: "--delete-shortcut NAME", short_flag: "-x NAME", description: "Deletes the shortcut with a given name, if it exists.") do |name|
				delete_shortcut name
				exit 0
			end

			parser.on(long_flag: "--shortcut NAME", short_flag: "-n NAME", description: "Forces sd to recognize NAME as a shortcut, not a local directory.") do |name|
				navigate_to_shortcut name
				exit 0
			end

			parser.on(long_flag: "--shortcuts", short_flag: "-p", description: "Prints a list of all exisiting shortcuts.") do
				print_shortcuts
				exit 0
			end

			parser.on(long_flag: "--use-history BOOL", short_flag: "-h BOOL", description: "Enables or disables the use of history logging.") do |bool|
				if bool == "true"
					@data.history.enabled = true
				elsif bool == "false"
					@data.history.enabled = false
					@data.history.delete_all
					@data.save
				else
					puts "Expected true or false, read '#{bool}'. Failed to set history state."
					exit 1
				end

				@data.save
				exit 0
			end

			parser.on(long_flag: "--history-status", short_flag: "-H", description: "Prints the logged directory history.") do
				@data.history.print_status
				exit 0
			end

			parser.on(long_flag: "--foward", short_flag: "-f", description: "Steps forwards in history, if it is enabled.") do
				history_step 1
			end

			parser.on(long_flag: "--back", short_flag: "-b", description: "Steps backwards in history, if it is enabled.") do
				history_step -1
			end

			parser.on(long_flag: "--jump AMOUNT", short_flag: "-j AMOUNT", description: "Jumps in history by AMOUNT steps. Positive for forward, negative for backward.") do |amount|
				begin
					history_step amount.to_i32
				rescue ex
					puts "failed to step in history - '#{amount}' is not an integer."
				end
			end

			parser.on(short_flag: "-h", long_flag: "--help", description: "Prints this help menu.") do
				puts parser
				exit 0
			end

			parser.missing_option do |flag|
				case flag
				when "-l", "--lock"
					enable_lock Dir.current
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
			cd_to @data.lock.location
		else
			if @data.default
				cd_to @data.default
			else
				cd_to Dir.current
			end
		end
	end

	# The function that is called when sd is invoked with a single string that is not a flag.
	# That is, `location` is either a directory, shortcut name, or malformed command.
	def navigate_to(location : String)
		# Check if the directory exists - directories have priority over shortcut names.
		directory = Path[location].expand.to_s
		if Dir.exists? directory
			cd_to directory
		else
			begin
				result = @data.shortcuts[location]
				cd_to result
			rescue ex
				puts "#{location} is not a valid directory or shortcut."
				exit 1
			end
		end
	end

	# This function specifically navigates to a shortcut, and does not check if name
	# is a directory. Used by --shortcut to override local dirs.
	def navigate_to_shortcut(name : String)
		begin
			result = @data.shortcuts[name]
			cd_to result
		rescue ex
			puts "#{name} is not a valid shortcut."
			exit 1
		end
	end

	# This function is invoked when the lock flag is recieved.
	def enable_lock(location : String)
		directory = Path[location].expand.to_s
		if Dir.exists? directory
			@data.lock.location = directory
			puts "locked to '#{directory}'"
		else
			begin
				result = @data.shortcuts[location]
				@data.lock.location = result
				puts "locked to '#{location}' (#{result})"
			rescue ex
				puts "no directory or shortcut named '#{directory}' exists"
				exit 1
			end
		end

		@data.lock.locked = true
		@data.save
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
			cd_to @data.lock.location
		end
	end

	def create_shortcut(name : String, dir : String)
		@data.shortcuts[name] = dir
		@data.save
	end

	def delete_shortcut(name : String)
		if @data.shortcuts.delete(name)
			@data.save
			puts "deleted the shortcut '#{name}'."
		else
			puts "the shortcut '#{name}' does not exist."
		end
	end

	def print_shortcuts()
		puts "shortcuts:"
		@data.shortcuts.each do |key, value|
			puts "#{key} -> #{value}"
		end
	end

	def history_step(amount)
		if @data.history.enabled
			@data.history.step amount
			@data.save
			cd_to path: @data.history.get_current, track: false
		else
			puts "history is not enabled"
		end
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

	def cd_to(path : String, track : Bool = true)
		if @data.history.enabled && track
			@data.history.push path
			@data.save
		end

		execute "cd #{path}"
	end
end

# Creates an instance of the class, invokes initialize()
SmartDirectory.new
