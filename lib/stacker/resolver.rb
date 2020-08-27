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

    def resolveRegion valuesHash
      region, stack, output = valuesHash.fetch('Region'), valuesHash.fetch('Stack'), valuesHash.fetch('Output')
      puts "Grabbing output from region #{region} for stack: #{stack} and output #{output}"
      cfnClient = Aws::CloudFormation::Client.new(region: region)
      resp = cfnClient.describe_stacks({
        stack_name: value.fetch('Stack')
      })
      if resp.stacks.length == 0
        raise "No stacks found called #{stack}"
      elsif resp.stacks.length > 1
        raise "More than 1 stacks found called #{stack}. Found #{resp.stacks.length}"
      end
      for output in resp.stacks[0].outputs do
        if output.output_key == output
          return output.output_value
        end
      end
      raise "No output found for key #{output} in stack #{stack} in region #{region}"
    end

    def resolved
    @resolved ||= Hash[parameters.map do |name, value|
      if value.is_a? Hash
        if value.key?('Region')
          value = send(resolveRegion value)
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
