module Clear::Model::HasValidation
  record Error, reason : String, field : String?

  getter errors : Array(Error) = [] of Error

  def add_error(reason, field = nil)
    @errors << Error.new(reason: reason, field: field)
  end

  def has_error?
    @errors.any?
  end

  def clear_errors
    @errors.clear
  end

  def check_than(x : T) forall T
    Validator(self, T).new
  end

  def validate
  end

  def valid?
    clear_errors

    with_triggers(:validate) { validate }

    !has_error?
  end
end
