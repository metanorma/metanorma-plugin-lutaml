# frozen_string_literal: true

def with_fixture_provider_load_path
  lib = fixtures_path("lutaml_data/providers/lib")
  $LOAD_PATH.unshift(lib)
  yield
ensure
  $LOAD_PATH.delete(lib)
end
