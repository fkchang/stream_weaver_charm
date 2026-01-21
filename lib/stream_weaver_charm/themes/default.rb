# frozen_string_literal: true

module StreamWeaverCharm
  module Themes
    # Default theme - uses standard ANSI colors
    class Default < Base
      def initialize
        super(:default)
      end
    end
  end
end
