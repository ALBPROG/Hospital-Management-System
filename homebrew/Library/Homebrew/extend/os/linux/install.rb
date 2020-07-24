# frozen_string_literal: true

module Homebrew
  module Install
    module_function

    DYNAMIC_LINKERS = [
      "/lib64/ld-linux-x86-64.so.2",
      "/lib64/ld64.so.2",
      "/lib/ld-linux.so.3",
      "/lib/ld-linux.so.2",
      "/lib/ld-linux-aarch64.so.1",
      "/lib/ld-linux-armhf.so.3",
      "/system/bin/linker64",
      "/system/bin/linker",
    ].freeze

    def check_cpu
      return if Hardware::CPU.intel? && Hardware::CPU.is_64_bit?
      return if Hardware::CPU.arm?

      message = "Sorry, Homebrew does not support your computer's CPU architecture!"
      if Hardware::CPU.ppc64le?
        message += <<~EOS
          For OpenPOWER Linux (PPC64LE) support, see:
            #{Formatter.url("https://github.com/homebrew-ppc64le/brew")}
        EOS
      end
      abort message
    end

    def symlink_ld_so
      brew_ld_so = HOMEBREW_PREFIX/"lib/ld.so"
      return if brew_ld_so.readable?

      ld_so = HOMEBREW_PREFIX/"opt/glibc/lib/ld-linux-x86-64.so.2"
      unless ld_so.readable?
        ld_so = DYNAMIC_LINKERS.find { |s| File.executable? s }
        raise "Unable to locate the system's dynamic linker" unless ld_so
      end

      FileUtils.mkdir_p HOMEBREW_PREFIX/"lib"
      FileUtils.ln_sf ld_so, brew_ld_so
    end

    def perform_preinstall_checks(all_fatal: false)
      generic_perform_preinstall_checks(all_fatal: all_fatal)
      symlink_ld_so
    end
  end
end
