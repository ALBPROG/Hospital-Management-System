# frozen_string_literal: true

require "style"

describe Homebrew::Style do
  around do |example|
    FileUtils.ln_s HOMEBREW_LIBRARY_PATH, HOMEBREW_LIBRARY/"Homebrew"
    FileUtils.ln_s HOMEBREW_LIBRARY_PATH.parent/".rubocop.yml", HOMEBREW_LIBRARY/".rubocop.yml"
    FileUtils.ln_s HOMEBREW_LIBRARY_PATH.parent/".rubocop_shared.yml", HOMEBREW_LIBRARY/".rubocop_shared.yml"

    example.run
  ensure
    FileUtils.rm_f HOMEBREW_LIBRARY/"Homebrew"
    FileUtils.rm_f HOMEBREW_LIBRARY/".rubocop.yml"
    FileUtils.rm_f HOMEBREW_LIBRARY/".rubocop_shared.yml"
  end

  before do
    allow(Homebrew).to receive(:install_bundler_gems!)
  end

  describe ".check_style_json" do
    let(:dir) { mktmpdir }

    it "returns RubocopResults when RuboCop reports offenses" do
      formula = dir/"my-formula.rb"

      formula.write <<~'EOS'
        class MyFormula < Formula

        end
      EOS

      rubocop_result = described_class.check_style_json([formula])

      expect(rubocop_result.file_offenses(formula.realpath.to_s).map(&:message))
        .to include("Extra empty line detected at class body beginning.")
    end

    it "corrected offense output format" do
      formula = dir/"my-formula-2.rb"

      formula.write <<~EOS
        class MyFormula2 < Formula
          desc "Test formula"
          homepage "https://foo.org"
          url "https://foo.org/foo-1.7.5.tgz"
          sha256 "cc692fb9dee0cc288757e708fc1a3b6b56ca1210ca181053a371cb11746969da"

          depends_on "foo"
          depends_on "bar-config" => :build

          test do
            assert_equal 5, 5
          end
        end
      EOS
      rubocop_result = described_class.check_style_json(
        [formula],
        fix: true, only_cops: ["FormulaAudit/DependencyOrder"],
      )
      offense_string = rubocop_result.file_offenses(formula.realpath).first.to_s
      expect(offense_string).to match(/\[Corrected\]/)
    end
  end

  describe ".check_style_and_print" do
    let(:dir) { mktmpdir }

    it "returns false for conforming file with only audit-level violations" do
      # This file is known to use non-rocket hashes and other things that trigger audit,
      # but not regular, cop violations
      target_file = HOMEBREW_LIBRARY_PATH/"utils.rb"

      rubocop_result = described_class.check_style_and_print([target_file])

      expect(rubocop_result).to eq true
    end
  end
end
