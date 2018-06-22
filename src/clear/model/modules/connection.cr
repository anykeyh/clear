module Clear::Model::Connection
  macro included # When included into Model
    macro included # When included into final Model
      class_property connection : String = "default"
    end
  end
end
