require "crypto/bcrypt/password"

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
