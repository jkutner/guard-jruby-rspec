# guard-jruby-rspec

This guard extention allows you to run all of your specs on JRuby without the initial start up cost.  It loads all of your application files in advance, and reloads any that change.  That way, when you run RSpec, the JVM is already running, and your files have already been required.

Most of the config options available to `guard-rspec` work with this extension too.  

## How to Use On-Demand mode

Just add this to your guard file:

    interactor :simple
    guard 'jruby-rspec', :spec_paths => ["spec"]

Then run `guard` like this (probably with Bundler):

    $ bundle exec guard
    Using polling (Please help us to support your system better than that).
    The signal USR1 is in use by the JVM and will not work correctly on this platform
    Guard could not detect any of the supported notification libraries.
    Guard is now watching at '~/myapp'
    Guard::JRuby::RSpec is running, with RSpec!
    .......

    Finished in 0.735 seconds
    7 examples, 0 failures
    >

The first time guard starts up, it will run all of your specs in order to bootstrap the runtime.  This first run will be as slow as any other run on JRuby. 

Once you change some files, and press return at the guard prompt to rerun your specs. You'll notice it's a lot faster than running `rspec` from the command line. 

## How to Use Autorun mode

Add something like this to your guard file (alternatives are in the template file):

    interactor :simple
    guard 'jruby-rspec' do        
      watch(%r{^spec/.+_spec\.rb$})
      watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
      watch('spec/spec_helper.rb')  { "spec" }
    end

Proceed as in on-demand mode.

## Using CLI Options

The format that `guard-jruby-rspec` expects CLI options to be in is a little different than what `guard-rspec` exepcts.  Here is an example:

    interactor :simple
    guard "jruby-rspec", :cli => ["-c", "-t~slow"]

The CLI options should be an Array containing a number of strings.  Each string should be a flag and an option value with no space between the flag and the value.

## TODO

+  Autorun specs like guard-rspec (want to integrate with guard-rspec so as to not duplicate all of it's logic).

+  Allow for extra rspec options

+  Fix the way guard uses stdin so its not flaky on JRuby

+  Work out the kinks in gj-rspec script so that specs can be run in main terminal.

## Thank You

Thank you to the authors of `guard-rspec`.  I'm piggybacking off of the hard work done by [Thibaud Guillaume-Gentil](https://github.com/thibaudgg) and others!

## Author

[@codefinger](http://twitter.com/#!/codefinger)