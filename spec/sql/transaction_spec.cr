require "spec"

require "../spec_helper"

module TransactionSpec
  extend self

  describe "Clear::SQL::Transaction#transaction" do
    it "can create transactional block" do
      Clear::SQL.transaction { Clear::SQL.select("1").execute }
      Clear::SQL.transaction(level: Clear::SQL::Transaction::Level::ReadCommitted) { Clear::SQL.select("1").execute }
      Clear::SQL.transaction(level: Clear::SQL::Transaction::Level::RepeatableRead) { Clear::SQL.select("1").execute }
    end
  end

  describe "Clear::SQL::Transaction#after_commit" do
    it "executes the callback code when transaction is commited" do
      is_called = false

      Clear::SQL.transaction do
        Clear::SQL.after_commit { is_called = true }
        is_called.should be_false
      end

      is_called.should be_true
    end

    it "does not execute the callback code when transaction is rollback" do
      is_called = false

      Clear::SQL.transaction do
        Clear::SQL.after_commit do
          is_called = true
        end

        is_called.should be_false
        Clear::SQL.rollback
      end

      channel = Channel(Nil).new

      5.times do
        # Ensure the list is clear after this block
        # Using all the connections
        spawn do
          Clear::SQL.transaction do
            channel.send(nil)
          end

          channel.send(nil)
        end
      end

      10.times { channel.receive } # Wait for all the fibers to finish.

      is_called.should be_false
    end

    it "doesn't call twice the callback" do
      is_called = 0

      Clear::SQL.transaction do
        Clear::SQL.after_commit { is_called += 1 }
        is_called.should eq(0)
      end

      is_called.should eq(1)
      Clear::SQL.transaction { is_called.should eq(1) }
      is_called.should eq(1)
    end

    # Because after_commit is related to a specific transaction, it should raise
    # and error if we're not currently in transaction.
    it "raises an error if not yet in transaction" do
      expect_raises(Clear::SQL::Error, /in transaction/) do
        Clear::SQL.after_commit { puts "Do something" }
      end
    end

    it "is related to the current commit only" do
      # This test is a bit tricky to make it work
      # because the fiber scheduler is changing context on call to the database
      # (which are IO calls, so it makes sense).
      # To prevent this, we need to force waiting each fiber by using a channel
      channel = Channel(Nil).new
      called = "nope"

      Clear::SQL.transaction do
        Clear::SQL.after_commit { called = "last" }

        spawn do
          Clear::SQL.transaction do
            Clear::SQL.after_commit { called = "first" }
            channel.receive # Wait for the message to commit.
          end
          channel.send nil # We have now commited
        end

        called.should eq("nope")  # No call yet.
        channel.send nil          # Call the commit of the other transaction
        channel.receive           # Wait for the other transaction to commit
        called.should eq("first") # Now we commited the first transaction
      end                         # Finish second transaction

      called.should eq("last")
    end
  end
end
