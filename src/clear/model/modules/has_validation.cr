require "../validation/helper"

module Clear::Model::HasValidation
  record Error, reason : String, field : String?

  getter errors : Array(Error) = [] of Error

  # Add validation error not related to a specific column
  def add_error(reason)
    @errors << Error.new(reason: reason, field: nil)
  end

  # Add validation error related to a specific column
  def add_error(field, reason)
    @errors << Error.new(reason: reason, field: field.to_s)
  end

  def error?
    @errors.any?
  end

  def clear_errors
    @errors.clear
  end

  def print_errors
    @errors.group_by(&.field).to_a.sort { |(f1, _), (f2, _)| (f1 || "") <=> (f2 || "") }.map do |field, errors|
      if field
        "#{field}: #{errors.map(&.reason).join(", ")}"
      else
        errors.map(&.reason).join(", ")
      end
    end.join("\n")
  end

  def validate
    # Must be overwritten
  end

  def valid!
    valid? || raise InvalidModelError.new("Model is invalid: #{print_errors}")
  end

  def valid?
    clear_errors

    with_triggers(:validate) {
      validate_field_presence # < This is built by the column system
      validate
    }

    !error?
  end

  include Clear::Validation::Helper
end
