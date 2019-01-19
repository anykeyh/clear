## Usage

*NOTE*: Polymorphism is currently experimental; feel free to open issues.

Table polymorphism allows you to store different models through a single table. 
On other hand, fetching a model will recreate the proper object.

Polymorphism is currently working on one level only. The base class should include `Clear::Model` and can be abstract. Due to the nature of compiled language of Crystal, you need to list the children into the base class.

Polymorphism is defined by the usage of the macro `polymorphic(*subclasses, through = "type")`.

The concrete class of the object is saved into the `through` column (by default: type). The class name is then saved as full qualified name (with parent module) in Crystal.

*NOTE*: Polymorphism works currently only on objects, not on references.

```crystal

abstract class Animal::Base
  include Clear::Model

  self.table = "animals"

  column name : String

  polymorphic Dog, Cat, through: "type"

  abstract def cry!
end

class Animal::Cat < Animal::Base
  column kitten_options : JSON::Any

  def cry!
     puts "Meow !"
  end
end

class Animal::Dog < Animal::Base
  def cry!
     puts "Woof !"
  end
end

#...

# Create an animal
Animal::Cat.create!

# Use the abstract class to query !
Animal::Base.query.all.each(&.cry!)
```

## Using query from concrete type

```crystal
  Animal::Cat.query.each do |cat|
  end
```

Will translate into `SELECT * FROM animals WHERE type='Animal::Cat'`