module Guard
  class JRubyRSpec
    class Containment
      def initialize(options = {})
        @error_handler = options.fetch(:error_handler, method(:output_as_guard_error))
      end

      def protect
        yield
      rescue Exception => e
        error_handler.call e
        throw :task_has_failed
      end

      private

      attr_reader :error_handler

      def output_as_guard_error(exception)
        UI.error $!.message
        UI.error $!.backtrace.join "\n"
      end
    end
  end
end
