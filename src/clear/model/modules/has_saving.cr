module Clear::Model::HasSaving
  def save
    with_triggers(:save) do
      if persisted?
        Clear::SQL.update(self.class.table).set(update_h).where { var("#{self.class.pkey}") == pkey }.to_sql
      else
        Clear::SQL.insert_into(self.class.table, to_h).to_sql
      end
    end

    true
  end

  # macro included
  #   class_property table : Clear::SQL::Symbolic = self.name.downcase.pluralize
  # end
end
