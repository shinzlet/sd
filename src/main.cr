require "phreak"

require "./sd.cr"
require "./config/data.cr"
require "./lang.cr"

include Lang

# This is the main class, so this top-level code is what sd actually runs
# on invocation.
config_dir : String = Path["~/.config/sd"].expand.to_s
data : Data = Data.load(config_dir)

# Note: calls to `exit` are used liberally and redundantly throughout this code
# to prevent complex behaviour arising from bulk execution.
Phreak.parse! do |root|
  root.banner = SD_BANNER
  root.bind(word: DEFAULT_KEYWORD, description: DEFAULT_DESCRIPTION) do |sub|
    on_default(data, sub)
    exit
  end

  root.bind(word: LOCK_KEYWORD, description: LOCK_DESCRIPTION) do |sub|
    on_lock(data, sub)
    exit
  end

  root.bind(word: HELP_KEYWORD, description: HELP_DESC) do
    puts root
    exit
  end

  root.bind(word: STATUS_KEYWORD,
    description: DEFAULT_STATUS_DESCRIPTION) do |sub|
    puts DEFAULT_STATUS_MESSAGE + SD.get_default(data)
  end
end

# Binds a `default` command to the given subparser.
def on_default(data, root)
  root.banner = DEFAULT_BANNER

  root.bind(word: SET_KEYWORD,
    description: DEFAULT_SET_DESCRIPTION) do |sub|
    shortcut : Bool? = nil
    sub.bind(short_flag: SHORTCUT_CHAR) do
      shortcut = true
    end

    sub.grab do |sub, path|
      SD.set_default(data, path, shortcut)
      exit
    end

    sub.missing_args do
      SD.set_default(data, Dir.current)
      exit
    end
  end

  root.bind(word: HELP_KEYWORD, description: HELP_DESC) do
    puts root
    exit
  end

  root.missing_args do
    SD.navigate(data, SD.get_default(data), shortcut: true)
    exit
  end
end

# Binds a `lock` command to the given subparser.
def on_lock(data, root)
  root.banner = LOCK_BANNER

  root.bind(word: ENABLE_KEYWORD, 
    description: LOCK_ENABLE_DESCRIPTION) do |sub|
    shortcut : Bool? = nil
    sub.bind(short_flag: SHORTCUT_CHAR) do
      shortcut = true
    end

    sub.grab do |sub, path|
      SD.lock_to(data, path, shortcut)
      exit
    end

    sub.missing_args do
      SD.lock_to(data, Dir.current, shortcut: false)
      exit
    end
  end

  root.bind(word: DISABLE_KEYWORD,
    description: LOCK_DISABLE_DESCRIPTION) do |sub|
    SD.disable_lock(data)
    exit
  end

  root.bind(word: STATUS_KEYWORD) do |sub|
    if path = SD.get_lock_dir(data)
      puts LOCK_STATUS_LOCKED_MESSAGE + path
    else
      puts LOCK_STATUS_NOT_LOCKED_MESSAGE
    end

    exit
  end

  root.bind(word: HELP_KEYWORD, description: HELP_DESC) do
    puts root
    exit
  end

  root.grab do |sub, location|
    SD.lock_to(data, Dir.current)
    exit
  end

  root.missing_args do
    SD.lock_to(data, Dir.current, shortcut: false)
    exit
  end
end
