class Reloaders
  def initialize
    @reloaders = []
  end

  # Add a reloader to be called on reload
  def register(options = {}, &block)
    if options[:prepend]
      @reloaders.unshift block
    else
      @reloaders << block
    end
  end

  def reload(paths = [])
    @reloaders.each do |reloader|
      reloader.call(paths)
    end
  end
end
