# typed: strict

module Homebrew
  include Kernel
end

module Homebrew::Help
  include Kernel
end

module Language::Perl::Shebang
  include Kernel
end

module Dependable
  def tags; end
end

class Formula
  module Compat
    include Kernel

    def latest_version_installed?; end

    def active_spec; end

    def patches; end
  end
end

class NilClass
  module Compat
    include Kernel
  end
end

class String
  module Compat
    include Kernel

    def chomp; end
  end
end
