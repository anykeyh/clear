module Clear::Model::HasSaving

  # Default class-wise read_only? method is `false`
  macro included # When included into Model
    macro included # When included into final Model
      class_property? read_only : Bool = false

      # Import a bulk of models in one SQL insert query.
      # Each model must be non-persisted.
      #
      # `on_conflict` callback can be optionnaly turned on
      # to manage constraints of the database.
      #
      # Note: Old models are not modified. This method return a copy of the
      # models as saved in the database.
      #
      # ## Example:
      # ```crystal
      #
      #  users = [ User.new(id: 1), User.new(id: 2), User.new(id: 3)]
      #  users = User.import(users)
      # ```
      def self.import(array : Enumerable(self), on_conflict : (Clear::SQL::InsertQuery -> )? = nil)
        array.each do |item|
          raise "One of your model is persisted while calling import" if item.persisted?
        end

        hashes = array.map do |item|
          item.trigger_before_events(:save)
          raise "import: Validation failed for `#{item}`" unless item.valid?
          item.trigger_before_events(:create)
          item.to_h
        end

        query = Clear::SQL.insert_into(self.table, hashes).returning("*")
        on_conflict.call(query) if on_conflict

        o = [] of self
        query.fetch(@@connection) do |hash|
          o << factory.build(hash, persisted: true,
          fetch_columns: false, cache: nil)
        end

        o.each(&.trigger_after_events(:create))
        o.each(&.trigger_after_events(:save))

        o
      end
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
  # ## `on_conflict` optional parameter
  #
  # Example:
  #
  # ```crystal
  # u = User.new id: 123, email: "email@example.com"
  # u.save(-> (qry) { qry.on_conflict.do_update{ |u| u.set(email: "email@example.com") } #update
  # # IMPORTANT NOTICE: user may not be saved, but will be still detected as persisted !
  # ```
  #
  # You may want to use a block for `on_conflict` optional parameter:
  #
  # ```crystal
  # u = User.new id: 123, email: "email@example.com"
  # u.save do |qry|
  #    qry.on_conflict.do_update{ |u| u.set(email: "email@example.com")
  # end
  # ```
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

  # Performs like `save`, but instead of returning `false` if validation failed,
  # raise `Clear::Model::InvalidModelError` exception
  def save!(on_conflict : (Clear::SQL::InsertQuery -> )? = nil)
    raise Clear::Model::ReadOnlyModelError.new("The model is read-only") if self.class.read_only?

    raise Clear::Model::InvalidModelError.new(
      "Validation of the model failed:\n #{print_errors}") unless save(on_conflict)

    return self
  end

  # Pass the `on_conflict` optional parameter via block.
  def save!(&block : Clear::SQL::InsertQuery ->)
    return save!(block)
  end


  #  Delete the model by building and executing a `DELETE` query.
  #  A deleted model is not persisted anymore, and can be saved again.
  #     Clear will do `INSERT` instead of `UPDATE` then
  #  Return `true` if the model has been successfully deleted, and `false` otherwise.
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
