require "yaml"

# This class provides functionality for storing data in utility files,
# such as config and data.
class UtilFile
	include YAML::Serializable

	@[YAML::Field(ignore: true)]
	property dir_name : String | Nil

	@[YAML::Field(ignore: true)]
	property file_name : String | Nil
	
	private def initialize(@dir_name, @file_name)
	end

	# Attempts to read the yml from disk at the specified filepath.
	# If there is no file there, nothing will be read, and the defaults
	# (which should be implemented in classes extending UtilFile) will
	# not be changed.
	def self.load(dir_name, file_name)
		filepath = "#{dir_name}/#{file_name}"
		if File.exists? filepath
			puts typeof(self)
			instance = from_yaml File.read(filepath)
			instance.dir_name = dir_name
			instance.file_name = file_name
			return instance
		else
			return new(dir_name, file_name)
		end
	end

	# Serializes the UtilFile and writes it out to the specified filepath. If
	# the directory specified does not exist, it will be created before writing.
	# Similarly, the file will be created if it doesn't exist.
	def save
		# Create the directory if it doesn't already exist
		unless Dir.exists? @dir_name
			Dir.mkdir_p @dir_name
		end

		File.write filepath, self.to_yaml
	end

	# Returns the filepath, which is just a concatenation of the directory and
	# filename.
	def filepath
		"#{@dir_name}/#{@file_name}"
	end
end
