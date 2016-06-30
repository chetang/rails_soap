class SolitaireCertEntity < WashOut::Type
  map(
   :CertifiedBy => :string,
   :CertifiedId => :string
  )
end