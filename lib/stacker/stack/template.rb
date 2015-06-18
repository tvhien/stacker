require 'active_support/core_ext/string/inflections'
require 'json'
require 'memoist'
require 'stacker/differ'
require 'stacker/stack/component'

module Stacker
  class Stack
    class Template < Component

      FORMAT_VERSION = '2010-09-09'

      extend Memoist

      def exists?
        File.exists? path
      end

      def local
        Stacker.logger.warn 'Getting local'
        @local ||= begin
          if exists?
            Stacker.logger.warn 'Reading and parsing local file'
            template = JSON.parse File.read path
            Stacker.logger.warn 'Setting format version'
            template['AWSTemplateFormatVersion'] ||= FORMAT_VERSION
            template
          else
            Stacker.logger.warn 'Local does not exist'
            {}
          end
        end
      end

      def remote
        Stacker.logger.warn 'Getting remote'
        @remote ||= JSON.parse client.template
      rescue AWS::CloudFormation::Errors::ValidationError => err
        if err.message =~ /does not exist/
          Stacker.logger.warn 'Raising DoesNotExistError'
          raise DoesNotExistError.new err.message
        else
          Stacker.logger.warn 'Raising Error'
          raise Error.new err.message
        end
      end

      def diff *args
        Differ.json_diff local, remote, *args
      end
      memoize :diff

      def write value = local
        File.write path, JSONFormatter.format(value)
      end

      def dump
        write remote
      end

      private

      def path
        @path ||= File.join(
          stack.region.templates_path,
          "#{stack.options.fetch('template_name', stack.name)}.json"
        )
      end

      class JSONFormatter
        STR = '\"[^\"]+\"'

        def self.format object
          formatted = JSON.pretty_generate object

          # put empty arrays on a single line
          formatted.gsub! /: \[\s*\]/m, ': []'

          # put { "Ref": ... } on a single line
          formatted.gsub! /\{\s+\"Ref\"\:\s+(?<ref>#{STR})\s+\}/m,
            '{ "Ref": \\k<ref> }'

          # put { "Fn::GetAtt": ... } on a single line
          formatted.gsub! /\{\s+\"Fn::GetAtt\"\: \[\s+(?<key>#{STR}),\s+(?<val>#{STR})\s+\]\s+\}/m,
            '{ "Fn::GetAtt": [ \\k<key>, \\k<val> ] }'

          formatted + "\n"
        end
      end

    end
  end
end
