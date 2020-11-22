require "../spec_helper"
require "crypto/bcrypt/password"

module BCryptSpec
  extend self

  class EncryptedPasswordMigration57632
    include Clear::Migration

    def change(dir)
      create_table(:bcrypt_users, id: :uuid) do |t|
        t.column "encrypted_password", "string"
      end
    end
  end

  class User
    include Clear::Model

    primary_key :id, type: :uuid

    self.table = "bcrypt_users"

    column encrypted_password : Crypto::Bcrypt::Password
  end

  def self.reinit!
    reinit_migration_manager
    EncryptedPasswordMigration57632.new.apply
  end

  describe "Clear::Migration::CreateEnum" do
    it "Can create bcrypt password" do
      temporary do
        reinit!

        User.create!({encrypted_password: Crypto::Bcrypt::Password.create("abcd")})

        User.query.count.should eq 1
        User.query.first!.encrypted_password.verify("abcd").should be_true
        User.query.first!.encrypted_password.verify("abce").should be_false

        usr = User.query.first!

        usr.encrypted_password = Crypto::Bcrypt::Password.create("lorem.ipsum")
        usr.save!

        User.query.first!.encrypted_password.verify("abcd").should be_false
        User.query.first!.encrypted_password.verify("lorem.ipsum").should be_true
      end
    end
  end
end
