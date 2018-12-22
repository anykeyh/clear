class Clear::Model::EventManager
  alias HookFunction = Clear::Model -> Void
  alias EventKey = {String, Symbol, Symbol}

  EVENT_CALLBACKS = {} of EventKey => Array(HookFunction)
  INHERITANCE_MAP = {} of String => String

  def self.trigger(klazz, direction : Symbol, event : Symbol, mdl : Clear::Model)
    arr = EVENT_CALLBACKS.fetch({klazz.to_s, direction, event}){ [] of HookFunction }

    parent = INHERITANCE_MAP[klazz.to_s]?

    self.trigger(parent, direction, event, mdl) unless parent.nil?

    arr = arr.reverse if direction == :before
    
    arr.each do |fn|
      fn.call(mdl)
    end
  end

  def self.add_inheritance(parent, child)
    INHERITANCE_MAP[child.to_s] = parent.to_s
  end

  def self.attach(klazz, direction : Symbol, event : Symbol, block : HookFunction)
    tuple = {klazz.to_s, direction, event}
    arr = EVENT_CALLBACKS.fetch(tuple){ [] of HookFunction }

    arr.push(block)
    EVENT_CALLBACKS[tuple] = arr 
  end

end