ODIN_SOAP_API_URL = "http://huabi.ejewel.co.in/odinapi.asmx?WSDL"
ODIN_CLIENT = Savon.client(:wsdl => ODIN_SOAP_API_URL, :convert_request_keys_to => :camelcase)