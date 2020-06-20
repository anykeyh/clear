# :nodoc:
module Clear::Model::Relations::HasOneMacro
  # :nodoc:
  # Write down the code for Has one relation
  macro generate(self_type, method_name, relation_type, foreign_key, primary_key)
    # Return the related model `{{method_name}}`.
    #
    # This relation is of type one to zero or one [1, 0..1]
    # between {{relation_type}} and {{self_type}}
    #
    # If the relation hasn't been cached, will call a `select` SQL operation.
    # Otherwise, will try to find in the cache.
    def {{method_name}} : {{relation_type}}?
      %primary_key = {{(primary_key || "pkey").id}}
      %foreign_key =  {{foreign_key}} || ( self.class.table.to_s.singularize + "_id" )

      {{relation_type}}.query.where{ raw(%foreign_key) == %primary_key }.first
    end

    # Return the related model `{{method_name}}`,
    # but throw an error if the model is not found.
    def {{method_name}}! : {{relation_type}}
      {{method_name}}.not_nil!
    end


  end
end
