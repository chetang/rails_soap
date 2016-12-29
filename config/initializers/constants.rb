BATCH_PROCESSING_COUNT = 500
if Rails.env == "production"
  LD_API_URL = "http://app.liquid.diamonds/"
else
  LD_API_URL = "http://localhost:4000/"
end
LD_DEMO_API_URL = "http://demo.liquid.diamonds/"

LD_ACTION_URLS = {
  bulk_update: "#{LD_API_URL}bulk_import",
  add_item: "#{LD_API_URL}items",
  update_prices: "#{LD_API_URL}update_prices",
  delete_solitaire: "#{LD_API_URL}delete_item",
  delete_all: "#{LD_API_URL}delete_all",
  bulk_delete: "#{LD_API_URL}bulk_delete"
}

LD_DEMO_ACTION_URLS = {
  bulk_update: "#{LD_DEMO_API_URL}bulk_import",
  add_item: "#{LD_DEMO_API_URL}items",
  update_prices: "#{LD_DEMO_API_URL}update_prices",
  delete_solitaire: "#{LD_DEMO_API_URL}delete_item",
  delete_all: "#{LD_DEMO_API_URL}delete_all",
  bulk_delete: "#{LD_DEMO_API_URL}bulk_delete"
}

HK_SOURCE_URL = "http://stock.hk.co/hkwebservice/packetlistservlet?usr=LIDIA&pwd=lidia123&typ=CSV"
HK_FILE_DESTINATION_FOLDER = "./public/ftp_upload/harikrishna"

KC_IN_HAND_STOCK_URL = "http://stock.kantilalchhotalal.com/GetData/S"
KC_ENTIRE_STOCK_URL = "http://stock.kantilalchhotalal.com/GetData/SM"
KC_SINGLE_DIAMOND_GET_URL = "http://stock.kantilalchhotalal.com/GetDataByLotBarcode/" # Append this by barcode id (stock number?)
# e.g.: http://stock.kantilalchhotalal.com/GetDataByLotBarcode/317302
KC_FILE_DESTINATION_FOLDER = "./public/ftp_upload/kantilalchhotalal"
