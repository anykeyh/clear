module Clear
  class_property logger : Logger = Logger.new(STDOUT)
end





# Require everything except the extensions and the CLI
require "./version"
require "./util"
require "./error_messages"
require "./seed"
require "./expression/**"
require "./sql/**"
require "./model/**"
require "./migration/**"
require "./view/**"