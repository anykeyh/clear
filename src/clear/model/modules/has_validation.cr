require "../validation/helper"

module Clear::Model::HasValidation
  record Error, reason : String, column : String?

  # List of errors raised during validation, in case the model hasn't been saved properly.
  getter errors : Array(Error) = [] of Error

  # Add validation error not related to a specific column
  def add_error(reason)
    @errors << Error.new(reason: reason, column: nil)
  end

  # Add validation error related to a specific column
  def add_error(column, reason)
    @errors << Error.new(reason: reason, column: column.to_s)
  end

  # Return `true` if saving has been declined because of validation issues.
  # The error list can be found by calling `Clear::Model#errors`
  def error?
    !@errors.empty?
  end

  # Clear the errors log (if any) of the model and return itself
  def clear_errors
    @errors.clear
    self
  end

  # Print the errors in string. Useful for debugging or simple error handling.
  def print_errors
    @errors.group_by(&.column).to_a.sort { |(f1, _), (f2, _)| (f1 || "") <=> (f2 || "") }.join("\n") do |column, errors|
      [column, errors.join(", ", &.reason)].compact.join(": ")
    end
  end

  # This method is called whenever `valid?` or `save` is called.
  # By default, `validate` is empty and must be overriden by your own validation code.
  def validate
    # Can be overwritten
  end

  # Check whether the model is valid. If not, raise `InvalidModelError`.
  # Return the model itself
  def valid!
    raise InvalidError.new(self) unless valid?
    self
  end

  # Return `true` if the model
  def valid?
    clear_errors

    with_triggers(:validate) {
      validate
      validate_fields_presence # < This is built by the column system using Union type !!
    }

    !error?
  end

  include Clear::Validation::Helper
end
