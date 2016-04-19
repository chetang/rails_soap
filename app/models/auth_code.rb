class AuthCode < WashOut::Type
  map(
   :UserName => :string,
   :Password => :string
  )
end

class AuthCodeAttr < WashOut::Type
  type_name 'auth_code_attr'
  map :AuthCodeAttr => AuthCode
end