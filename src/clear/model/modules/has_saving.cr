module Clear::Model::HasSaving
  getter? read_only : Bool = false
  getter? persisted : Bool

  def save
    raise Clear::Model::ReadOnlyModel.new("The model is read-only") if read_only?

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
      raise Clear::Model::InvalidModelError.new(
        "Validation of the model failed:\n #{print_errors}") unless save
    end

    return self
  end

  def delete
    return false unless persisted?

    with_triggers(:delete) do
      Clear::SQL::DeleteQuery.new.from(self.class.table).where{ var("#{self.class.pkey}") == pkey }.execute

      @persisted = false
      clear_change_flags
    end

    return true
  end

end
