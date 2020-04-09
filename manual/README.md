# Welcome to Clear

Welcome to Clear, the ORM specifically developed for PostgreSQL and Crystal Language.

After reading this guide, you will know:

* How to install and configure Clear for your project
* How to use Clear to manipulate the data stored in your database
* How to take advantage of the advanced features of PostgreSQL combined seamlessly with the powerful Crystal Language features
* How to maintain the coherence of your database through migration and validations. 

## What is Clear ?

Clear is an ORM \(Object Relation Mapping\) built for Crystal language. 

It offers the Model layer of your applications. 

Clear is built especially for PostgreSQL, meaning it's not compatible with MariaDB or SQLite for example. Therefore, it achieves to delivers a tremendous amount of PostgreSQL advanced features out of the box.

Clear is largely based on Active Record pattern, and freely inspired by [Rails Active Record](https://github.com/rails/rails/tree/master/activerecord) and [Sequel](https://github.com/jeremyevans/sequel). Thus, it follow some philosophical concepts, as:

* **Convention over configuration:** While it's possible to name your models and key the way you want, linking achieved without any directives in the code by using the default naming convention:

| Crystal | PostgreSQL |
| :--- | :--- |
| **class** ModelName | **TABLE** model\_names |
| **belongs\_to** foreign\_object | **COLUMN** foreign\_object\_id : bigint |

{% hint style="info" %}
If you already works with Ruby on Rails, you will notice that the naming convention follow ActiveRecord pattern.
{% endhint %}

* **Multiple way of doing things:** Philosophically, Clear try to reduce the gap between the mind of the developer and the code itself. The code is meant to be read as close to written English as possible. Therefore, there's often multiple way to do things, based on the feeling of the developer writing the code. 
* **Less boilerplate = more happiness:** The "magic" under Clear allows to write as minimum as possible boilerplate code, like type-checking, validations or even SQL fragment writing.

