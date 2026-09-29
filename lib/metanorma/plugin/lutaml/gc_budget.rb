# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      # The lutaml macro family churns transients of hundreds of MB per
      # invocation on top of a multi-GB live parsed-XMI set. The churn is
      # malloc-side (libxml/moxml/liquid), so the GC's heap-growth
      # heuristics fire too late under memory caps; collect at macro
      # boundaries whenever uncollected malloc has exceeded the budget.
      module GcBudget
        BUDGET_BYTES = 512 * (1 << 20)

        class << self
          def gc_when_bloated!
            GC.start if GC.stat(:malloc_increase_bytes) > BUDGET_BYTES
          end
        end
      end
    end
  end
end
