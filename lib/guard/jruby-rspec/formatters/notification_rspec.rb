require "guard/rspec/formatter"

superclass = if Guard::RSpec::Formatter.instance_of? Module # guard-rspec-1.x
               Object
             elsif Guard::RSpec::Formatter.instance_of? Class # guard-rspec-2.x
               Guard::RSpec::Formatter
             else
               fail 'Guard::RSpec::Formatter is neither class nor module'
             end

class Guard::JRubyRSpec::Formatter::NotificationRSpec < superclass
  include Guard::RSpec::Formatter if Guard::RSpec::Formatter.instance_of? Module

  def dump_summary(duration, total, failures, pending)
    message = guard_message(total, failures, pending, duration)
    image   = guard_image(failures, pending)
    notify(message, image)
  end

end
