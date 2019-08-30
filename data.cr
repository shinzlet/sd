require "yaml"
require "./util_file.cr"

# An object that allows access to a data file. In SmartDirectory,
# this is where directory aliases, project aliases, and lock settings
# are stored.
class Data < UtilFile
	@@filename = "data.yml"

	@[YAML::Field(key: "default")]
	property default : String | Nil = nil

	@[YAML::Field(key: "lock")]
	property lock : Lock = Lock.new
end

class Lock
	include YAML::Serializable

	def initialize
	end

	@[YAML::Field(key: "locked")]
	property locked : Bool = false

	@[YAML::Field(key: "location")]
	property location : String = "/"
end
