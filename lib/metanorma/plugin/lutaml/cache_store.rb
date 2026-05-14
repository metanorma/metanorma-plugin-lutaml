# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      class CacheStore
        def initialize(max_size: 50)
          @store = {}
          @max_size = max_size
          @mutex = Mutex.new
        end

        def fetch(key)
          @mutex.synchronize { @store[key] }
        end

        def store(key, value)
          @mutex.synchronize do
            evict! if @store.size >= @max_size
            @store[key] = value
          end
        end

        def fetch_or_store(key)
          @mutex.synchronize do
            if @store.key?(key)
              @store[key]
            else
              evict! if @store.size >= @max_size
              @store[key] = yield
            end
          end
        end

        def clear
          @mutex.synchronize { @store.clear }
        end

        def size
          @mutex.synchronize { @store.size }
        end

        private

        def evict!
          @store.shift
        end
      end
    end
  end
end
