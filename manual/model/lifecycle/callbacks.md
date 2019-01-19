# Triggers

Clear provides a way to create triggers on different time of the lifecycle of the model.

## Example usage

```ruby
class User
    include Clear::Model

    column first_name : String
    column last_name : String

    def full_name
        {first_name, last_name}.join(" ")
    end

    after :create, :send_email

    before(:update) { |m| m.as(User).updated_at = Time.now }

    def send_email
        EmailManager.send_email(subject: "welcome #{full_name} !", body: "...")
    end
end
```

## Caveats

* Calling before/after with a block will return a Clear::Model as argument. Therefore, you must cast the variable \(`m.as(User)` in example above\).
* `before/after :action, :method` must be pointing to public method. If the method is private, the call will fail.

## Trigger list

| Trigger symbol | Description |
| :--- | :--- |
| `:validate` | Is triggered before and after calling `valid?` method |
| `:save` | Is triggered before and after calling `save` method |
| `:delete` | Is triggered before and after destroying a model |
| `:create` | Is triggered before and after calling `save` method, if the model is not yet persisted and save execute INSERT request. |
| `:update` | Is triggered before and after calling `save` method, if the model is already existing and save execute UPDATE request. |
| `:creation_commited` | **Note: PLANNED FEATURE NOT YET IMPLEMENTED**. Is triggered when a transaction is commited, for each model which has been created during the lifetime of a transaction |
| `:update_commited` | **Note: PLANNED FEATURE NOT YET IMPLEMENTED.** Is triggered when a transaction is commited, for each model which has been updated during the lifetime of a transaction |
| `:delete_commited` | **Note: PLANNED FEATURE NOT YET IMPLEMENTED.** Is triggered when a transaction is commited, for each model which has been destroyed during the lifetime of a transaction |

