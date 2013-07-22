class VerEx < Regexp
    
  def initialize(&block)
    @prefixes = ""
    @source = ""
    @suffixes = ""
    @modifiers = "" # TODO: Ruby Regexp option flags
    @self_before_instance_eval = eval "self"
    instance_eval &block
    super(@prefixes + @source + @suffixes, @modifiers)
  end
  
  def method_missing(method, *args, &block)
    @self_before_instance_eval.send method, *args, &block
  end
  
  # We try to keep the syntax as
  # user-friendly as possible.
  # So we can use the "normal"
  # behaviour to split the "sentences"
  # naturally.
  # TODO: then is reserved in ruby, so use find or think of a better name
  def find(value)
    value = sanitize(value)
    add("(#{value})")
  end
  
  private
    
    # Sanitation function for adding
    # anything safely to the expression
    def sanitize(value)
      case value
      when Regexp, VerEx
        value.source
      else
        value.gsub(/([^\w])/) { "\\#{$1}" } # Escape non word chars
      end
    end
    
    # Function to add stuff to the
    # expression. 
    def add(value = '')
      @source += value
    end
    
end
