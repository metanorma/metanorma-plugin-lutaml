module Metanorma
  module Plugin
    module Lutaml
      module Asciidoctor
        class PreprocessorNoIfdefsReader < ::Asciidoctor::PreprocessorReader
          def preprocess_conditional_directive(_keyword, _target, _delimiter,
            _text)
            false # decline to resolve idefs
          end
        end
      end
    end
  end
end
