module Lang
  {% if env("SD_LANG") == "en" %}
    # General help messages
    SD_BANNER = "Usage: `sd [arg1 | arg2] [...]`\n\
      Suffix any command with 'help' for usage information."
    HELP_DESC = "Displays this help menu."

    # Frequently used keywords
    HELP_KEYWORD = "help"
    SET_KEYWORD = "set"
    STATUS_KEYWORD = "status"
    ENABLE_KEYWORD = "enable"
    DISABLE_KEYWORD = "disable"
    # This flag is used to disambiguate a shortcut from a path.
    SHORTCUT_CHAR = 's'

    # Strings related to the 'default' subcommand
    DEFAULT_BANNER = "Set and manage the default directory. When invoked \
      with no arguments, `sd default` will navigate to the default \
      directory, ignoring shortcuts."
    DEFAULT_DESCRIPTION = "Navigate to or manage the default directory."
    DEFAULT_KEYWORD = "default"
    DEFAULT_CHAR = 'd'
    DEFAULT_SET_DESCRIPTION = "Sets the default directory to the given \
      location, or the current directory if no location is provided. \
      A location can be suffixed with -s to force interpretation as a \
      shortcut. (e.g. `sd default set -s ambiguous_name`)"
    DEFAULT_STATUS_DESCRIPTION = "Display the current default directory."
    DEFAULT_STATUS_MESSAGE = "Current default directory: "

    # Strings related to the 'lock' subcommand
    LOCK_BANNER = "Enable, disable, and view the status of directory locking. \
      When invoked without a valid subcommand, `sd lock` behaves like `sd \
      lock enable`."
    LOCK_DESCRIPTION = "Manage directory locking."
    LOCK_KEYWORD = "lock"
    LOCK_CHAR = 'l'
    LOCK_ENABLE_DESCRIPTION = "Enable the lock on a given path or shortcut. \
      If no path is given, lock to the current directory."
    LOCK_DISABLE_DESCRIPTION = "Disable directory locking."
    LOCK_STATUS_DESCRIPTION = "Display the current state of the lock."
    LOCK_STATUS_NOT_LOCKED_MESSAGE = "No directory is currently locked."
    LOCK_STATUS_LOCKED_MESSAGE = "Current lock directory: "
  {% end %}
end
