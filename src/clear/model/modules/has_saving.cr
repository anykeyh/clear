module Clear::Model::HasSaving
  getter? read_only : Bool = false

  def save
    with_triggers(:save) do
      if valid?
        if persisted?
          Clear::SQL.update(self.class.table).set(update_h).where { var("#{self.class.pkey}") == pkey }.execute
        else
          Clear::SQL.insert_into(self.class.table, to_h).returning(self.class.pkey).to_sql
          @persisted = true
          hash = Clear::SQL.insert_into(self.class.table, to_h).returning("*").execute
          self.set(hash)
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
    with_triggers(:save) do
      raise Clear::Model::InvalidModelError.new("Validation of the model failed:\n #{print_errors}") unless save
    end
  end
end
