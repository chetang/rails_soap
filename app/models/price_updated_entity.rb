class PriceUpdatedEntity < WashOut::Type
  map(
   :CertifiedBy => :string,
   :CertifiedId => :string,
   :UpdatedPrice => :double
  )
end