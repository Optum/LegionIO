require_relative 'base'

module Legion
  module Extensions
    module Actors
      class Nothing
        include Legion::Extensions::Actors::Base

        def initialize; end

        def cancel; end
      end
    end
  end
end
