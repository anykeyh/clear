module Clear::Model::HasTimestamps
  macro timestamps
    field( updated_at : Time )
    field( created_at : Time )

    before(:save) do |model|
      now = Time.now

      unless model.persisted?
        model.created_at = now
      end

      model.updated_at = now
    end

  end
end
