# frozen_string_literal: true

raise "HOMEBREW_BREW_FILE was not exported! Please call bin/brew directly!" unless ENV["HOMEBREW_BREW_FILE"]

std_trap = trap("INT") { exit! 130 } # no backtrace thanks

# check ruby version before requiring any modules.
RUBY_X, RUBY_Y, = RUBY_VERSION.split(".").map(&:to_i)
if RUBY_X < 2 || (RUBY_X == 2 && RUBY_Y < 6)
  raise "Homebrew must be run under Ruby 2.6! You're running #{RUBY_VERSION}."
end

# Load Bundler first of all if it's needed to avoid Gem version conflicts.
if ENV["HOMEBREW_INSTALL_BUNDLER_GEMS_FIRST"]
  require_relative "utils/gems"
  Homebrew.install_bundler_gems!
end

# Also define here so we can rescue regardless of location.
class MissingEnvironmentVariables < RuntimeError; end

begin
  require_relative "global"
rescue MissingEnvironmentVariables => e
  raise e if ENV["HOMEBREW_MISSING_ENV_RETRY"]

  if ENV["HOMEBREW_DEVELOPER"]
    $stderr.puts <<~EOS
      Warning: #{e.message}
      Retrying with `exec #{ENV["HOMEBREW_BREW_FILE"]}`!
    EOS
  end

  ENV["HOMEBREW_MISSING_ENV_RETRY"] = "1"
  exec ENV["HOMEBREW_BREW_FILE"], *ARGV
end

def output_unsupported_error
  $stderr.puts <<~EOS
    Please create pull requests instead of asking for help on Homebrew's GitHub,
    Discourse, Twitter or IRC.
  EOS
end

begin
  trap("INT", std_trap) # restore default CTRL-C handler

  empty_argv = ARGV.empty?
  help_flag_list = %w[-h --help --usage -?]
  help_flag = !ENV["HOMEBREW_HELP"].nil?
  cmd = nil

  ARGV.each_with_index do |arg, i|
    break if help_flag && cmd

    if arg == "help" && !cmd
      # Command-style help: `help <cmd>` is fine, but `<cmd> help` is not.
      help_flag = true
    elsif !cmd && !help_flag_list.include?(arg)
      cmd = ARGV.delete_at(i)
      cmd = Commands::HOMEBREW_INTERNAL_COMMAND_ALIASES.fetch(cmd, cmd)
    end
  end

  path = PATH.new(ENV["PATH"])
  homebrew_path = PATH.new(ENV["HOMEBREW_PATH"])

  # Add SCM wrappers.
  path.prepend(HOMEBREW_SHIMS_PATH/"scm")
  homebrew_path.prepend(HOMEBREW_SHIMS_PATH/"scm")

  ENV["PATH"] = path

  require "commands"

  if cmd
    internal_cmd = Commands.valid_internal_cmd?(cmd)
    internal_cmd ||= begin
      internal_dev_cmd = Commands.valid_internal_dev_cmd?(cmd)
      if internal_dev_cmd && !Homebrew::EnvConfig.developer?
        if (HOMEBREW_REPOSITORY/".git/config").exist?
          system "git", "config", "--file=#{HOMEBREW_REPOSITORY}/.git/config",
                 "--replace-all", "homebrew.devcmdrun", "true"
        end
        ENV["HOMEBREW_DEV_CMD_RUN"] = "1"
      end
      internal_dev_cmd
    end
  end

  unless internal_cmd
    # Add contributed commands to PATH before checking.
    homebrew_path.append(Tap.cmd_directories)

    # External commands expect a normal PATH
    ENV["PATH"] = homebrew_path
  end

  # Usage instructions should be displayed if and only if one of:
  # - a help flag is passed AND a command is matched
  # - a help flag is passed AND there is no command specified
  # - no arguments are passed
  # - if cmd is Cask, let Cask handle the help command instead
  if (empty_argv || help_flag) && cmd != "cask"
    require "help"
    Homebrew::Help.help cmd, empty_argv: empty_argv
    # `Homebrew.help` never returns, except for unknown commands.
  end

  if internal_cmd || Commands.external_ruby_v2_cmd_path(cmd)
    Homebrew.send Commands.method_name(cmd)
  elsif (path = Commands.external_ruby_cmd_path(cmd))
    require?(path)
    exit Homebrew.failed? ? 1 : 0
  elsif Commands.external_cmd_path(cmd)
    %w[CACHE LIBRARY_PATH].each do |env|
      ENV["HOMEBREW_#{env}"] = Object.const_get("HOMEBREW_#{env}").to_s
    end
    exec "brew-#{cmd}", *ARGV
  else
    possible_tap = OFFICIAL_CMD_TAPS.find { |_, cmds| cmds.include?(cmd) }
    possible_tap = Tap.fetch(possible_tap.first) if possible_tap

    odie "Unknown command: #{cmd}" if !possible_tap || possible_tap.installed?

    # Unset HOMEBREW_HELP to avoid confusing the tap
    ENV.delete("HOMEBREW_HELP") if help_flag
    tap_commands = []
    cgroup = Utils.popen_read("cat", "/proc/1/cgroup")
    if %w[azpl_job actions_job docker garden kubepods].none? { |container| cgroup.include?(container) }
      brew_uid = HOMEBREW_BREW_FILE.stat.uid
      tap_commands += %W[/usr/bin/sudo -u ##{brew_uid}] if Process.uid.zero? && !brew_uid.zero?
    end
    tap_commands += %W[#{HOMEBREW_BREW_FILE} tap #{possible_tap.name}]
    safe_system(*tap_commands)
    ENV["HOMEBREW_HELP"] = "1" if help_flag
    exec HOMEBREW_BREW_FILE, cmd, *ARGV
  end
rescue UsageError => e
  require "help"
  Homebrew::Help.help cmd, usage_error: e.message
rescue SystemExit => e
  onoe "Kernel.exit" if Homebrew.args.debug? && !e.success?
  $stderr.puts e.backtrace if Homebrew.args.debug?
  raise
rescue Interrupt
  $stderr.puts # seemingly a newline is typical
  exit 130
rescue BuildError => e
  Utils::Analytics.report_build_error(e)
  e.dump

  output_unsupported_error if Homebrew.args.HEAD? || e.formula.deprecated? || e.formula.disabled?

  exit 1
rescue RuntimeError, SystemCallError => e
  raise if e.message.empty?

  onoe e
  $stderr.puts e.backtrace if Homebrew.args.debug?

  output_unsupported_error if Homebrew.args.HEAD?

  exit 1
rescue MethodDeprecatedError => e
  onoe e
  if e.issues_url
    $stderr.puts "If reporting this issue please do so at (not Homebrew/brew or Homebrew/core):"
    $stderr.puts "  #{Formatter.url(e.issues_url)}"
  end
  $stderr.puts e.backtrace if Homebrew.args.debug?
  exit 1
rescue Exception => e # rubocop:disable Lint/RescueException
  onoe e
  if internal_cmd && defined?(OS::ISSUES_URL) &&
     !Homebrew::EnvConfig.no_auto_update?
    $stderr.puts "#{Tty.bold}Please report this issue:#{Tty.reset}"
    $stderr.puts "  #{Formatter.url(OS::ISSUES_URL)}"
  end
  $stderr.puts e.backtrace
  exit 1
else
  exit 1 if Homebrew.failed?
end
