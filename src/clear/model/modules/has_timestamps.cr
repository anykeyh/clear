module Clear::Model::HasTimestamps
  macro timestamps
    column( updated_at : Time )
    column( created_at : Time )

    before(:validate) do |model|
      model = model.as(self)

      now = Time.now

      unless model.persisted?
        model.created_at = now
      end

      model.updated_at = now
    end

  end
end
