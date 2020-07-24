# frozen_string_literal: true

require "rubocops/extend/formula"

module RuboCop
  module Cop
    module FormulaAudit
      # This cop audits URLs and mirrors in Formulae.
      class Urls < FormulaCop
        # These are parts of URLs that look like binaries but actually aren't.
        NOT_A_BINARY_URL_PREFIX_ALLOWLIST = %w[
          https://downloads.sourceforge.net/project/astyle/astyle/
          https://downloads.sourceforge.net/project/bittwist/
          https://downloads.sourceforge.net/project/launch4j/
          https://github.com/ChrisJohnsen/tmux-MacOSX-pasteboard/archive/
          https://github.com/obihann/archey-osx
          https://github.com/sindresorhus/macos-wallpaper/archive/
          https://raw.githubusercontent.com/liyanage/macosx-shell-scripts/
          https://osxbook.com/book/bonus/chapter8/core/download/gcore
          https://naif.jpl.nasa.gov/pub/naif/toolkit/C/MacIntel_OSX_AppleC_64bit/packages/
          https://artifacts.videolan.org/x264/release-macos/
        ].freeze

        # These are formulae that, sadly, require an upstream binary to bootstrap.
        BINARY_BOOTSTRAP_FORMULA_URLS_ALLOWLIST = %w[
          clozure-cl
          crystal
          fpc
          ghc
          ghc@8.6
          ghc@8.8
          go
          go@1.9
          go@1.10
          go@1.11
          go@1.12
          go@1.13
          haskell-stack
          ldc
          mlton
          openjdk
          openjdk@11
          pypy
          sbcl
          rust
        ].freeze

        def audit_formula(_node, _class_node, _parent_class_node, body_node)
          urls = find_every_func_call_by_name(body_node, :url)
          mirrors = find_every_func_call_by_name(body_node, :mirror)

          # Identify livecheck urls, to skip some checks for them
          livecheck_url = if (livecheck = find_every_func_call_by_name(body_node, :livecheck).first) &&
                             (livecheck_url = find_every_func_call_by_name(livecheck.parent, :url).first)
            string_content(parameters(livecheck_url).first)
          end

          # GNU urls; doesn't apply to mirrors
          gnu_pattern = %r{^(?:https?|ftp)://ftpmirror.gnu.org/(.*)}
          audit_urls(urls, gnu_pattern) do |match, url|
            problem "Please use \"https://ftp.gnu.org/gnu/#{match[1]}\" instead of #{url}."
          end

          # Fossies upstream requests they aren't used as primary URLs
          # https://github.com/Homebrew/homebrew-core/issues/14486#issuecomment-307753234
          fossies_pattern = %r{^https?://fossies\.org/}
          audit_urls(urls, fossies_pattern) do
            problem "Please don't use fossies.org in the url (using as a mirror is fine)"
          end

          apache_pattern = %r{^https?://(?:[^/]*\.)?apache\.org/(?:dyn/closer\.cgi\?path=/?|dist/)(.*)}i
          audit_urls(urls, apache_pattern) do |match, url|
            next if url == livecheck_url

            problem "#{url} should be `https://www.apache.org/dyn/closer.lua?path=#{match[1]}`"
          end

          version_control_pattern = %r{^(cvs|bzr|hg|fossil)://}
          audit_urls(urls, version_control_pattern) do |match, _|
            problem "Use of the #{match[1]}:// scheme is deprecated, pass `:using => :#{match[1]}` instead"
          end

          svn_pattern = %r{^svn\+http://}
          audit_urls(urls, svn_pattern) do |_, _|
            problem "Use of the svn+http:// scheme is deprecated, pass `:using => :svn` instead"
          end

          audit_urls(mirrors, /.*/) do |_, mirror|
            urls.each do |url|
              url_string = string_content(parameters(url).first)
              next unless url_string.eql?(mirror)

              problem "URL should not be duplicated as a mirror: #{url_string}"
            end
          end

          urls += mirrors

          # Check a variety of SSL/TLS URLs that don't consistently auto-redirect
          # or are overly common errors that need to be reduced & fixed over time.
          http_to_https_patterns = Regexp.union([%r{^http://ftp\.gnu\.org/},
                                                 %r{^http://ftpmirror\.gnu\.org/},
                                                 %r{^http://download\.savannah\.gnu\.org/},
                                                 %r{^http://download-mirror\.savannah\.gnu\.org/},
                                                 %r{^http://(?:[^/]*\.)?apache\.org/},
                                                 %r{^http://code\.google\.com/},
                                                 %r{^http://fossies\.org/},
                                                 %r{^http://mirrors\.kernel\.org/},
                                                 %r{^http://mirrors\.ocf\.berkeley\.edu/},
                                                 %r{^http://(?:[^/]*\.)?bintray\.com/},
                                                 %r{^http://tools\.ietf\.org/},
                                                 %r{^http://launchpad\.net/},
                                                 %r{^http://github\.com/},
                                                 %r{^http://bitbucket\.org/},
                                                 %r{^http://anonscm\.debian\.org/},
                                                 %r{^http://cpan\.metacpan\.org/},
                                                 %r{^http://hackage\.haskell\.org/},
                                                 %r{^http://(?:[^/]*\.)?archive\.org},
                                                 %r{^http://(?:[^/]*\.)?freedesktop\.org},
                                                 %r{^http://(?:[^/]*\.)?mirrorservice\.org/}])
          audit_urls(urls, http_to_https_patterns) do |_, url|
            problem "Please use https:// for #{url}"
          end

          apache_mirror_pattern = %r{^https?://(?:[^/]*\.)?apache\.org/dyn/closer\.(?:cgi|lua)\?path=/?(.*)}i
          audit_urls(mirrors, apache_mirror_pattern) do |match, mirror|
            problem "Please use `https://archive.apache.org/dist/#{match[1]}` as a mirror instead of #{mirror}."
          end

          cpan_pattern = %r{^http://search\.mcpan\.org/CPAN/(.*)}i
          audit_urls(urls, cpan_pattern) do |match, url|
            problem "#{url} should be `https://cpan.metacpan.org/#{match[1]}`"
          end

          gnome_pattern = %r{^(http|ftp)://ftp\.gnome\.org/pub/gnome/(.*)}i
          audit_urls(urls, gnome_pattern) do |match, url|
            problem "#{url} should be `https://download.gnome.org/#{match[2]}`"
          end

          debian_pattern = %r{^git://anonscm\.debian\.org/users/(.*)}i
          audit_urls(urls, debian_pattern) do |match, url|
            problem "#{url} should be `https://anonscm.debian.org/git/users/#{match[1]}`"
          end

          # Prefer HTTP/S when possible over FTP protocol due to possible firewalls.
          mirror_service_pattern = %r{^ftp://ftp\.mirrorservice\.org}
          audit_urls(urls, mirror_service_pattern) do |_, url|
            problem "Please use https:// for #{url}"
          end

          cpan_ftp_pattern = %r{^ftp://ftp\.cpan\.org/pub/CPAN(.*)}i
          audit_urls(urls, cpan_ftp_pattern) do |match_obj, url|
            problem "#{url} should be `http://search.cpan.org/CPAN#{match_obj[1]}`"
          end

          # SourceForge url patterns
          sourceforge_patterns = %r{^https?://.*\b(sourceforge|sf)\.(com|net)}
          audit_urls(urls, sourceforge_patterns) do |_, url|
            # Skip if the URL looks like a SVN repo
            next if url.include? "/svnroot/"
            next if url.include? "svn.sourceforge"
            next if url.include? "/p/"

            if url =~ /(\?|&)use_mirror=/
              problem "Don't use #{Regexp.last_match(1)}use_mirror in SourceForge urls (url is #{url})."
            end

            problem "Don't use /download in SourceForge urls (url is #{url})." if url.end_with?("/download")

            if url.match?(%r{^https?://sourceforge\.}) && url != livecheck_url
              problem "Use https://downloads.sourceforge.net to get geolocation (url is #{url})."
            end

            if url.match?(%r{^https?://prdownloads\.})
              problem <<~EOS.chomp
                Don't use prdownloads in SourceForge urls (url is #{url}).
                        See: http://librelist.com/browser/homebrew/2011/1/12/prdownloads-is-bad/
              EOS
            end

            if url.match?(%r{^http://\w+\.dl\.})
              problem "Don't use specific dl mirrors in SourceForge urls (url is #{url})."
            end

            problem "Please use https:// for #{url}" if url.start_with? "http://downloads"
          end

          # Debian has an abundance of secure mirrors. Let's not pluck the insecure
          # one out of the grab bag.
          unsecure_deb_pattern = %r{^http://http\.debian\.net/debian/(.*)}i
          audit_urls(urls, unsecure_deb_pattern) do |match, _|
            problem <<~EOS
              Please use a secure mirror for Debian URLs.
              We recommend:
                https://deb.debian.org/debian/#{match[1]}
            EOS
          end

          # Check to use canonical urls for Debian packages
          noncanon_deb_pattern =
            Regexp.union([%r{^https://mirrors\.kernel\.org/debian/},
                          %r{^https://mirrors\.ocf\.berkeley\.edu/debian/},
                          %r{^https://(?:[^/]*\.)?mirrorservice\.org/sites/ftp\.debian\.org/debian/}])
          audit_urls(urls, noncanon_deb_pattern) do |_, url|
            problem "Please use https://deb.debian.org/debian/ for #{url}"
          end

          # Check for new-url Google Code download urls, https:// is preferred
          google_code_pattern = Regexp.union([%r{^http://.*\.googlecode\.com/files.*},
                                              %r{^http://code\.google\.com/}])
          audit_urls(urls, google_code_pattern) do |_, url|
            problem "Please use https:// for #{url}"
          end

          # Check for git:// GitHub repo urls, https:// is preferred.
          git_gh_pattern = %r{^git://[^/]*github\.com/}
          audit_urls(urls, git_gh_pattern) do |_, url|
            problem "Please use https:// for #{url}"
          end

          # Check for git:// Gitorious repo urls, https:// is preferred.
          git_gitorious_pattern = %r{^git://[^/]*gitorious\.org/}
          audit_urls(urls, git_gitorious_pattern) do |_, url|
            problem "Please use https:// for #{url}"
          end

          # Check for http:// GitHub repo urls, https:// is preferred.
          gh_pattern = %r{^http://github\.com/.*\.git$}
          audit_urls(urls, gh_pattern) do |_, url|
            problem "Please use https:// for #{url}"
          end

          # Check for master branch GitHub archives.
          tarball_gh_pattern = %r{^https://github\.com/.*archive/master\.(tar\.gz|zip)$}
          audit_urls(urls, tarball_gh_pattern) do
            problem "Use versioned rather than branch tarballs for stable checksums."
          end

          # Use new-style archive downloads
          archive_gh_pattern = %r{https://.*github.*/(?:tar|zip)ball/}
          audit_urls(urls, archive_gh_pattern) do |_, url|
            next if url.end_with?(".git")

            problem "Use /archive/ URLs for GitHub tarballs (url is #{url})."
          end

          # Don't use GitHub .zip files
          zip_gh_pattern = %r{https://.*github.*/(archive|releases)/.*\.zip$}
          audit_urls(urls, zip_gh_pattern) do |_, url|
            next if url.include?("releases/download")

            problem "Use GitHub tarballs rather than zipballs (url is #{url})."
          end

          # Don't use GitHub codeload URLs
          codeload_gh_pattern = %r{https?://codeload\.github\.com/(.+)/(.+)/(?:tar\.gz|zip)/(.+)}
          audit_urls(urls, codeload_gh_pattern) do |match, url|
            problem <<~EOS
              Use GitHub archive URLs:
                https://github.com/#{match[1]}/#{match[2]}/archive/#{match[3]}.tar.gz
              Rather than codeload:
                #{url}
            EOS
          end

          # Check for Maven Central urls, prefer HTTPS redirector over specific host
          maven_pattern = %r{https?://(?:central|repo\d+)\.maven\.org/maven2/(.+)$}
          audit_urls(urls, maven_pattern) do |match, url|
            problem "#{url} should be `https://search.maven.org/remotecontent?filepath=#{match[1]}`"
          end

          return if formula_tap != "homebrew-core"

          # Check for binary URLs
          audit_urls(urls, /(darwin|macos|osx)/i) do |match, url|
            next if @formula_name.include?(match.to_s.downcase)
            next if url.match?(/.(patch|diff)(\?full_index=1)?$/)
            next if NOT_A_BINARY_URL_PREFIX_ALLOWLIST.any? { |prefix| url.start_with?(prefix) }
            next if BINARY_BOOTSTRAP_FORMULA_URLS_ALLOWLIST.include?(@formula_name)

            problem "#{url} looks like a binary package, not a source archive; " \
                    "homebrew/core is source-only."
          end
        end
      end

      class PyPiUrls < FormulaCop
        def audit_formula(_node, _class_node, _parent_class_node, body_node)
          urls = find_every_func_call_by_name(body_node, :url)
          mirrors = find_every_func_call_by_name(body_node, :mirror)
          urls += mirrors

          # Check pypi urls
          pypi_pattern = %r{^https?://pypi.python.org/}
          audit_urls(urls, pypi_pattern) do |_, url|
            problem "use the `Source` url found on PyPI downloads page (`#{get_pypi_url(url)}`)"
          end

          # Require long files.pythonhosted.org urls
          pythonhosted_pattern = %r{^https?://files.pythonhosted.org/packages/source/}
          audit_urls(urls, pythonhosted_pattern) do |_, url|
            problem "use the `Source` url found on PyPI downloads page (`#{get_pypi_url(url)}`)"
          end
        end

        def get_pypi_url(url)
          package_file = File.basename(url)
          package_name = package_file.match(/^(.+)-[a-z0-9.]+$/)[1]
          "https://pypi.org/project/#{package_name}/#files"
        end
      end
    end
  end
end
