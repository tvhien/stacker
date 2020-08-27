module Stacker
  class Resolver

    attr_reader :region, :parameters

    def initialize region, parameters
      @region, @parameters = region, parameters
    end

    def dependencies
      @dependencies ||= parameters.select { |_, value|
        value.is_a?(Hash)
      }.map { |_, value|
        "#{value.fetch('Stack')}.#{value.fetch('Output')}"
      }
    end

    def resolved
    @resolved ||= Hash[parameters.map do |name, value|
      if value.is_a? Hash
        if value.key?("Region")
          puts "Grabbing output from region #{value.fetch('Region')} for stack: #{value.fetch('Stack')}"
          cfnClient = Aws::CloudFormation::Client.new(region: value.fetch('Region'))
          resp = cfnClient.describe_stacks({
            stack_name: value.fetch('Stack')
          })
          puts "Retrieved stacks: #{resp.stacks.length}"
          puts "Outputs in stack: #{resp.stacks[0].outputs.length}"
          for output in outputs do
            puts "Looking at output_key #{output.output_key}"
            if output.output_key == value.fetch('Output')
              value = output.output_value
              break
            end
          end
          puts "retrieved value: #{value}"
        else
          stack = region.GetStack value.fetch('Stack')
          value = stack.outputs.fetch value.fetch('Output')
        end
      end
		  retval = [ name, value ]
      #the following logging message will be reformatted in the future with more elaborate detail
		  #puts "Resolver.resolved finishing with #{retval}"
        [ name, value ]
      end]
    end

  end
end
