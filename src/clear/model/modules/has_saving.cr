module Clear::Model::HasSaving

  # Default class-wise read_only? method is `false`
  macro included # When included into Model
    macro included # When included into final Model
      class_property? read_only : Bool = false
    end
  end

  getter? persisted : Bool

  def save
    return false if self.class.read_only?

    with_triggers(:save) do
      if valid?
        if persisted?

          h = update_h

          if h.any?
            with_triggers(:update) do
              Clear::SQL.update(self.class.table).set(update_h).where { var("#{self.class.pkey}") == pkey }.execute(@@connection)
            end
          end
        else
          with_triggers(:create) do
            @persisted = true
            pp "Execute insert?"
            hash = Clear::SQL.insert_into(self.class.table, to_h).returning("*").execute(@@connection)
            self.set(hash)
          end
        end

        self.clear_change_flags
        return true
      else
        return false
      end
    end

    return true
  end

  def save!
    raise Clear::Model::ReadOnlyModelError.new("The model is read-only") if self.class.read_only?

    raise Clear::Model::InvalidModelError.new(
      "Validation of the model failed:\n #{print_errors}") unless save

    return self
  end

  def delete
    return false unless persisted?

    with_triggers(:delete) do
      Clear::SQL::DeleteQuery.new.from(self.class.table).where{ var("#{self.class.pkey}") == pkey }.execute(@@connection)

      @persisted = false
      clear_change_flags
    end

    return true
  end

end
