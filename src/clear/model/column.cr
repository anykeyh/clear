require "db"

# A column of a Model
# Provide some methods like:
#   - Informations persistance (value before, value changed?)
#   - Raise error if we try to access the value of a field
#     which is not gathered through the query system (uninitialized column).
#     Or use the `get_def` to get with default value
class Clear::Model::Column(T, C)
  include Clear::ErrorMessages

  struct UnknownClass
  end

  UNKNOWN = UnknownClass.new

  @value : T | UnknownClass

  getter old_value : T | UnknownClass
  getter name : String
  getter? changed : Bool = false
  getter? has_db_default : Bool = false

  def initialize(@name : String, @value : T | UnknownClass = UNKNOWN, @has_db_default = false)
    @old_value = @value
  end

  # Returns the current value of this column.
  # If the value has never been initialized, throw an exception
  def value : T
    raise illegal_setter_access_to_undefined_column(@name) unless defined?
    @value.as(T)
  end

  # Return the database converted value using the converter
  def to_sql_value(default = nil) : Clear::SQL::Any
    C.to_db(value(default))
  end

  # Returns the current value of this column or `default` if the value is undefined.
  def value(default : X) : T | X forall X
    defined? ? @value.as(T) : default
  end

  # If the column is dirty (e.g the value has been changed), return to the previous state.
  def revert
    if @value != @old_value && @old_value != UNKNOWN
      @changed = true
      @value = @old_value
    end

    @value
  end

  def reset_convert(x)
    reset C.to_column(x)
  end

  def set_convert(x)
    set C.to_column(x)
  end

  def set(x : T?)
    old_value = @value
    {% if T.nilable? %}
      @value = x.as(T)
    {% else %}
      raise null_column_mapping_error(@name, T) if x.nil?
      @value = x.not_nil!
    {% end %}

    @old_value = old_value
    @changed = true
  end

  # Reset the current field.
  # Restore the `old_value` state to current value.
  # Reset the flag `changed` to false.
  def reset(x : T?)
    {% if T.nilable? %}
      @value = x.as(T)
    {% else %}
      raise null_column_mapping_error(@name, T) if x.nil?
      @value = x.not_nil!
    {% end %}

    @changed = false
    @old_value = @value
  end

  # :nodoc:
  def value=(x : UnknownClass)
    @value = UNKNOWN
    @changed = false

    @value
  end

  # Set the value of the column to the value `x`. If `x` is not equal to the old value, then the column `changed?`
  # flag is set to `true`.
  def value=(x : T)
    @changed = (@old_value != x)
    @value = x
  end

  # Return `true` if the value is an union of a Type with Nilable, `false` otherwise.
  def nilable?
    T.nilable?
  end

  # Inspect this column.
  # If a column is not loaded (e.g. not defined once), it will show "#undef".
  # If a column is dirty (e.g. change hasn't be saved), it will show a "*" after the value.
  def inspect
    if defined?
      @value.inspect + (changed? ? "*" : "")
    else
      "#undef"
    end
  end

  # :nodoc:
  def inspect(io)
    io << inspect
  end

  # Check whether the column is defined or not.
  def defined?
    UNKNOWN != @value
  end

  # :nodoc:
  def failed_to_be_present?
    !nilable? &&
      !defined? &&
      !has_db_default?
  end

  # Completely clear the column, remove both `value` and `old_value` and turning the column in a non-defined state.
  def clear
    self.value = UNKNOWN
    @old_value = UNKNOWN

    @changed = false

    self
  end

  # Reset `changed?` flag to `true`. See `Column(T)#clear_change_flag` for the counter part.
  def dirty!
    @changed = true
    self
  end

  # Reset `changed?` flag to `false`. See `Column(T)#dirty!` for the counter part.
  def clear_change_flag
    @changed = false
    @old_value = @value
    self
  end
end
