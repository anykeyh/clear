module Clear::Model::HasTimestamps
  macro timestamps
    column( updated_at : Time )
    column( created_at : Time )

    after(:validate) do |model|
      model = model.as(self)

      now = Time.now

      unless model.persisted?
        model.created_at = now
      end

      if model.changed?
        model.updated_at = now
      end
    end

  end
end
