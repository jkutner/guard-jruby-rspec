require "guard/rspec/formatter"

class Guard::JRubyRSpec::Formatter::NotificationRSpec < Guard::RSpec::Formatter

  def dump_summary(duration, total, failures, pending)
    message = guard_message(total, failures, pending, duration)
    image   = guard_image(failures, pending)
    notify(message, image)
  end

end
