require "option_parser"
require "yaml"
require "phreak"
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

		Phreak.parse! do |root|
			root.bind(word: "default", short_flag: 'd') do |sub|
				sub.fuzzy_bind(word: "set") do |sub|
					sub.grab do |sub, path|
						set_default path
					end

					sub.insufficient_arguments do |apex|
						set_default Dir.current
					end
				end

				sub.insufficient_arguments do |apex|
					navigate_to @data.default
				end
			end

			root.bind(word: "lock", short_flag: 'l') do |sub|
				sub.fuzzy_bind(word: "disable") do |sub|
					disable_lock
					exit 0
				end

				sub.fuzzy_bind(word: "enable") do |sub|
					path = root.token_available? ? root.next_token : Dir.current
					enable_lock path
					exit 0
				end

				sub.fuzzy_bind(word: "status") do |sub|
					@data.lock.print_status
					exit 0
				end

				# By default, `sd lock` = `sd lock enable`
				sub.grab do |sub, path|
					enable_lock path
					exit 0
				end

				# If no path or subcommand was provided, enable lock in current dir.
				sub.insufficient_arguments do |apex|
					enable_lock Dir.current
					exit 0
				end
			end

			root.bind(word: "unlock", short_flag: 'u') do |sub|
				disable_lock
				exit 0
			end

			root.bind(word: "back", short_flag: 'b') do |sub|
				history_step -1
			end

			root.bind(word: "next", short_flag: 'n') do |sub|
				history_step 1
			end

			root.bind(word: "jump", short_flag: 'n') do |sub|
				sub.fuzzy_bind(word: "back") do |sub|
					history_step -1
				end

				sub.fuzzy_bind(word: "next") do |sub|
					history_step 1
				end

				sub.grab do |sub, value|
					begin
						amount = value.to_i32
						history_step amount
					rescue ex
						puts "Cannot jump by '#{value}'!"
					end
				end
			end

			root.grab do |sub, path|
				navigate_to path
			end

			root.default do
				navigate
			end

			root.insufficient_arguments do |apex|
				puts "Insufficient arguments were collected after `#{apex}`"
			end
			
			root.unrecognized_arguments do |name|
				puts "'#{name}' is not a recognized token."
			end
		end

		# OptionParser.parse! do |parser|
		# 	parser.on(long_flag: "--create-shortcut NAME DIR", short_flag: "-s NAME DIR", description: "Creates a shortcut with the given name and directory. If the directory is not specified, the current directory is used.") do |name|
		# 		if ARGV.size > 0
		# 			if Dir.exists? (path = ARGV.delete_at(0))
		# 				create_shortcut name, path
		# 			else
		# 				puts "Refusing to create shortcut for non-existent path '#{path}'."
		# 			end
		# 		else
		# 			create_shortcut name, ENV["PWD"]
		# 		end
		# 		exit 0
		# 	end

		# 	parser.on(long_flag: "--delete-shortcut NAME", short_flag: "-x NAME", description: "Deletes the shortcut with a given name, if it exists.") do |name|
		# 		delete_shortcut name
		# 		exit 0
		# 	end

		# 	parser.on(long_flag: "--shortcut NAME", short_flag: "-n NAME", description: "Forces sd to recognize NAME as a shortcut, not a local directory.") do |name|
		# 		navigate_to_shortcut name
		# 		exit 0
		# 	end

		# 	parser.on(long_flag: "--shortcuts", short_flag: "-p", description: "Prints a list of all exisiting shortcuts.") do
		# 		print_shortcuts
		# 		exit 0
		# 	end

		# 	parser.on(long_flag: "--use-history BOOL", short_flag: "-h BOOL", description: "Enables or disables the use of history logging.") do |bool|
		# 		if bool == "true"
		# 			@data.history.enabled = true
		# 		elsif bool == "false"
		# 			@data.history.enabled = false
		# 			@data.history.delete_all
		# 			@data.save
		# 		else
		# 			puts "Expected true or false, read '#{bool}'. Failed to set history state."
		# 			exit 1
		# 		end

		# 		@data.save
		# 		exit 0
		# 	end

		# 	parser.on(long_flag: "--history-status", short_flag: "-H", description: "Prints the logged directory history.") do
		# 		@data.history.print_status
		# 		exit 0
		# 	end

		# 	parser.on(long_flag: "--foward", short_flag: "-f", description: "Steps forwards in history, if it is enabled.") do
		# 		history_step 1
		# 	end

		# 	parser.on(long_flag: "--back", short_flag: "-b", description: "Steps backwards in history, if it is enabled.") do
		# 		history_step -1
		# 	end

		# 	parser.on(long_flag: "--jump AMOUNT", short_flag: "-j AMOUNT", description: "Jumps in history by AMOUNT steps. Positive for forward, negative for backward.") do |amount|
		# 		begin
		# 			history_step amount.to_i32
		# 		rescue ex
		# 			puts "failed to step in history - '#{amount}' is not an integer."
		# 		end
		# 	end
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
