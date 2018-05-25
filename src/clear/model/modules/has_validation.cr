require "../validation/helper"

module Clear::Model::HasValidation
  record Error, reason : String, column : String?

  getter errors : Array(Error) = [] of Error

  # Add validation error not related to a specific column
  def add_error(reason)
    @errors << Error.new(reason: reason, column: nil)
  end

  # Add validation error related to a specific column
  def add_error(column, reason)
    @errors << Error.new(reason: reason, column: column.to_s)
  end

  def error?
    @errors.any?
  end

  def clear_errors
    @errors.clear
  end

  def print_errors
    @errors.group_by(&.column).to_a.sort { |(f1, _), (f2, _)| (f1 || "") <=> (f2 || "") }.map do |column, errors|
      [column, errors.map(&.reason).join(", ")].compact.join(": ")
    end.join("\n")
  end

  def validate
    # Can be overwritten
  end

  def valid!
    raise InvalidModelError.new("Model is invalid: #{print_errors}") unless valid?
    self
  end

  def valid?
    clear_errors

    with_triggers(:validate) {
      validate_fields_presence # < This is built by the column system using Union type !!
      validate
    }

    !error?
  end

  include Clear::Validation::Helper
end
