module Clear::Model::HasHooks
  macro included
    alias HookFunction = self -> Void

    EVENTS_BEFORE = {} of Symbol => Array(HookFunction)
    EVENTS_AFTER = {} of Symbol => Array(HookFunction)

    macro included
      macro before(event_name, method)
        before(:"\\{{event_name.id}}"){ |mdl| mdl.as(\{{@type}}).\\{{method}}  }
      end

      macro after(event_name, method)
        after(:"\\{{event_name.id}}"){ |mdl| mdl.as(\{{@type}}).\\{{method}}  }
      end
    end

  end

  module ClassMethods
    def before(event_name, &block : HookFunction)
      EVENTS_BEFORE[event_name] = [] of HookFunction unless EVENTS_BEFORE[event_name]?
      EVENTS_BEFORE[event_name] << block
    end

    def after(event_name, &block : HookFunction)
      EVENTS_AFTER[event_name] = [] of HookFunction unless EVENTS_BEFORE[event_name]?
      EVENTS_AFTER[event_name] << block
    end
  end

  def with_triggers(event_name, &block)
    (EVENTS_BEFORE[event_name]? || [] of HookFunction).each do |cb|
      cb.call(self)
    end

    with self yield

    (EVENTS_AFTER[event_name]? || [] of HookFunction).each do |cb|
      cb.call(self)
    end
  end
end
