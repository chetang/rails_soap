class SolitairePriceEntity < WashOut::Type
  map(
   :CertifiedBy => :string,
   :CertifiedId => :string,
   :UpdatedPrice => :double
  )
end