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

### What our `LiquidErrorCapturer` actually captures

```ruby
# Current code (utils.rb:19-31)
module LiquidErrorCapturer
  def handle_error(e, line_number = nil)
    unless e.is_a?(::Liquid::Error)
      ::Metanorma::Util.log(
        "[metanorma-plugin-lutaml] Liquid original error: " \
        "#{e.class}: #{e.message}\n" \
        "#{e.backtrace&.first(10)&.join("\n")}",
        :error,
      )
    end
    super  # calls original handle_error which replaces non-Liquid errors with InternalError
  end
end
```

**Problems:**
- `line_number` parameter is received but never logged
- `template_name` is available as `self.template_name` (from `Liquid::Context`) but never logged
- The original exception (`e`) is logged before Liquid replaces it with `InternalError`, but the replacement still happens — `liquid_template.errors` will contain `InternalError` objects with no useful backtrace or original message
- `notify_render_errors` logs `error_obj.backtrace` on the `InternalError`, which is useless (it points to the `raise InternalError` inside `context.rb`, not the real error)

### What `notify_render_errors` gets (utils.rb:108-117)

After `render_liquid_string` returns `[rendered_string, liquid_template.errors]`:
- `liquid_template.errors` contains `Liquid::InternalError` objects
- Each has `.template_name` and `.line_number` set (Liquid does this in `handle_error` before we log)
- But the `.message` is just `"internal"` and `.backtrace` points to `context.rb`'s `raise InternalError`

So **template name and line number are already on the error objects** — we just aren't using them in `notify_render_errors`.

### What `render_liquid_string` already knows

The method receives `template_path:` which is the `.liquid` file path. This could be set as the template name:
```ruby
liquid_template = ::Liquid::Template
  .parse(template_string, environment: create_liquid_environment)
liquid_template.name = template_path  # <-- this sets template_name on the context during render
```

Currently `liquid_template.name` is `nil`, so `context.template_name` is `nil`, so errors have no template name.

## Plan

### Step 1: Preserve original exceptions in error collection (most impactful)

The core issue is that `handle_error` replaces non-Liquid exceptions with `InternalError`. Instead of logging in the prepended module, **store the original exception** so `notify_render_errors` can report it.

```ruby
module LiquidErrorCapturer
  def handle_error(e, line_number = nil)
    unless e.is_a?(::Liquid::Error)
      # Store original exception before Liquid wraps it
      @original_errors ||= []
      @original_errors << {
        exception: e,
        template_name: template_name,
        line_number: line_number,
      }
    end
    super
  end

  def original_errors
    @original_errors || []
  end
end
```

Then in `notify_render_errors`, also report `original_errors` from the context.

### Step 2: Set template name on the Liquid::Template

In `render_liquid_string`:
```ruby
liquid_template.name = template_path  # sets context.template_name during render
```

This makes `Liquid::Error#template_name` meaningful for Liquid-native errors too.

### Step 3: Improve `notify_render_errors` formatting

```ruby
def notify_render_errors(document, errors, original_errors: [])
  errors.each do |error_obj|
    location = []
    location << error_obj.template_name if error_obj.template_name
    location << "line #{error_obj.line_number}" if error_obj.line_number
    loc_str = location.empty? ? "" : " (#{location.join(' ')})"

    ::Metanorma::Util.log(
      "[metanorma-plugin-lutaml] Liquid error#{loc_str}: " \
      "#{error_obj.class}: #{error_obj.message}",
      :error,
    )
  end

  original_errors.each do |err_info|
    e = err_info[:exception]
    location = []
    location << err_info[:template_name] if err_info[:template_name]
    location << "line #{err_info[:line_number]}" if err_info[:line_number]
    loc_str = location.empty? ? "" : " (#{location.join(' ')})"

    ::Metanorma::Util.log(
      "[metanorma-plugin-lutaml] Liquid original error#{loc_str}: " \
      "#{e.class}: #{e.message}\n" \
      "#{e.backtrace&.first(5)&.join("\n")}",
      :error,
    )
  end
end
```

### Step 4 (optional): Extract drop class/method from backtrace

For Ruby errors originating from Liquid drops, parse the backtrace to find the drop method:
```ruby
drop_frame = e.backtrace&.find { |line| line.include?("liquid_drops/") }
```

This gives something like `lib/lutaml/xmi/liquid_drops/klass_drop.rb:84:in 'associations'` which tells you exactly which drop method failed.

## Summary of changes needed

| File | Change |
|------|--------|
| `utils.rb` `LiquidErrorCapturer` | Store original exceptions with template_name + line_number instead of just logging |
| `utils.rb` `render_liquid_string` | Set `liquid_template.name = template_path` |
| `utils.rb` `notify_render_errors` | Accept and log `original_errors`, format template_name/line_number in output |
| `utils.rb` `render_liquid_string` | Pass context.original_errors to notify_render_errors |
