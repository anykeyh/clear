require "crypto/bcrypt/password"

# Fix issue in the Bcrypt::Password equality check
# https://github.com/crystal-lang/crystal/issues/6339
class Crypto::Bcrypt::Password
  def ==(password)
    super(password)
  end

  def ==(password : String)
    hashed_password = Bcrypt.new(password, salt, cost)
    Crypto::Subtle.constant_time_compare(@raw_hash, hashed_password)
  end
end

module Clear::Model::Converter::BcryptPasswordConverter
  def self.to_column(x) : ::Crypto::Bcrypt::Password?
    case x
    when String
      return ::Crypto::Bcrypt::Password.new(x)
    when ::Crypto::Bcrypt::Password
      return x
    when Nil
      return nil
    else
      raise Clear::ErrorMessages.converter_error(x.class.name, "Crypto::Bcrypt::Password")
    end
  end

  def self.to_db(x : ::Crypto::Bcrypt::Password?)
    case x
    when ::Crypto::Bcrypt::Password?
      return x.to_s
    when Nil
      return nil
    end
  end
end

Clear::Model::Converter.add_converter("Crypto::Bcrypt::Password", Clear::Model::Converter::BcryptPasswordConverter)
