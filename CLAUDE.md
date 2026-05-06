# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`metanorma-plugin-lutaml` is a Ruby gem that provides Asciidoctor extensions for the Metanorma document publishing system. It enables Metanorma documents to embed and render data models from multiple formats: EXPRESS (ISO 10303), LutaML DSL, Enterprise Architect XMI, GML Dictionaries, JSON, and YAML.

## Build and Test Commands

```bash
# Install dependencies
bundle install

# Run all tests
bundle exec rake

# Run a single test file
bundle exec rspec spec/metanorma/plugin/lutaml/lutaml_preprocessor_spec.rb

# Run a specific test by line number
bundle exec rspec spec/metanorma/plugin/lutaml/lutaml_preprocessor_spec.rb:42

# Lint
bundle exec rubocop

# Build the gem
bundle exec rake build
```

## Architecture

### Asciidoctor Extension Pattern

All extensions follow the Asciidoctor extension API. The two main extension types are:

- **Preprocessors** (`::Asciidoctor::Extensions::Preprocessor`): Process document text before rendering. They read input lines, detect custom block syntax (e.g., `[lutaml_express, ...]`), and replace them with rendered content via Liquid templates.
- **Block/BlockMacro/InlineMacro extensions**: Handle `lutaml_diagram`, `lutaml_ea_diagram`, `lutaml_gml_dictionary`, `lutaml_klass_table`, `lutaml_enum_table`, `lutaml_table`, `lutaml_figure` — these are Asciidoctor block-level or inline macros.

### Preprocessor Inheritance Hierarchy

- `LutamlPreprocessor` — handles `[lutaml]`, `[lutaml_express]`, `[lutaml_express_liquid]` blocks. Parses EXPRESS files via the `lutaml`/`expressir` gems, builds Liquid contexts, and renders templates.
- `LutamlUmlDatamodelDescriptionPreprocessor` and `LutamlEaXmiPreprocessor` — both include `LutamlEaXmiBase`, which handles XMI parsing via `lutaml` gem and renders using bundled Liquid templates.
- `LutamlXmiUmlPreprocessor` — another XMI-based preprocessor with its own macro regex.
- `BaseStructuredTextPreprocessor` — base for `[yaml2text]`, `[json2text]`, `[data2text]` blocks. Its subclasses (`Yaml2TextPreprocessor`, `Json2TextPreprocessor`, `Data2TextPreprocessor`) differ only in how they load content (YAML vs JSON vs auto-detect). The `Content` module provides the actual parsing logic.

### Key Shared Modules

- `Utils` (`lib/metanorma/plugin/lutaml/utils.rb`) — shared helpers: file path resolution relative to document, Liquid template rendering with custom environment/filters, EXPRESS repository loading with caching, parsing document-level `:lutaml-express-index:` attributes.
- `LutamlEaXmiBase` — shared logic for XMI-based preprocessors: XMI document loading/caching, config YAML parsing, package filtering/sorting, Liquid context building, nested macro collection.
- `LutamlDiagramBase` — shared logic for diagram block extensions: parses LutaML DSL, renders via Graphviz to PNG.
- `LutamlGmlDictionaryBase` — parses GML XML via `ogc-gml` gem, renders via Liquid.
- `SourceExtractor` — scans document lines for anchors (`[[id]]`, `[#id]`, `[id=...]`) and `include::`/`embed::` directives, extracting source blocks into `document.attributes["source_blocks"]` for later use by preprocessors.

### Liquid Template System

The plugin uses Liquid templates extensively. Key components:

- **Custom Liquid environment** with registered `keyiterator` tag and custom filters (`html2adoc`, `values`, `replace_regex`, `loadfile`, `file_exist`).
- **`Liquid::LocalFileSystem`** subclass (`multiply_local_file_system.rb`) resolves includes from multiple paths.
- **Liquid Drops** (`liquid_drops/`) wrap domain objects (e.g., `GmlDictionaryDrop`) for template rendering.
- **Bundled templates** live in `lib/metanorma/plugin/lutaml/liquid_templates/` for XMI/EA rendering.

### Config System

The `Config` module (`lib/metanorma/plugin/lutaml/config.rb`) uses `lutaml/model` (LutaML::Model) to define config schemas: `Root`, `Package`, `Guidance`, `GuidanceKlass`, `GuidanceAttribute`. Config YAML files control which packages/entities to render from XMI documents.

### Testing Pattern

Tests use `metanorma-standoc` as the backend. The spec helper registers all extensions with Asciidoctor, then tests call `metanorma_convert(input)` which converts AsciiDoc input through the pipeline and compares XML output. Test fixtures (`.exp`, `.lutaml`, `.xmi`, `.xml`, `.liquid` files) are in `spec/fixtures/lutaml/` and `spec/assets/lutaml/`.

## Key Dependencies

- `lutaml` — core LutaML parser/model library (EXPRESS, UML, XMI formats)
- `expressir` — EXPRESS schema parser
- `ogc-gml` — OGC GML dictionary parser
- `liquid` — template rendering engine
- `asciidoctor` — document processing framework
