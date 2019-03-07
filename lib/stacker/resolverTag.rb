module Stacker
    class ResolverTag
  
      attr_reader :region, :tags
  
      def initialize region, tags
        Stacker.logger.info "Resolver Tag #{tags}"
        @region, @tags = region, tags
      end
  
      def dependencies
        @dependencies ||= tags.select { |_, value|
          value.is_a?(Hash)
        }.map { |_, value|
          "#{value.fetch('Stack')}.#{value.fetch('Output')}"
        }
      end
  
      def resolved
      @resolved ||= Hash[tags.map do |name, value|
        if value.is_a? Hash
          stack = region.GetStack value.fetch('Stack')
          value = stack.outputs.fetch value.fetch('Output')
        end
            retval = [ name, value ]
        #the following logging message will be reformatted in the future with more elaborate detail
            #puts "Resolver.resolved finishing with #{retval}"
          [ name, value ]
        end]
      end
  
    end
  end
  