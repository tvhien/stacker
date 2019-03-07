require 'memoist'
require 'stacker/differ'
require 'stacker/resolver'
require 'stacker/stack/component'

module Stacker
  class Stack
    class Parameters < Component

      extend Memoist

      # everything required by the template
      def template_definitions
        stack.template.local.fetch 'Parameters', {}
      end

      def region_defaults
        stack.region.defaults.fetch 'parameters', {}
      end

      # template defaults merged with region and stack-specific overrides
      def local
        region_defaults = stack.region.defaults.fetch 'parameters', {}

        template_defaults = Hash[
          template_definitions.select { |_, opts|
            opts.key?('Default')
          }.map { |name, opts|
            [name, opts['Default']]
          }
        ]

        available = template_defaults.merge(
          region_defaults.merge(
            stack.options.fetch 'parameters', {}
          )
        )

        Stacker.logger.info "parameters available 1:#{available}"

        available.slice(*template_definitions.keys)
      end

      def missing
        template_definitions.keys - local.keys
      end

      def remote
		Hash[(((stack.region.client.describe_stacks stack_name: client.stack_name)[0])[0]).parameters.map { |parameter| [ parameter.parameter_key, parameter.parameter_value ] }]
      end
      memoize :remote

      def resolved
        resolver.resolved
      end
      memoize :resolved

      def resolver
        Stacker.logger.info "parameters param local: #{local}"
        Resolver.new stack.region, local
      end
      memoize :resolver

      def diff *args
        Differ.yaml_diff Hash[resolved.sort], Hash[remote.sort], *args
      end
      memoize :diff

    end
  end
end
