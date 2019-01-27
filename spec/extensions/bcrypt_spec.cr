require "../spec_helper"
require "crypto/bcrypt/password"

module BCryptSpec
  extend self

  class EncryptedPasswordMigration57632
    include Clear::Migration

    def change(dir)
      create_table(:bcrypt_users, id: :uuid) do |t|
        t.string :encrypted_password
      end
    end
  end

  class User
    include Clear::Model

    primary_key type: :uuid

    self.table = "bcrypt_users"

    column encrypted_password : Crypto::Bcrypt::Password
  end

  def self.reinit!
    reinit_migration_manager
    EncryptedPasswordMigration57632.new.apply(Clear::Migration::Direction::UP)
  end

  describe "Clear::Migration::CreateEnum" do
    it "Can create bcrypt password" do
      temporary do
        reinit!

        User.create!({encrypted_password: Crypto::Bcrypt::Password.create("abcd")})

        User.query.count.should eq 1
        User.query.first!.encrypted_password.should eq "abcd"
        User.query.first!.encrypted_password.should_not eq "abce"

        usr = User.query.first!

        usr.encrypted_password = Crypto::Bcrypt::Password.create("lorem.ipsum")
        usr.save!

        User.query.first!.encrypted_password.should_not eq "abcd"
        User.query.first!.encrypted_password.should eq "lorem.ipsum"
      end
    end
  end
end
