require "../spec_helper"

# puts \
#   Clear::ErrorMessages.format_width \
#     "Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque "+
#     "laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi "+
#     "architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia " +
#     "voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui " +
#     "ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia " +
#     "dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora " +
#     "incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, " +
#     "quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea " +
#     "commodi consequatur? Quis autem vel eum iure reprehenderit qui in " +
#     "ea voluptate velit esse quam nihil molestiae consequatur, " +
#     "vel illum qui dolorem eum fugiat quo voluptas nulla pariatur", 80


# class User
#   include Clear::Model
#   with_serial_pkey
#   column username : String
#   column password : String
#   column auth_key : String?
#   column auth_user : String?
#   column session_id : String?
#   column expires : Time?
#   column updated_on : Time?
#   column created_on : Time?
#   self.table = "user"
# end

# Clear::SQL.init("postgres://postgres@localhost/clear_spec")
# Clear.logger.level = ::Logger::DEBUG

# Clear::SQL.execute <<-SQL
#   CREATE TABLE IF NOT EXISTS  "user" (
#     id bigint PRIMARY KEY,
#     username VARCHAR(32) NOT NULL,
#     password VARCHAR(32) NOT NULL,
#     auth_key text,
#     session_id text,
#     expires timestamp without time zone,
#     updated_on timestamp without time zone,
#     created_on timestamp without time zone
#   )
# SQL


# User.create! id: 1, username: "Helloword", password: "xxx"
# pp User.query.to_a