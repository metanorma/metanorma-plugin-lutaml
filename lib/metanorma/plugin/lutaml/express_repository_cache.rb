# frozen_string_literal: true

require "digest"
require "expressir"

module Metanorma
  module Plugin
    module Lutaml
      # Process-wide, content-keyed store of parsed Expressir repositories.
      #
      # A Metanorma collection compiles many documents against the same
      # schema set, and every document compile used to re-parse the whole
      # EXPRESS corpus (measured on ISO 10303-104: 125 schemas, 8.29 MB,
      # ~12.5 s wall and ~1.1 GB of allocations per document). This cache
      # parses each distinct source once per process: the key is derived
      # from the schema sources' content digests, so an edited source
      # produces a new key and re-parses instead of serving a stale
      # repository.
      #
      # Deliberately NOT registered in CacheRegistry: the metanorma
      # toolchain flushes CacheRegistry after every document compile to
      # release the render-time XMI/XSD graphs, and a flush here would
      # restore the per-document re-parse this cache exists to remove
      # (metanorma/metanorma-plugin-lutaml#341). The repositories are
      # collection-lifetime state; the LRU bound below caps how many
      # corpora stay resident.
      class ExpressRepositoryCache
        # Key digest version: bump when the key composition changes so
        # keys from different compositions can never collide.
        KEY_VERSION = "metanorma-plugin-lutaml/express-repository-cache/v1"

        MAX_SIZE = 4

        class << self
          # Content key for a set of EXPRESS source files: the key version,
          # the Expressir version, then every file's path and content
          # digest, in the order given (the order shapes the repository,
          # and the parsed model embeds file paths, so both belong in the
          # key). A changed source yields a new key.
          def source_key(paths)
            digest = Digest::SHA256.new
            digest.update(KEY_VERSION)
            digest.update(Expressir::Version::VERSION.to_s)
            paths.each do |path|
              digest.update(path)
              digest.update(Digest::SHA256.file(path).digest)
            end
            digest.hexdigest
          end

          # Identity key for one prebuilt file (a compiled-set artifact or
          # an Expressir cache file): expanded path plus mtime and size.
          # The file is not read for the key — compiled sets hydrate lazily
          # and re-reading a whole artifact per document would defeat the
          # sharing; path + mtime + size detects a rebuilt file.
          def file_key(path)
            [
              KEY_VERSION,
              File.expand_path(path),
              File.mtime(path).to_f,
              File.size(path),
            ]
          end

          def fetch_or_store(key, &block)
            store.fetch_or_store(key, &block)
          end

          def fetch(key)
            store.fetch(key)
          end

          def clear
            store.clear
          end

          def size
            store.size
          end

          private

          def store
            @store ||= CacheStore.new(max_size: MAX_SIZE)
          end
        end
      end
    end
  end
end
