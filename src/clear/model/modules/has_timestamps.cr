module Clear::Model::HasTimestamps
  macro timestamps
    column( updated_at : Time )
    column( created_at : Time )

    puts "HERE?"
    before(:validate) do |model|
      model = model.as(self)

      unless model.persisted?
        now = Time.now
        model.created_at = now
        model.updated_at = now
      end
    end

    puts "OR HERE?"
    after(:validate) do |model|
      model = model.as(self)

      # In the case the updated_at has been changed, we do not override.
      # It happens on first insert, in the before validation setup.
      if model.changed? && !model.updated_at_column.changed?
        model.updated_at = Time.now
      end

    end
    puts "MEH?"

  end
end
