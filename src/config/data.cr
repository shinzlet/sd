require "yaml"
require "./util_file.cr"

# An object that allows access to a data file. In SmartDirectory,
# this is where directory aliases, project aliases, and lock settings
# are stored.
class Data < UtilFile
  class_getter filename = "sd.yml"

  @[YAML::Field(key: "default")]
  property default : String = Path.home.expand.to_s

  @[YAML::Field(key: "lock")]
  property lock : Lock = Lock.new

  @[YAML::Field(key: "shortcuts")]
  property shortcuts : Hash(String, String) = Hash(String, String).new

  @[YAML::Field(key: "history")]
  property history : History = History.new

  def self.load(dir : String)
    super(dir, @@filename)
  end
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

class History
  include YAML::Serializable

  def initialize
  end

  @[YAML::Field(key: "enabled")]
  property enabled : Bool = false

  @[YAML::Field(key: "max_size")]
  property max_size : UInt32 = 10

  @[YAML::Field(key: "log")]
  property log : Array(String) = [] of String

  @[YAML::Field(key: "index")]
  property index : UInt32 = 0

  def push(path)
    return if get_current == path
    log.push path
    @index = (log.size - 1).to_u32

    unless log.size <= max_size
      @index = @index - 1
      log.delete_at 0
    end
  end

  def step(amount : Number)
    new_index = @index + amount
    if new_index < 0
      @index = 0
    elsif new_index >= log.size
      @index = Math.max 0_u32, @log.size.to_u32 - 1_u32
    else
      @index = new_index
    end
  end

  def delete_all
    @index = 0
    @log = [] of String
  end

  def get_current
    return "" if @index >= log.size
    return log[@index]
  end
end
