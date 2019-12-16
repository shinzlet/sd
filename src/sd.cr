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
	# Given an ambiguous location, which may be a shortcut or a
	# filepath, return a filepath. If the location string is a
	# valid shortcut *and* filesystem path, it is assumed that
	# the path was meant, not the shortcut.
	def self.resolve_path(data : Data, location : String)
	end
	
	# Set the default directory for SD to use. The default directory is
	# where sd will nagivate to by default when the lock is disabled. Uses the
	# same inferece rules as `SD#set_default`.
	def self.set_default(data : Data, path : String, shortcut : Bool? = nil)
	end

	# Return the default directory indicated in the SD data file.
	def self.get_default(data : Data) : String
		"xoxoxo"
	end

	# Navigates to the provided location. If `shortcut` is true or false, rather
	# than `nil`, the location will be interpreted as a shortcut or filesystem
	# path as specified. Otherwise, the location meaning will be inferred using
	# `SD#resolve_path`.
	def self.navigate(data : Data, location : String, shortcut : Bool? = nil)
	end

	# Enables the lock in the SD datafile, setting it to a provided location.
	# This function uses the same shortcut/path inference as `SD#navigate`.
	def self.lock_to(data : Data, location : String, shortcut : Bool? = nil)
	end

	# Disables the lock in the provided SD datafile.
	def self.disable_lock(data : Data)
	end

	# Returns the path which is locked in the SD datafile. If no path has lock,
	# returns null.
	def self.get_lock_dir(data : Data) : String?
	end
end
