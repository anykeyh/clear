require "db"

# A column of a Model
# Provide some methods like:
#   - Informations persistance (value before, value changed?)
#   - Raise error if we try to access the value of a field
#     which is not gathered through the query system (uninitialized column).
#     Or use the `get_def` to get with default value
class Clear::Model::Column(T)
  struct UnknownClass; end

  UNKNOWN = UnknownClass.new

  @value : T | UnknownClass

  getter old_value : T | UnknownClass
  getter name : String
  getter? changed : Bool = false
  getter? has_db_default : Bool = false

  def initialize(@name : String, @value : T | UnknownClass = UNKNOWN, @has_db_default = false)
    @old_value = @value
  end

  def value : T
    raise "You cannot access to the field `#{name}` " +
          "because it never has been initialized" unless defined?

    @value.as(T)
  end

  def value(default : X) : T | X forall X
    defined? ? @value.as(T) : default
  end

  def revert
    if @value != @old_value && @old_value != UNKNOWN
      @changed = true
      @value = @old_value
    end
  end

  # Reset the current field.
  # Restore the `old_value` state to current value.
  # Reset the flag `changed` to false.
  def reset(x : T?)
    @changed = false

    if T.nilable?
      @value = x.as(T)
    else
      raise "Your field `#{@name}` is declared as `#{T}` but `NULL` value has been found in the database.\n" +
            "Maybe declaring it as `#{T}?` would fix the mess !" if x.nil?
      @value = x.not_nil!
    end

    @old_value = @value
  end

  def value=(x : UnknownClass)
    @value = UNKNOWN
    @changed = false
  end

  def value=(x : T)
    if @value != x
      @value = x
      @changed = (@old_value != @value)
    end

    @value
  end

  # Return if the value can be nilable or not,
  # to check the presence during validation
  def nilable?
    T.nilable?
  end

  # If a column is not loaded (e.g. not defined once), it will show "#undef".
  # If a column is dirty (e.g. change hasn't be saved), it will show a "*" after the value.
  def inspect
    if defined?
      @value.inspect + (changed? ? "*" : "")
    else
      "#undef"
    end
  end

  def defined?
    @value != UNKNOWN
  end

  def failed_to_be_present?
    !nilable? &&
      !defined? &&
      !has_db_default?
  end

  def clear
    self.value = UNKNOWN
    @old_value = UNKNOWN
  end

  def clear_change_flag
    @changed = false
  end
end
