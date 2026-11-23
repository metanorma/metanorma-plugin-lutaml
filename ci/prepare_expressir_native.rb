# frozen_string_literal: true

# Qualify Ruby-only candidate changes with the unchanged published native ABI.
# A Git install on Windows deliberately skips native compilation. Require the
# real batch parser here, so that fallback parsing cannot conceal a regression.
require "fileutils"
require "digest"

candidate = Gem.loaded_specs.fetch("expressir")
unless candidate.version.to_s == "2.4.82"
  abort "Unexpected Expressir candidate version"
end
native_lib = File.read(ARGV.fetch(0)).strip
candidate_lib = File.join(candidate.full_gem_path, "lib")
abi = RUBY_VERSION.split(".").take(2).join(".")
pattern = "expressir_core.{so,bundle}"
binaries = Dir.glob(File.join(native_lib, "expressir", abi, pattern))
if binaries.empty?
  binaries = Dir.glob(File.join(native_lib, "expressir", pattern))
end
abort "Published Expressir native binary is missing" if binaries.empty?

binaries.each do |binary|
  destination = File.join(candidate_lib, "expressir", File.basename(binary))
  FileUtils.mkdir_p(File.dirname(destination))
  FileUtils.cp(binary, destination)
end

require "expressir"
require "expressir/express/parser"
unless Expressir::Express::Core::NATIVE_AVAILABLE &&
    Expressir::Core.const_defined?(:BatchStream, false)
  abort "Candidate qualification requires the native batch parser"
end
parser = Expressir::Express::Parser.method(:from_files).source_location.first
unless File.realpath(parser).start_with?(File.realpath(candidate_lib) + File::SEPARATOR)
  abort "Candidate Ruby parser source was not loaded"
end
puts "Expressir candidate Ruby SHA256: #{Digest::SHA256.file(parser).hexdigest}"
binaries.each do |binary|
  puts "Published native SHA256: #{Digest::SHA256.file(binary).hexdigest}"
end
