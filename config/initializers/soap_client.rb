if Rails.env == "production"
  # ODIN_SOAP_API_URL = "http://huabi.ejewel.co.in/odinapi.asmx?WSDL"
  ODIN_SOAP_API_URL = "http://huabi.azurewebsites.net/odinAPI.asmx?wsdl"
else
  ODIN_SOAP_API_URL = ""
end

ODIN_CLIENT = Savon.client(:wsdl => ODIN_SOAP_API_URL, :convert_request_keys_to => :camelcase, open_timeout: 7200, read_timeout: 600)