module Clear::Model::HasSaving

  # Default class-wise read_only? method is `false`
  macro included # When included into Model
    macro included # When included into final Model
      class_property? read_only : Bool = false
    end
  end

  getter? persisted : Bool

  # Save the model. If the model is already persisted, will call `UPDATE` query. 
  # If the model is not persisted, will call `INSERT`
  #
  # Optionally, you can pass a `Proc` to refine the `INSERT` with on conflict
  # resolution functions.
  #
  # Return `false` if the model cannot be saved (validation issue)
  # Return `true` if the model has been correctly saved.
  #
  # Note: On first save, `persisted` is set to true.
  #
  # Example:
  #
  # ```crystal
  # u = User.new
  # if u.save
  #   puts "User correctly saved !"
  # else
  #   puts "There was a problem during save: "
  #   # do something with `u.errors`
  # end
  # ```
  #
  # ```crystal
  # u = User.new id: 123, email: "email@example.com"
  # u.save(-> (qry) { qry.on_conflict.do_update{ |u| u.set(email: "email@example.com") } #update
  # # Note: user may not be saved, but will be detected as persisted !
  # ```
  #
  #
  #
  def save(on_conflict : (Clear::SQL::InsertQuery -> )? = nil)
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
            query = Clear::SQL.insert_into(self.class.table, to_h).returning("*")
            on_conflict.call(query) if on_conflict
            hash = query.execute(@@connection)

            self.set(hash)
            @persisted = true
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

  def save(&block)
    save(on_conflict: block)
  end

  def save!(on_conflict : (Clear::SQL::InsertQuery -> )? = nil)
    raise Clear::Model::ReadOnlyModelError.new("The model is read-only") if self.class.read_only?

    raise Clear::Model::InvalidModelError.new(
      "Validation of the model failed:\n #{print_errors}") unless save(on_conflict)

    return self
  end

  def save!(&block : Clear::SQL::InsertQuery ->)
    return save!(block)
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
