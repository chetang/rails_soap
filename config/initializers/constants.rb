BATCH_PROCESSING_COUNT = 500
LD_API_URL = "http://localhost:4000/"
LD_ACTION_URLS = {
  bulk_update: LD_API_URL + "bulk_import",
  add_item: LD_API_URL + "items",
  update_prices: LD_API_URL + "update_prices",
  delete_solitaire: LD_API_URL + "delete_item",
  delete_all: LD_API_URL + "delete_all",
}