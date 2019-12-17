require "option_parser"
require "yaml"
require "phreak"

require "./config/data.cr"

# Implements all the backend functionality of SD. Note that this class
# relies heavily on dependency injection - most methods require the SD
# data file to be used to be passed in as a parameter.
# The methods in this class will print to STDOUT as needed in order to
# communicate invalid paths / usage errors to the user.
class SD
	# Run a piece of code only if the DEBUG environment variable is set to
	# "enabled".
	macro debug(code)
		{% if env("DEBUG") == "enabled" %}
			{{ code }}
		{% end %}
	end

	# Pretty-prints only if this is a debug build.
	macro dbp(obj)
		debug p {{ obj }}
	end

	# Given an ambiguous location, which may be a shortcut or a
	# filepath, return a filepath. If the location string is a
	# valid shortcut *and* filesystem path, it is assumed that
	# the path was meant, not the shortcut.
	def self.resolve_path(data : Data, location : String)
		dbp "resolve_path: #{data}, #{location}"
	end
	
	# Set the default directory for SD to use. The default directory is
	# where sd will nagivate to by default when the lock is disabled. Uses the
	# same inferece rules as `SD#set_default`.
	def self.set_default(data : Data, path : String, shortcut : Bool? = nil)
		dbp "set_default: #{data}, #{path}, #{shortcut}"
	end

	# Return the default directory indicated in the SD data file.
	def self.get_default(data : Data) : String
		dbp "get_default: #{data}"
		"xoxoxo"
	end

	# Navigates to the provided location. If `shortcut` is true or false, rather
	# than `nil`, the location will be interpreted as a shortcut or filesystem
	# path as specified. Otherwise, the location meaning will be inferred using
	# `SD#resolve_path`.
	def self.navigate(data : Data, location : String, shortcut : Bool? = nil)
		dbp "navigate: #{data}, #{location}, #{shortcut}"
	end

	# Enables the lock in the SD datafile, setting it to a provided location.
	# This function uses the same shortcut/path inference as `SD#navigate`.
	def self.lock_to(data : Data, location : String, shortcut : Bool? = nil)
		dbp "lock_to: #{data}, #{location}, #{shortcut}"
	end

	# Disables the lock in the provided SD datafile.
	def self.disable_lock(data : Data)
		dbp "disable_lock: #{data}"
	end

	# Returns the path which is locked in the SD datafile. If no path has lock,
	# returns null.
	def self.get_lock_dir(data : Data) : String?
		dbp "get_lock_dir: #{data}"
	end

	# Enables history collection in the SD data file.
	def self.enable_history(data : Data)
		dbp "enable_history: #{data}"
	end

	# Disables history collection in the SD data file.
	def self.disable_history(data : Data)
		dbp "disable_history: #{data}"
	end

	# Returns an array of all locations stored in the datafile's directory
	# history. A larger index means an entry is more recent.
	def self.get_history(data : Data) : Array(String)
		dbp "get_history: #{data}"
		["dir1", "dir2", "dir3"]
	end

	# Returns the history index in the SD datafile.
	def self.get_history_index(data : Data) : UInt32
		dbp "get_history_index: #{data}"
		return 0_u32
	end

	# Jumps by a specified amount in the history.
	def self.jump(data : Data, step_size : Int32)
		dbp "jump: #{data}, #{step_size}"
	end
end
