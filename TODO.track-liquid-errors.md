# TODO: Improve Liquid error diagnostics

## Investigation findings

### How Liquid 5.12 error handling works

1. **`BlockBody.render_node`** (block_body.rb) catches all exceptions from node rendering and calls `context.handle_error(exc, node.line_number)`. This is the *only* place `line_number` is passed.

2. **`Context#handle_error`** (context.rb:100) does:
   ```ruby
   def handle_error(e, line_number = nil)
     e = internal_error unless e.is_a?(Liquid::Error)  # non-Liquid errors become InternalError
     e.template_name ||= template_name                   # sets template name on the error
     e.line_number   ||= line_number                     # sets line number on the error
     errors.push(e)                                      # collects into context.errors
     exception_renderer.call(e).to_s                     # returns error string for output
   end
   ```

3. **`Template#render`** (template.rb) does `context.template_name ||= name` before rendering, so the template name is available on the context.

4. **After render**, `liquid_template.errors` contains all `Liquid::Error` objects, each with `.template_name` and `.line_number` set by `handle_error`.

5. **`Liquid::Error`** (errors.rb) has `attr_accessor :line_number, :template_name, :markup_context`. Its `to_s` formats as: `"Liquid error (template_name line N): message"`.

### Liquid 4.x compatibility

- `Context#handle_error` has the same signature and same `InternalError` wrapping behavior in 4.x
- `BlockBody` passes `node.line_number` the same way in 4.x
- `Liquid::Error` has the same `template_name` and `line_number` accessors in 4.x
- **Key difference**: Liquid 4.x `Template` has **no `name` attribute** (`attr_accessor :root` only)
- **Key difference**: Liquid 4.x `Template#render` does **NOT** set `context.template_name` (5.x does `context.template_name ||= name`)
- **Key difference**: Liquid 4.x has **no `Liquid::Environment`** class — `create_liquid_environment` is 5.x only
- In practice, `metanorma-utils` depends on `liquid (~> 5)` so 4.x is not used, but we guard for it anyway via `respond_to?(:name=)` and `registers[:template_path]`

## Implemented changes

### Step 1: Preserve original exceptions ✅

`LiquidErrorCapturer` now stores original exceptions (before Liquid wraps them as `InternalError`) in `registers[:original_errors]` with template_name and line_number:

```ruby
module LiquidErrorCapturer
  def handle_error(e, line_number = nil)
    unless e.is_a?(::Liquid::Error)
      tname = template_name || registers[:template_path]
      registers[:original_errors] ||= []
      registers[:original_errors] << {
        exception: e,
        template_name: tname,
        line_number: line_number,
      }
    end
    super
  end
end
```

### Step 2: Set template name ✅

In `render_liquid_string`:
```ruby
liquid_template.name = template_path if template_path && liquid_template.respond_to?(:name=)
liquid_template.registers[:template_path] = template_path  # fallback for Liquid 4.x
```

### Step 3: Return original errors from render ✅

`render_liquid_string` now returns a 3-element array:
```ruby
[rendered_string, liquid_template.errors, original_errors]
```

All three call sites updated:
- `base_structured_text_preprocessor.rb`
- `lutaml_xmi_uml_preprocessor.rb`
- `lutaml_ea_xmi_base.rb`

### Step 4: Improved error formatting ✅

`notify_render_errors` now:
- Formats `template_name` and `line_number` from Liquid error objects
- Reports original exceptions with class, message, template name, line number, and backtrace
- Extracts drop frame from backtrace when available (shows which Liquid Drop method failed)
- Has `original_errors` parameter defaulting to `[]` for backward compatibility

Example output:
```
[metanorma-plugin-lutaml] Liquid error (templates/model.liquid line 42): Liquid::InternalError: internal
[metanorma-plugin-lutaml] Liquid original error (templates/model.liquid line 42) (in /gems/lutaml-0.10.12/lib/lutaml/xmi/liquid_drops/klass_drop.rb:84:in 'associations'): NoMethodError: undefined method `filter_map' for nil
```

## Future improvements (not yet implemented)

- **Switch to `strict_variables: true`** for early detection of undefined template variables
- **Custom exception class** that wraps the original error with template context, so it can be programmatically inspected
- **Per-drop method error context** by having drops rescue and re-raise with more context about which accessor failed
