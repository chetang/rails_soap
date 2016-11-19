BATCH_PROCESSING_COUNT = 500
if Rails.env == "production"
  LD_API_URL = "http://app.liquid.diamonds/"
else
  LD_API_URL = "http://localhost:4000/"
end
LD_ACTION_URLS = {
  bulk_update: "#{LD_API_URL}bulk_import",
  add_item: "#{LD_API_URL}items",
  update_prices: "#{LD_API_URL}update_prices",
  delete_solitaire: "#{LD_API_URL}delete_item",
  delete_all: "#{LD_API_URL}delete_all",
  bulk_delete: "#{LD_API_URL}bulk_delete"
}