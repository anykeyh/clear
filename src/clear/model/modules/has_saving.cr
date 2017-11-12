module Clear::Model::HasSaving
  def save
    with_triggers(:save) do
      if persisted?
        Clear::SQL.update(self.class.table).set(update_h).where { var("#{self.class.pkey}") == pkey }.execute
        self.clear_change_flags
      else
        Clear::SQL.insert_into(self.class.table, to_h).returning(self.class.pkey).to_sql
        @persisted = true
        hash = Clear::SQL.insert_into(self.class.table, to_h).returning("*").execute
        self.set(hash)
      end
    end

    true
  end
end
