# Global storage for model lifecycle event management
#
# This class acts as a storage and can trigger events
# This class a singleton.
class Clear::Model::EventManager
  alias HookFunction = Clear::Model -> Nil
  alias EventKey = {String, Symbol, Symbol}

  EVENT_CALLBACKS = {} of EventKey => Array(HookFunction)
  INHERITANCE_MAP = {} of String => String

  # Trigger events callback for a specific model.
  # Direction can be `:before` and `:after`
  # In case of `:before` direction, the events are called in reverse order:
  # ```
  # before:
  # - Last defined event
  # - First defined event
  # action
  # after:
  # - First defined events
  # - Last defined events
  def self.trigger(klazz, direction : Symbol, event : Symbol, mdl : Clear::Model)
    arr = EVENT_CALLBACKS.fetch({klazz.to_s, direction, event}) { [] of HookFunction }

    parent = INHERITANCE_MAP[klazz.to_s]?

    if direction == :after
      arr = arr.reverse

      arr.each &.call(mdl)
      self.trigger(parent, direction, event, mdl) unless parent.nil?
    else
      self.trigger(parent, direction, event, mdl) unless parent.nil?
      arr.each &.call(mdl)
    end
  end

  def self.has_trigger?(klazz, direction : Symbol, event : Symbol)
    return true if EVENT_CALLBACKS[{klazz.to_s, direction, event}]?

    parent = INHERITANCE_MAP[klazz.to_s]?

    has_trigger?(parent, direction, event) unless parent.nil?
  end

  # Map the inheritance between models. Events which belongs to parent model are triggered when child model lifecycle
  # actions occurs
  def self.add_inheritance(parent, child)
    INHERITANCE_MAP[child.to_s] = parent.to_s
  end

  # Add an event for a specific class, to a specific direction (after or before), a specific event Symbol (validate, save, commit...)
  def self.attach(klazz, direction : Symbol, event : Symbol, block : HookFunction)
    tuple = {klazz.to_s, direction, event}
    arr = EVENT_CALLBACKS.fetch(tuple) { [] of HookFunction }

    arr.push(block)
    EVENT_CALLBACKS[tuple] = arr
  end
end
