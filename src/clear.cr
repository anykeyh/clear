require "logger"

#
# # Welcome to Clear ORM !
#

module Clear
  class_getter logger : Logger = Logger.new(STDOUT)
end

require "./clear/**"
