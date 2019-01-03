module Clear::Model::HasHooks
  # This performs theses operations:
  #
  # - Call triggers `before` the event
  # - Yield the given block
  # - Call triggers `after` the event
  #
  # ```
  #    model.with_triggers("email_sent") do |m|
  #       model.send_email
  #    end
  # ```
  #
  # Returns `self`
  def with_triggers(event_name, &block)
    trigger_before_events(event_name)
    yield
    trigger_after_events(event_name)

    self
  end

  # Triggers the events hooked before `event_name`
  def trigger_before_events(event_name)
    Clear::Model::EventManager.trigger(self.class, :before, event_name, self)
  end

  # Triggers the events hooked after `event_name`
  def trigger_after_events(event_name)
    Clear::Model::EventManager.trigger(self.class, :after, event_name, self)
  end

  module ClassMethods
    def before(event_name : Symbol, &block : Clear::Model -> Void)
      Clear::Model::EventManager.attach(self, :before, event_name, block)
    end

    def after(event_name : Symbol, &block : Clear::Model -> Void)
      Clear::Model::EventManager.attach(self, :after, event_name, block)
    end
  end

  macro before(event_name, method_name)
    before({{event_name}}) { |mdl|
      mdl.as({{@type}}).{{method_name.id}}
    }
  end

  macro after(event_name, method_name)
    after({{event_name}}) { |mdl|
      mdl.as({{@type}}).{{method_name.id}}
    }
  end

end
