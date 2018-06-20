module Clear::Model::Connection
  macro included # When included into Model
    macro included # When included into final Model
      class_property connection : Clear::SQL::Symbolic = "default"
    end
  end
end
