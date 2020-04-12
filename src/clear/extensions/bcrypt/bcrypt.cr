require "crypto/bcrypt/password"

module Clear::Model::Converter::BcryptPasswordConverter
  def self.to_column(x) : ::Crypto::Bcrypt::Password?
    case x
    when String
      ::Crypto::Bcrypt::Password.new(x)
    when ::Crypto::Bcrypt::Password
      x
    when Nil
      nil
    else
      raise Clear::ErrorMessages.converter_error(x.class.name, "Crypto::Bcrypt::Password")
    end
  end

  def self.to_db(x : ::Crypto::Bcrypt::Password?)
    return nil if x.nil?
    x.to_s
  end
end

Clear::Model::Converter.add_converter("Crypto::Bcrypt::Password", Clear::Model::Converter::BcryptPasswordConverter)
