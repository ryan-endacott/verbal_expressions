# Ruby Verbal Expressions, based on the awesome JavaScript repo by @jehna: https://github.com/jehna/VerbalExpressions

# For documentation and install instructions,
# see the main Ruby repo: https://github.com/ryan-endacott/VerbalExpressions.rb

class VerEx < Regexp

  def initialize(&block)
    @prefixes = ""
    @source = ""
    @suffixes = ""
    @modifiers = "" # TODO: Ruby Regexp option flags
    @self_before_instance_eval = eval "self", block.binding
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
    add("(?:#{value})")

    return self
  end

  # start or end of line

  def start_of_line(enable = true)
    @prefixes = '^' if enable

    return self
  end

  def end_of_line(enable = true)
    @suffixes = '$' if enable

    return self
  end

  # Maybe is used to add values with ?
  def maybe(value)
    value = sanitize(value)
    add("(?:#{value})?")

    return self
  end

  # Any character any number of times
  def anything
    add("(?:.*)")

    return self
  end

  # Anything but these characters
  def anything_but(value)
    value = sanitize(value)
    add("(?:[^#{value}]*)")

    return self
  end

  # Regular expression special chars


  def line_break
    add('(?:\n|(?:\r\n))')

    return self
  end

  # And a shorthand for html-minded
  alias_method :br, :line_break

  def tab
    add('\t')

    return self
  end

  # Any alphanumeric
  def word
    add('\w+')

    return self
  end

  # Any single digit
  def digit
    add('\d')

    return self
  end

  # Any integer (multiple digits)
  def integer
    one_or_more { digit }

    return self
  end

  # Any whitespace character
  def whitespace()
    add('\s+')

    return self
  end

  # Any given character
  def any_of(value)
    value = sanitize(value)
    add("[#{value}]")

    return self
  end

  #At least one of some other thing
  def one_or_more(&b)
    add("(?:")
    yield
    add(")+")
  end

  def zero_or_more(&b)
    add("(?:")
    yield
    add(")*")
  end

  alias_method :any, :any_of

  # Usage: range( from, to [, from, to ... ] )
  def range(*args)
    value = "["
    args.each_slice(2) do |from, to|
      from = sanitize(from)
      to = sanitize(to)
      value += "#{from}-#{to}"
    end
    value += "]"
    add(value)

    return self
  end

  # Loops

  def multiple(value,min=nil,max=nil)
    value = "(" + sanitize(value) + ")"
    if min != nil and max != nil 
      value += "{#{min},#{max}}"
    elsif min != nil and max == nil
      value += "{#{min},}"
    else
      value += "+"
    end
    add(value)

    return self
  end

  # Adds alternative expressions
  # TODO: or is a reserved keyword in ruby, think of better name
  def alternatively(value = nil)
    @prefixes += "(?:" unless @prefixes.include?("(")
    @suffixes = ")" + @suffixes unless @suffixes.include?(")")
    add(")|(?:")
    if value != nil
      value = sanitize(value)
      add("(?:#{value})")
    end

    return self
  end

  # Capture groups (can optionally name)
  def begin_capture(name = nil)
    if name
      add("(?<#{name}>")
    else
      add("(")
    end

    return self
  end

  def end_capture
    add(")")

    return self
  end

  def capture(name = nil, &block)
    begin_capture(name)
    yield
    end_capture
  end

  private

    # Sanitation function for adding
    # anything safely to the expression
    def sanitize(value)
      case value
      when Regexp, VerEx
        value.source
      else
        Regexp.quote(value)
      end
    end

    # Function to add stuff to the
    # expression. Also compiles the
    # new expression so it's ready to
    # be used.
    def add(value = '')
      @source += value
    end

end

class VerExChain < VerEx
  def initialize
    @prefixes  = ""
    @source    = ""
    @suffixes  = ""
    @modifiers = "" 
  end

  alias_method :or  ,:alternatively
  alias_method :then,:find
  def end
    return Regexp.new(@prefixes + @source + @suffixes)
  end

  def end_of_line
    super
    return Regexp.new(@prefixes + @source + @suffixes)
  end

end

# Usage of VerExChain
# -------------------
# Always use .end() at end of expression chain. 
# If there is an end_of_line() at the end of expression,
# then there is no need for calling end.
# And also - or() and then() are available in VerExChain.

# v = VerExChain.new
#   .start_of_line
#   .find('http')
#   .maybe('s')
#   .then('://')
#   .maybe('www.')
#   .anything_but(' ')
#   .end_of_line
# puts "Works." if v =~ "http://google.com/"
# puts v.source

# expression = VerExChain.new
#                 .find( "http" )
#                 .maybe( "s" )
#                 .then( "://" )
#                 .or()
#                 .then( "ftp://" )
#                 .end()
# puts "Works. 2" if expression =~ "ftp://"
# puts "Works. 3" if expression =~ "http://"



# replace_me = "Replace bird with a duck"
# Create an expression that seeks for word "bird"
# expression = VerExChain.new.find('bird').end

# Execute the expression like a normal Regexp object
# result = replace_me.gsub( expression, "duck" );

# puts result # Outputs "Replace duck with a duck"


# multiple() tests - 
# v = VerEx.new do
#    start_of_line
#    multiple("1",2,5)
#    end_of_line
#  end
# puts "Match" if v =~ "11111"
# puts v.source