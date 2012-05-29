require 'guard'
require 'guard/guard'
# require 'guard/jruby-rspec/runner'

module Guard
  class JRubyRSpec < Guard
    autoload :Runner,    'guard/jruby-rspec/runner'

    def initialize(watchers = [], options = {})
      @monitor = options[:monitor_file]
      @monitor ||= ".guard-jruby-rspec"

      @spec_paths = options[:spec_dir]
      @spec_paths ||= ["spec"]

      all_watchers = watchers + [
        Watcher.new(@monitor), 
        Watcher.new(%r{^(.+)\.rb$}),
        Watcher.new(%r{^(.+)\.(erb|haml)$})
      ]
      
      # touch the monitor file (lets the gjrspec know we're here)
      #File.open(@monitor, "w") {}

      super(all_watchers, options)

      @runner = Runner.new(options)

    end

    # Call once when guard starts
    def start
      UI.info "Guard::JRuby::RSpec is running, with RSpec!"
      run_all #if @options[:all_on_start]
    end

    def run_all      
      @runner.run(@spec_paths) # options should be configurable
    end

    def reload
      #UI.info "reload!"
    end

    def run_on_change(paths)
      paths.each do |p| 
        if File.exists?(p)
          if p == @monitor
            begin
              pidfile = open(@monitor, "r+")
              pid = pidfile.read

              run_all

              system("kill #{pid}") if (pid and !pid.empty?)
            ensure
              @runner.cleanup
            end
          else
            # reload the file
            load p 
          end
        end
      end
    end

  end
end

