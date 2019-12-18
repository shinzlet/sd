# This module declares help text and commands in one location.
# A macro is used to change help messages between compilation languages.
# Note that `_KEYWORD_` or `_CHAR` strings are NOT locale specific by
# design, and should be constant across all versions of SD. This is due
# to compatibility concerns - sd usage should be identical across all
# systems, even if the language of the help menus are distinct.
module Lang
  # Frequently used keywords
  HELP_KEYWORD    = "help"
  SET_KEYWORD     = "set"
  STATUS_KEYWORD  = "status"
  ENABLE_KEYWORD  = "enable"
  DISABLE_KEYWORD = "disable"
  CREATE_KEYWORD  = "create"
  DELETE_KEYWORD  = "delete"

  # This flag is used to disambiguate a shortcut from a path.
  SHORTCUT_CHAR = 's'

  DEFAULT_CHAR      = 'd'
  DEFAULT_KEYWORD   = "default"
  LOCK_CHAR         = 'l'
  LOCK_KEYWORD      = "lock"
  UNLOCK_KEYWORD    = "unlock"
  HISTORY_CHAR      = 'H'
  HISTORY_KEYWORD   = "history"
  JUMP_KEYWORD      = "jump"
  JUMP_NEXT_KEYWORD = "next"
  JUMP_BACK_KEYWORD = "back"
  JUMP_BACK_REGEX   = /^[bB]/
  JUMP_NEXT_REGEX   = /^[nN]/
  SHORTCUT_KEYWORD  = "shortcut"

  {% if env("SD_LANG") == "en" %}
    # General help messages
    SD_BANNER = "Usage: `sd [arg1 | arg2] [...]`\n\
      Suffix any command with 'help' for usage information."
    HELP_DESC         = "Displays this help menu."
    MISSING_ARGS      = "Arguments were missing after '%s'\n"
    UNRECOGNIZED_ARGS = "'%s' is an unrecognized argument.\n"

    # Strings related to the 'default' subcommand
    DEFAULT_BANNER = "Set and manage the default directory. When invoked \
      with no arguments, `sd default` will navigate to the default \
      directory, ignoring shortcuts."
    DEFAULT_DESCRIPTION     = "Navigate to or manage the default directory."
    DEFAULT_SET_DESCRIPTION = "Sets the default directory to the given \
      location, or the current directory if no location is provided. \
      A location can be suffixed with -s to force interpretation as a \
      shortcut. (e.g. `sd default set -s ambiguous_name`)"
    DEFAULT_STATUS_DESCRIPTION = "Display the current default directory."
    DEFAULT_STATUS_MESSAGE     = "Current default directory: %s\n"

    # Strings related to the 'lock' subcommand
    LOCK_BANNER = "Enable, disable, and view the status of directory locking. \
      When invoked without a valid subcommand, `sd lock` behaves like `sd \
      lock enable`."
    LOCK_DESCRIPTION        = "Manage directory locking."
    LOCK_ENABLE_DESCRIPTION = "Enable the lock on a given path or shortcut. \
      If no path is given, lock to the current directory."
    LOCK_DISABLE_DESCRIPTION       = "Disable directory locking."
    LOCK_STATUS_DESCRIPTION        = "Display the current state of the lock."
    LOCK_STATUS_NOT_LOCKED_MESSAGE = "No directory is currently locked."
    LOCK_STATUS_LOCKED_MESSAGE     = "Current lock directory: %s\n"

    # Strings related to the 'jump' subcommand.
    JUMP_DESCRIPTION = "Jump to a directory in the history log \
      by navigating forwards (jump [nN]), backwards (jump [bB]), \
      or by an arbitrary step size (jump [+-]3). (alias to `sd jump`)"
    JUMP_AMOUNT_ERROR = "Error! Cannot jump by '%s'\n"

    # Strings related to the 'history' subcommand
    HISTORY_BANNER              = "View, control, and traverse navigation history."
    HISTORY_DESCRIPTION         = "View, control, and traverse navigation history."
    HISTORY_ENABLE_DESCRIPTION  = "Enables history tracking."
    HISTORY_DISABLE_DESCRIPTION = "Disables history tracking, clearing \
      history."
    HISTORY_STATUS_DESCRIPTION = "Pretty-prints the history log, indicating \
      the current index in history with a small arrow prefix."
    HISTORY_JUMP_DESCRIPTION = JUMP_DESCRIPTION + " (alias to `sd jump`)"

    # Strings related to the 'shortcut' subcommand
    SHORTCUT_BANNER = "Create, delete, and view directory shortcuts. If a \
      shortcut name is provided immediately after 'shortcut', it will be \
      unabiguously navigated to (even if there is a directory with the same \
      name in the current scope)."
    SHORTCUT_DESCRIPTION        = "Manage and navigate to directory shortcuts."
    SHORTCUT_CREATE_DESCRIPTION = "Create a shortcut given a name and path in \
      that order ('create NAME PATH'). If no path is provided, a shortcut \
      will be created to the current directory."
    SHORTCUT_DELETE_DESCRIPTION = "Delete a shortcut by name."
    SHORTCUT_STATUS_DESCRIPTION = "Display all existing shortcuts."

    # Strings for top level aliases
    ALIAS_LOCK_DESCRIPTION   = "Alias to `lock enable`."
    ALIAS_UNLOCK_DESCRIPTION = "Alias to `lock disable`."
    ALIAS_NEXT_DESCRIPTION   = "Alias to `jump next`"
    ALIAS_BACK_DESCRIPTION   = "Alias to `jump back`"
  {% end %}
end
