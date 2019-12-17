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

  root.bind(word: JUMP_KEYWORD, description: JUMP_DESCRIPTION) do |sub|
	 on_jump(data, sub)
  end

  root.bind(word: SHORTCUT_KEYWORD, description: SHORTCUT_DESCRIPTION) do |sub|
	 on_shortcut(data, sub)
  end

  root.bind(word: LOCK_KEYWORD, description: ALIAS_LOCK_DESCRIPTION) do |sub|
	 sub.grab do |sub, location|
		SD.lock_to(data, location)
		exit
	 end
  end

  root.bind(word: UNLOCK_KEYWORD, description: ALIAS_UNLOCK_DESCRIPTION) do
	 SD.disable_lock(data)
	 exit
  end

  root.bind(word: JUMP_NEXT_KEYWORD, description: ALIAS_NEXT_DESCRIPTION) do
	 SD.jump(data, 1)
	 exit
  end

  root.bind(word: JUMP_BACK_KEYWORD, description: ALIAS_BACK_DESCRIPTION) do
	 SD.jump(data, -1)
	 exit
  end

  root.bind(word: HELP_KEYWORD, description: HELP_DESC) do
    puts root
    exit
  end

  root.grab do |sub, location|
	 SD.navigate(data, location)
	 exit
  end

  root.default do
	 SD.navigate(data, SD.get_default(data), shortcut: false)
	 exit
  end

  root.missing_args do |apex|
	 printf(MISSING_ARGS, apex)
	 exit
  end

  root.unrecognized_args do |arg|
	 printf(UNRECOGNIZED_ARGS, arg)
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
    SD.lock_to(data, location)
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
		when JUMP_BACK_REGEX
		  amount = -1
		# Matches strings like 'next'
		when JUMP_NEXT_REGEX
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

def on_shortcut(data, root)
  root.banner = SHORTCUT_BANNER

  root.bind(word: CREATE_KEYWORD,
	 description: SHORTCUT_CREATE_DESCRIPTION) do |sub|
	 # Attempt to get the shortcut name
	 sub.grab do |sub, name|
		# If there is a provided path, we want to use that to create the
		# shortcut
		sub.grab do |sub, path|
		  SD.create_shortcut(data, name, path)
		  exit
		end

		# If no path was provided, use the current directory instead
		sub.missing_args do
		  SD.create_shortcut(data, name, Dir.current)
		  exit
		end
	 end
  end

  root.bind(word: DELETE_KEYWORD,
	 description: SHORTCUT_DELETE_DESCRIPTION) do |sub|
	 sub.grab do |sub, name|
		SD.delete_shortcut(data, name)
		exit
	 end
  end

  root.bind(word: STATUS_KEYWORD,
	 description: SHORTCUT_STATUS_DESCRIPTION) do |sub|
	 shortcuts = SD.get_shortcuts(data)
	 shortcuts.each do |name, path|
		puts "#{name} -> #{path}"
	 end
	 exit
  end

  root.grab do |sub, name|
	 SD.navigate(data, name, shortcut: true)
	 exit
  end
end
