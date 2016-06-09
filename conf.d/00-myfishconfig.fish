# Environment varialbes {{{
set -x LC_ALL en_US.UTF-8
set -x LANG en_US.UTF-8

test -d "$HOME/bin"; and set -x PATH "$HOME/bin" $PATH
test -d "$HOME/.cabal/bin"; and set -x PATH "$HOME/.cabal/bin" $PATH
test -d "$HOME/.pyenv"; and set -x PATH "$HOME/.pyenv/bin" $PATH
test -d "$HOME/.rvm/bin"; and set -x PATH "$HOME/.rvm/bin" $PATH
# }}}

# Color {{{
if begin echo "$COLORTERM" | grep -q "^gnome-"; and [ "$TERM" = xterm ]; \
        and infocmp gnome-256color >/dev/null 2>&1; end
    set -gx TERM gnome-256color
else if infocmp xterm-256color >/dev/null 2>&1
    set -gx TERM xterm-256color
end
# }}}

# Functions {{{
function l; tree --dirsfirst -aFCNL 1 $argv; end
function ll; tree --dirsfirst -ChFupDaLg 1 $argv; end
function mkdircd; mkdir -p "$argv[1..-1]"; and cd "$argv[1..-1]"; end
# }}}

# Tmux {{{
if [ $TMUX ]
    set -g PROMPT_COMMAND 'echo -ne "\033k[(prompt_pwd)]\033\\"'
end
# }}}

# Go {{{
set -x GOPATH "$HOME/.go"
set -x GOBIN "$GOPATH/bin"
test -d "$GOBIN"; and set -x PATH "$GOBIN" $PATH
# }}}

# Darwin specific tweaks {{{
if [ (uname) = Darwin ]
    # ls color
    alias ls='ls -G'
    # updatedb
    alias updatedb='sudo /usr/libexec/locate.updatedb'
end
# }}}

# Android Studio {{{
test -d "$HOME/sdk/android-sdk-linux"; \
    and set -x PATH "$HOME/sdk/android-sdk-linux/tools" "$HOME/sdk/android-sdk-linux/platform-tools" $PATH; \
    and set -x ANDROID_HOME "$HOME/sdk/android-sdk-linux"
test -d "$HOME/Library/Android/sdk"; \
    and set -x PATH "$HOME/Library/Android/sdk/tools" "$HOME/Library/Android/sdk/platform-tools" $PATH; \
    and set -x ANDROID_HOME "$HOME/Library/Android/sdk"
# }}}

# Java {{{
test -d /usr/lib/jvm/java-7-oraclea; \
    and set -x JAVA7_HOME /usr/lib/jvm/java-7-oracle
test -d "/Library/Java/JavaVirtualMachines/jdk1.7"*".jdk/Contents/Home"; \
    and set -x JAVA7_HOME (echo "/Library/Java/JavaVirtualMachines/jdk1.7"*".jdk/Contents/Home")
test -d /usr/lib/jvm/java-8-oracle; \
    and set -x JAVA8_HOME /usr/lib/jvm/java-8-oracle
test -d "/Library/Java/JavaVirtualMachines/jdk1.8"*".jdk/Contents/Home"; \
    and set -x JAVA8_HOME (echo "/Library/Java/JavaVirtualMachines/jdk1.8"*".jdk/Contents/Home")
if [ "$JAVA8_HOME" ]
    set -gx JAVA_HOME "$JAVA8_HOME"
else if [ "$JAVA7_HOME" ]
    set -gx JAVA_HOME "$JAVA7_HOME"
end
# }}}

# gpg-agent {{{
function __get_gpg_agent_sock
  set --local __gpg_agent_info_file "$argv[1]"
  cat "$__gpg_agent_info_file" | while read --local line
    if echo -n "$line" | grep -q "S\.gpg-agent" > /dev/null 2>&1
      echo -n "$line" | sed 's/.*\(\/tmp\/gpg.*\/S\.gpg-agent\).*/\1/'
      break
    end
  end
end

function __get_gpg_agent_info
  set --local __gpg_agent_info_file "$argv[1]"
  cat "$__gpg_agent_info_file" | while read --local line
    if echo -n "$line" | grep -q "S\.gpg-agent" > /dev/null 2>&1
      echo -n "$line" | sed 's/GPG_AGENT_INFO=//' | sed 's/; export GPG_AGENT_INFO;//'
      break
    end
  end
end

set __gpg_agent_info_file "$HOME/.gpg-agent-info"

if test -f "$__gpg_agent_info_file"
  set --local __gpg_agent_info (__get_gpg_agent_info "$__gpg_agent_info_file")
  set --local __gpg_agent_sock (__get_gpg_agent_sock "$__gpg_agent_info_file")
  if test -S "$__gpg_agent_sock"
    set --export --global GPG_AGENT_INFO "$__gpg_agent_info"
  else
    set --erase --unexport GPG_AGENT_INFO
  end
else
  if test -n "$GPG_AGENT_INFO"
    set --local __gpg_agent_sock (__get_gpg_agent_sock <(echo -n $GPG_AGENT_INFO))
    if not test -S "$__gpg_agent_sock"
      set --erase --unexport GPG_AGENT_INFO
    end
  end
end

if test -z "$GPG_AGENT_INFO"
  rm -rf "$__gpg_agent_info_file"
  pgrep -U (id -u) "gpg-agent" | while read --local line
    kill "$line"
  end
  set --local __gpg_agent_info (gpg-agent --daemon --sh --default-cache-ttl 7200)
  if test -z "$__gpg_agent_info"
    if test -S "$HOME/.gnupg/S.gpg-agent"
      set __gpg_agent_info "$HOME/.gnupg/S.gpg-agent"
    end
  end
  if test -n "$__gpg_agent_info"
    echo -n "$__gpg_agent_info" > "$__gpg_agent_info_file"
    set --export --global GPG_AGENT_INFO "$__gpg_agent_info"
  end
end

set --erase __gpg_agent_info_file
functions --erase __get_gpg_agent_sock
functions --erase __get_gpg_agent_info
# }}}
