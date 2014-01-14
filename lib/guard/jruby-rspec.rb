require 'guard'
require 'guard/guard'
require 'guard/rspec'
require 'guard/jruby-rspec/reloaders'

module Guard
  class JRubyRSpec < ::Guard::RSpec
    autoload :Runner,       'guard/jruby-rspec/runner'
    autoload :Inspector,    'guard/jruby-rspec/inspector'

    def initialize(watchers = [], options = {})
      @options = {
        :all_after_pass   => true,
        :all_on_start     => true,
        :keep_failed      => true,
        :spec_paths       => ["spec"],
        :spec_file_suffix => "_spec.rb",
        :run_all          => {},
        :monitor_file     => ".guard-jruby-rspec",
        :custom_reloaders => []
      }.merge(options)
      @last_failed  = false
      @failed_paths = []

      default_watchers = [Watcher.new(@monitor)]
      if @custom_watchers.nil? or @custom_watchers.empty?
        default_watchers <<
            Watcher.new(%r{^(.+)\.rb$}) <<
            Watcher.new(%r{^(.+)\.(erb|haml)$})
      else
        watchers.each do |w|
          default_watchers << Watcher.new(w.pattern)
        end
      end

      @custom_watchers = watchers

      # touch the monitor file (lets the gjrspec know we're here)
      #File.open(@monitor, "w") {}

      # ideally we would bypass the Guard::RSpec initializer
      super(default_watchers, @options)

      @inspector = Inspector.new(@options)
      @runner = Runner.new(@options)
      @reloaders = set_up_reloaders(@options)
    end

    # Call once when guard starts
    def start
      UI.info "Guard::JRuby::RSpec is running, with RSpec!"
      run_all if @options[:all_on_start]
    end

    def run_all
      unload_previous_examples
      super
    end

    def run_on_changes(raw_paths)
      unload_previous_examples
      @reloaders.reload(raw_paths)

      unless @custom_watchers.nil? or @custom_watchers.empty?
        paths = []

        raw_paths.each do |p|
          @custom_watchers.each do |w|
            if (m = w.match(p))
              paths << (w.action.nil? ? p : w.call_action(m))
            end
          end
        end
        super(paths.flatten)
      end
    end
    # Guard 1.1 renamed run_on_change to run_on_changes
    alias_method :run_on_change, :run_on_changes

    def reload_rails(*)
      if defined? ::ActionDispatch::Reloader
        ActionDispatch::Reloader.cleanup!
        ActionDispatch::Reloader.prepare!
      end
    end

    def reload_factory_girl(*)
      FactoryGirl.reload if defined? ::FactoryGirl
    end

    def reload_paths(paths)
      paths.reject {|p| p.end_with?(@options[:spec_file_suffix])}.each do |p|
        if File.exists?(p)
          if p == @options[:monitor_file]
            # begin
            #   pidfile = open(@options[:monitor_file], "r+")
            #   pid = pidfile.read

            #   run_all

            #   system("kill #{pid}") if (pid and !pid.empty?)
            # ensure
            #   @runner.cleanup
            # end
          else
            # reload the file
            Containment.new.protect do
              load p
            end
          end
        end
      end
    end

    private

    def set_up_reloaders(options)
      reloaders = Reloaders.new
      reloader_methods = [:reload_rails, :reload_paths, :reload_factory_girl]
      reloader_procs = reloader_methods.map { |name| method(name) }
      reloader_procs += options[:custom_reloaders]
      reloader_procs.each { |reloader| reloaders.register &reloader }

      reloaders
    end

    def unload_previous_examples
      ::RSpec.configuration.reset
      ::RSpec.world.reset
    end
  end
end

