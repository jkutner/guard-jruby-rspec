require 'rspec'

module Guard
  class JRubyRSpec
    class Runner
     
      def initialize(options = {})
        @pipefile = options[:pipefile]
        @pipefile ||= ".guard-jruby-rspec-pipe"
        cleanup
      end

      def cleanup
        File.delete(@pipefile) if File.exists?(@pipefile)
      end

      def run(paths, options = {})
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
          ::RSpec::Core::Runner.run(paths)
        end
      end

    end
  end
end
