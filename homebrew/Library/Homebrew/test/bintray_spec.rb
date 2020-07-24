# frozen_string_literal: true

require "bintray"

describe Bintray, :needs_network do
  bintray = described_class.new(user: "BrewTestBot", key: "deadbeef", org: "homebrew")
  describe "::file_published?" do
    it "detects a published file" do
      results = bintray.file_published?(repo: "bottles", remote_file: "hello-2.10.catalina.bottle.tar.gz")
      expect(results).to be true
    end

    it "fails on a non-existant file" do
      results = bintray.file_published?(repo: "bottles", remote_file: "my-fake-bottle-1.0.snow_hyena.tar.gz")
      expect(results).to be false
    end
  end

  describe "::package_exists?" do
    it "detects a package" do
      results = bintray.package_exists?(repo: "bottles", package: "hello")
      expect(results).to be true
    end
  end
end
