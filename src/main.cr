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
  end

  root.bind(word: LOCK_KEYWORD, description: LOCK_DESCRIPTION) do |sub|
    on_lock(data, sub)
  end

  root.bind(word: HISTORY_KEYWORD, description: HISTORY_DESCRIPTION) do |sub|
	 on_history(data, sub)
  end

  root.bind(word: JUMP_KEYWORD,
	 description: JUMP_DESCRIPTION) do |sub|
	 on_jump(data, sub)
  end

  root.bind(word: HELP_KEYWORD, description: HELP_DESC) do
    puts root
    exit
  end

  root.missing_args do |apex|
	 printf(MISSING_ARGS, apex)
	 exit
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
  
  root.bind(word: STATUS_KEYWORD,
    description: DEFAULT_STATUS_DESCRIPTION) do |sub|
    printf(DEFAULT_STATUS_MESSAGE, SD.get_default(data))
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
      printf(LOCK_STATUS_LOCKED_MESSAGE, path)
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

def on_history(data, root)
  root.banner = HISTORY_BANNER
  
  root.bind(word: ENABLE_KEYWORD,
	 description: HISTORY_ENABLE_DESCRIPTION) do |sub|
	 SD.enable_history(data)
	 exit
  end

  root.bind(word: DISABLE_KEYWORD,
	 description: HISTORY_DISABLE_DESCRIPTION) do |sub|
	 SD.disable_history(data)
	 exit
  end

  root.bind(word: STATUS_KEYWORD,
	 description: HISTORY_STATUS_DESCRIPTION) do |sub|
	 entries = SD.get_history(data)
	 current_index = SD.get_history_index(data)

	 current_prefix = "-> "
	 blank_prefix = " " * current_prefix.size

	 entries.each_index do |index|
		if index == current_index
		  printf current_prefix
		else
		  printf blank_prefix
		end

		puts "#{index}: #{entries[index]}"
	 end
  end
  
  # We want to be able to invoke `history jump` as an alias to `jump`.
  root.bind(word: JUMP_KEYWORD,
	 description: HISTORY_JUMP_DESCRIPTION) do |sub|
	 on_jump(data, sub)
  end

  root.bind(word: HELP_KEYWORD,
	 description: HELP_DESC) do |sub|
	 puts root
	 exit
  end
end

# This is a standalone command, but is also used by `history`.
def on_jump(data, root)
  root.grab do |sub, value|
	 amount = 0

	 case value
		# Matches strings like 'back'
		when /^[bB]/
		  amount = -1
		# Matches strings like 'next'
		when /^[nN]/
		  amount = 1
		# Matches integers or garbage values
		else
		  begin
			 amount = value.to_i32
		  rescue ex
			 printf(JUMP_AMOUNT_ERROR, value)
			 exit
		  end
	 end

	 SD.jump(data, amount)
	 exit
  end
end
