# frozen_string_literal: true

module OS
  module Linux
    module_function

    def os_version
      if which("lsb_release")
        description = Utils.popen_read("lsb_release -d")
                           .chomp
                           .sub("Description:\t", "")
        codename = Utils.popen_read("lsb_release -c")
                        .chomp
                        .sub("Codename:\t", "")
        "#{description} (#{codename})"
      elsif (redhat_release = Pathname.new("/etc/redhat-release")).readable?
        redhat_release.read.chomp
      else
        "Unknown"
      end
    end
  end

  # Define OS::Mac on Linux for formula API compatibility.
  module Mac
    module_function

    # rubocop:disable Naming/ConstantName
    # rubocop:disable Style/MutableConstant
    ::MacOS = OS::Mac
    # rubocop:enable Naming/ConstantName
    # rubocop:enable Style/MutableConstant

    raise "Loaded OS::Linux on generic OS!" if ENV["HOMEBREW_TEST_GENERIC_OS"]

    def version
      Version::NULL
    end

    def full_version
      Version::NULL
    end

    def languages
      @languages ||= Array(ENV["LANG"]&.slice(/[a-z]+/)).uniq
    end

    def language
      languages.first
    end

    def sdk_root_needed?
      false
    end

    def sdk_path_if_needed(_v = nil)
      nil
    end

    module Xcode
      module_function

      def version
        Version::NULL
      end
    end

    module CLT
      module_function

      def version
        Version::NULL
      end
    end
  end
end
