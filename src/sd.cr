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
			# Bind subcommands
			root.bind(word: "default", short_flag: 'd') do |sub|
				# Sets the default directory, falling back to the current directory if no path provided
				sub.fuzzy_bind(word: "set") do |sub|
					sub.grab do |sub, path|
						set_default path
					end

					sub.missing_args do |apex|
						set_default Dir.current
					end
				end

				# When `default` is called standalone, navigate to the default directory.
				sub.missing_args do |apex|
					navigate_to @data.default
				end
			end

			root.bind(word: "lock", short_flag: 'l') do |sub|
				# Disables locking.
				sub.fuzzy_bind(word: "disable") do |sub|
					disable_lock
					exit 0
				end

				# Enables locking, either to the current directory or to a provided key.
				sub.fuzzy_bind(word: "enable") do |sub| path = root.token_available? ? root.next_token : Dir.current
					enable_lock path
					exit 0
				end

				# Prints the status of the lock
				sub.fuzzy_bind(word: "status") do |sub|
					@data.lock.print_status
					exit 0
				end

				# If `lock` is called standalone, it will by default act the same as `sd lock enable`.
				sub.grab do |sub, path|
					enable_lock path
					exit 0
				end

				# If no path or subcommand was provided, enable lock in current dir.
				sub.missing_args do |apex|
					enable_lock Dir.current
					exit 0
				end
			end

			root.bind(word: "history", short_flag: 'h') do |sub|
				sub.fuzzy_bind(word: "enable") do |sub|
					@data.history.enabled = true
					@data.save
				end

				sub.fuzzy_bind(word: "disable") do |sub|
					@data.history.enabled = false
					@data.history.delete_all
					@data.save
				end

				sub.fuzzy_bind(word: "status") do |sub|
					@data.history.print_status
				end

				sub.fuzzy_bind(word: "jump") do |sub|
					# Jump back one step
					sub.fuzzy_bind(word: "back") do |sub|
						history_step -1 end

					# Jump forwards one step
					sub.fuzzy_bind(word: "next") do |sub|
						history_step 1
					end

					# Jump forwards by a specified increment
					sub.grab do |sub, value|
						begin
							amount = value.to_i32
							history_step amount
						rescue ex
							puts "Cannot jump by '#{value}'!"
						end
					end
				end
			end


			root.bind(word: "shortcut", short_flag: 's') do |sub|
				sub.fuzzy_bind(word: "create") do |sub|
					# Attempt to get the name
					sub.grab do |sub, name|
						# If the name was available, attempt to get the path to bind it to
						sub.grab do |sub, path|
							create_shortcut name, path
						end

						# If no path was provided, but a name was, bind the current directory to it.
						sub.missing_args do
							create_shortcut name, Dir.current
						end
					end
				end

				sub.fuzzy_bind(word: "delete") do |sub|
					sub.grab do |sub, name|
						delete_shortcut name
					end
				end

				sub.fuzzy_bind(word: "status") do |sub|
					print_shortcuts
				end
				
				# If a shortcut name is specified, navigate to it unambiguously (ignore local folders)
				sub.grab do |sub, name|
					navigate_to_shortcut name
				end
			end

			# Bind shortcut commands for frequent actions
			# Quick unlock
			root.bind(word: "unlock", short_flag: 'u') do |sub|
				disable_lock
				exit 0
			end

			# Takes one step back in history.
			root.bind(word: "back", short_flag: 'b') do |sub|
				history_step -1
			end

			# Takes one step forwards in the history.
			root.bind(word: "next", short_flag: 'n') do |sub|
				history_step 1
			end


			# If `sd` is called with a single parameter that didn't match any command, it's likely
			# being given a literal directory. Navigate to it.
			root.grab do |sub, path|
				navigate_to path
			end

			# If `sd` is called with no arguments, simply perform the default navigate action. (lock or default depending on state)
			root.default do
				navigate
			end

			root.missing_args do |apex|
				puts "Insufficient arguments were collected after `#{apex}`"
			end
			
			root.unrecognized_args do |name|
				puts "'#{name}' is not a recognized token."
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
