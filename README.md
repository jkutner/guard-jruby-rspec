# guard-jruby-rspec

This guard extention allows you to run all of your specs on JRuby without the initial start up cost.  *It does not run a subset of your specs like guard-rspec* and it does not trigger a run when a file changes.

Instead, this extension loads all of your application files in advance, and reloads any that change.  That way, when you run RSpec, the JVM is already running, and your files have already been required.

## How to Use

Just add this to your guard file:

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

NOTE: sometime you have to hit return twice because stdin is flaky on JRuby. You probably see this message a lot, but it's okay:

    stty: stdin isn't a terminal

This will be improved.

## TODO

+  Autorun specs like guard-rspec (want to integrate with guard-rspec so as to not duplicate all of it's logic).

+  Allow for extra rspec options

+  Fix the way guard uses stdin so its not flaky on JRuby

+  Work out the kinks in gj-rspec script so that specs can be run in main terminal.

## Author

[@codefinger](http://twitter.com/#!/codefinger)