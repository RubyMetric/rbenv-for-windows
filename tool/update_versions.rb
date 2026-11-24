# ---------------------------------------------------------------
# SPDX-License-Identifier: MIT
# ---------------------------------------------------------------
# File Name      : update_versions.rb
# File Authors   : Aoran Zeng <ccmywish@qq.com>
# Created On     : <2026-11-24>
# Last Modified  : <2026-11-24>
#
# Update supported RubyInstaller versions from the upstream
# downloads.yaml
# ---------------------------------------------------------------

require "open-uri"
require "json"
require "yaml"

SOURCE_URL = "https://raw.githubusercontent.com/oneclick/rubyinstaller.org-website/master/_data/downloads.yaml"
REPOSITORY_ROOT = File.expand_path("..", __dir__)
ARCHITECTURES = %w[x64 arm].freeze

# Exclude pre-2.4.1-1 and releases with legacy URLs through 2.5.3-1 / 2.4.5-1.
def supported_version?(version)
  parts = version.split(/[.-]/).map(&:to_i)
  major, minor = parts

  return false if (parts <=> [2, 4, 1, 1]) < 0
  return false if major == 2 && minor == 5 && (parts <=> [2, 5, 3, 1]) <= 0
  return false if major == 2 && minor == 4 && (parts <=> [2, 4, 5, 1]) <= 0

  true
end

def version_sort_key(version)
  version.split(/[.-]/).map(&:to_i)
end

def versions_for_architecture(entries, architecture)
  versions = {}

  entries.each do |entry|
    next unless entry.is_a?(Hash)

    href = entry.fetch("href")
    case entry["filetype"]
    when "rubyinstaller7z"
      match = href.match(%r{/rubyinstaller-(\d+\.\d+\.\d+-\d+)-(x64|arm|x86)\.7z\z})
      checksum_column = "sha256"
      architecture_index = 2
    when "ridkexe"
      match = href.match(%r{/rubyinstaller-devkit-(\d+\.\d+\.\d+-\d+)-(x64|arm|x86)\.exe\z})
      checksum_column = "devkit_sha256"
      architecture_index = 2
    else
      next
    end
    next unless match && match[architecture_index] == architecture

    version = match[1]
    next unless supported_version?(version)

    sha256 = entry.fetch("sha256")
    raise "Invalid SHA256 for Ruby #{version} (#{architecture})" unless sha256.match?(/\A[0-9a-f]{64}\z/i)

    version_info = versions[version] ||= { "sha256" => nil, "devkit_sha256" => nil }
    if version_info[checksum_column]
      raise "Duplicate #{checksum_column} for Ruby #{version} (#{architecture})"
    end
    version_info[checksum_column] = sha256.downcase
  end

  versions.each do |version, checksums|
    missing = %w[sha256 devkit_sha256].reject { |checksum| checksums[checksum] }
    unless missing.empty?
      raise "Missing #{missing.join(' and ')} for Ruby #{version} (#{architecture})"
    end
  end

  versions.sort_by { |version, _checksums| version_sort_key(version) }.reverse
end

def json_content(versions)
  records = [{ "version" => "head", "sha256" => nil, "devkit_sha256" => nil }]
  versions.each do |version, checksums|
    records << {
      "version" => version,
      "sha256" => checksums["sha256"],
      "devkit_sha256" => checksums["devkit_sha256"]
    }
  end
  JSON.pretty_generate(records) + "\n"
end

yaml = URI.open(SOURCE_URL, open_timeout: 10, read_timeout: 30, &:read)
entries = YAML.safe_load(yaml, permitted_classes: [], permitted_symbols: [], aliases: false)
raise "Expected an array in upstream downloads.yaml" unless entries.is_a?(Array)

versions_by_architecture = ARCHITECTURES.each_with_object({}) do |architecture, result|
  versions = versions_for_architecture(entries, architecture)
  raise "No Ruby versions found for #{architecture}" if versions.empty?
  result[architecture] = versions
end

versions_by_architecture.each do |architecture, versions|
  path = File.join(REPOSITORY_ROOT, "share", "versions-for-#{architecture}.json")
  File.write(path, json_content(versions), mode: "w:UTF-8")
  puts "Updated #{path} (#{versions.length} versions)"
end
