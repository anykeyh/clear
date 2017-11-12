module Clear::Model::HasSaving
  def save
    with_triggers(:save) do
      if persisted?
        Clear::SQL.update(self.class.table).set(update_h).where { var("#{self.class.pkey}") == pkey }.execute
      else
        Clear::SQL.insert_into(self.class.table, to_h).execute
      end
    end

    true
  end
end
