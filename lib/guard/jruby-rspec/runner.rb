require 'rspec'
require 'guard/jruby-rspec/formatters/notification_rspec'

module Guard
  class JRubyRSpec
    class Runner

      def initialize(options = {})
        @options = {
          :cli          => [],
          :notification => true
        }.merge(options)

        @pipefile = options[:pipefile]
        @pipefile ||= ".guard-jruby-rspec-pipe"
        cleanup
      end

      def cleanup
        File.delete(@pipefile) if File.exists?(@pipefile)
      end

      def run(paths, options = {})
        return false if paths.empty?

        message = options[:message] || "Running: #{paths.join(' ')}"
        UI.info(message, :reset => true)

        # it might be a problem to run Rspec within this runtime.  Might have to create an
        # embedded jruby.
        if File.exists?(@pipefile)
          raise "not supported yet"
          # instead of writing to the pipefile, we should probably use a
          # formatter and write to /dev/null
          # orig_stdout = $stdout.clone
          # orig_stderr = $stderr.clone
          # begin
          #   $stdout.reopen(@pipefile, "w")
          #   $stderr.reopen(@pipefile, "w")
          #   ::RSpec::Core::Runner.run(paths)
          # ensure
          #   $stdout.reopen(orig_stdout)
          #   $stderr.reopen(orig_stderr)
          # end
        else
          orig_configuration = ::RSpec.configuration
          begin
            ::RSpec::Core::Runner.run(rspec_arguments(paths, @options))
          rescue SyntaxError => e
            UI.error e.message
          ensure
            ::RSpec.instance_variable_set(:@configuration, orig_configuration)
          end
        end
      end

      def parsed_or_default_formatter
        @parsed_or_default_formatter ||= begin
          file_name = "#{Dir.pwd}/.rspec"
          parsed_formatter = if File.exist?(file_name)
            formatters = File.read(file_name).scan(formatter_regex).flatten
            formatters.map { |formatter| "-f#{formatter}" }.join(' ')
          end

          parsed_formatter.nil? || parsed_formatter.empty? ? '-fprogress' : parsed_formatter
        end
      end

      private

      def rspec_arguments(paths, options)
        arg_parts = []
        arg_parts.concat(options[:cli]) if options[:cli]
        if @options[:notification]
          arg_parts << parsed_or_default_formatter unless options[:cli] =~ formatter_regex
          arg_parts << "-fGuard::JRubyRSpec::Formatter::NotificationRSpec"
          arg_parts << "-o/dev/null"
        end
        #arg_parts << "--failure-exit-code #{FAILURE_EXIT_CODE}" if failure_exit_code_supported?
        arg_parts.concat(paths)
      end

      def formatter_regex
        @formatter_regex ||= /(?:^|\s)(?:-f\s*|--format(?:=|\s+))([\w:]+)/
      end

    end
  end
end
