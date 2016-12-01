class UsersController < ApplicationController
  soap_service namespace: 'urn:WashOut'
  before_filter :dump_parameters

  # before_action :authenticate_user!

  def index
    @users = User.all
  end

  def show
    @user = User.find(params[:id])
    unless @user == current_user
      redirect_to :back, :alert => "Access denied."
    end
  end

  soap_action "DeleteMultipleSolitaires",
    :args => {
      :AuthCode => AuthCode,
      :Collection => ArrayOfSolitaireCertEntity
    },
    :return => :string,
    :to     => :bulk_delete

  def bulk_delete
    auth_params = params[:AuthCode]
    collection = params[:Collection]
    raise "Collection can't be nil. Please provide a list of objects with 'CertifiedBy' and 'CertifiedID'" if collection.blank?
    Rails.logger.warn "RECEIVE: DeleteMultipleSolitaires has been called @#{DateTime.now} to delete #{collection["SolitaireCertEntity"].length} solitaires"
    user = User.authenticate(auth_params)
    render :soap => "Invalid Username and password" and return unless user
    # response = user.delete_solitaires(collection)
    Resque.enqueue(OdinDeleteBulk, user.id, collection)
    toDeleteEntities = collection[:SolitaireCertEntity]
    # Resque.enqueue(LDDeleteMultipleSolitaires, user.id, toDeleteEntities)
    Rails.logger.warn "INTERNAL: Successfully processed DeleteMultipleSolitaires and background processing is queued @ #{DateTime.now}"
    # Rails.logger.debug "Successfully processed delete_solitaires and background processing is queued"
    render :soap => "Delete Solitaires is being processed. You will be notified by email, in case of any problems/ errors." and return
  rescue => e
    raise SOAPError, "Error occured : #{e}"
  end

  soap_action "BulkUpdateSolitairePrices",
    :args => {
      :AuthCode => AuthCode,
      :Collection => ArrayOfSolitairePriceEntity,
      :InputCurrency => :string
    },
    :return => :string,
    :to     => :udpate_item_price

  def udpate_item_price
    auth_params = params[:AuthCode]
    collection = params[:Collection]
    number_of_diamonds = collection.length
    input_currency = params[:InputCurrency]
    raise "Collection can't be nil. Please provide a list of objects with 'CertifiedBy', 'CertifiedID' & 'UpdatedPrice'" if collection.blank?
    Rails.logger.warn "RECEIVE: BulkUpdateSolitairePrices has been called @#{DateTime.now} to update prices of #{collection["SolitairePriceEntity"].length} items"
    user = User.authenticate(auth_params)
    render :soap => "Invalid Username and password" and return unless user
    response = user.update_prices(collection, input_currency)
    Rails.logger.warn "INTERNAL: Successfully processed BulkUpdateSolitairePrices and background processing is queued @ #{DateTime.now}"
    # Rails.logger.debug "Successfully processed update_item_prices and background processing is queued"
    render :soap => "#{number_of_diamonds} diamonds processing added successfully. You will be notified by email, in case of any problems/ errors." and return
  rescue => e
    raise SOAPError, "Error occured : #{e}"
  end

  soap_action "DeleteSolitaire",
    :args => {
      :AuthCode => AuthCode,
      :CertifiedBy => :string,
      :CertifiedId => :string
    },
    :return => :string,
    :to     => :delete_item

  def delete_item
    auth_params = params[:AuthCode]
    certificate_id = params[:CertifiedId]
    certified_by = params[:CertifiedBy]
    Rails.logger.warn "RECEIVE: DeleteSolitaire has been called @#{DateTime.now} for solitaire with id #{certificate_id} by #{certified_by}"
    user = User.authenticate(auth_params)
    render :soap => "Invalid Username and password" and return unless user
    # response = user.delete_item(certificate_id, certified_by)
    Resque.enqueue(OdinDeleteSolitaire, user.id, certificate_id, certified_by)
    # Resque.enqueue(LDDeleteSolitaire, user.id, certificate_id, certified_by)
    # Rails.logger.debug "Successfully processed delete_item and background processing is queued"
    Rails.logger.warn "INTERNAL: Successfully processed DeleteSolitaire and background processing is queued @ #{DateTime.now}"
    render :soap => "Diamond with certificate ID: #{certificate_id} by #{certified_by} will be deleted. You will be notified by email, in case of any problems/ errors." and return
  rescue => e
    raise SOAPError, "Error occured : #{e}"
  end

  soap_action "DeleteAllSolitaires",
    :args => {
      :AuthCode => AuthCode
    },
    :return => :string,
    :to     => :delete_all_items

  def delete_all_items
    auth_params = params[:AuthCode]
    Rails.logger.warn "RECEIVE: DeleteAllSolitaires has been called @#{DateTime.now}"
    user = User.authenticate(auth_params)
    render :soap => "Invalid Username and password" and return unless user
    Resque.enqueue(OdinDeleteAll, user.id)
    # Resque.enqueue(LDDeleteAll, user.id)
    # response = user.delete_all_items()
    # Rails.logger.debug "Successfully processed delete_all_items and background processing is queued"
    Rails.logger.warn "INTERNAL: Successfully processed DeleteAllSolitaires and background processing is queued @ #{DateTime.now}"
    render :soap => "All your diamonds will be deleted. You will be notified by email, in case of any problems/ errors." and return
  rescue => e
    raise SOAPError, "Error occured : #{e}"
  end

  soap_action "BulkImportSolitaires",
    :args => {
      :AuthCode => AuthCode,
      :Collection => ArrayOfSolitaireAPIEntity,
      :InputCurrency => :string,
      :BAssignCutGrade => :boolean
    },
    :return => :string,
    :to     => :bulk_import_solitaires

  def bulk_import_solitaires
    collection = params[:Collection]
    auth_params = params[:AuthCode]
    input_currency = params[:InputCurrency]
    b_assign_cut_grade = params[:BAssignCutGrade]
    raise "Collection can't be nil. Please provide a list of objects" if collection.blank?
    Rails.logger.warn "RECEIVE: BulkImportSolitaires has been called @#{DateTime.now} to import #{collection["SolitaireAPIEntity"].length} solitaires"
    # Authenticate using auth_params, and process only if valid else return
    user = User.authenticate(auth_params)
    render :soap => "Invalid Username and password" and return unless user
    response = user.bulk_import_items(collection, input_currency, b_assign_cut_grade)
    Rails.logger.warn "INTERNAL: Successfully processed BulkImportSolitaires and background processing is queued @ #{DateTime.now}"
    # Rails.logger.debug "Successfully processed bulk_import_solitaires and background processing is queued"
    render :soap => "Diamonds processing added successfully. You will be notified by email, in case of any problems/ errors." and return
  rescue => e
    raise SOAPError, "Error occured : #{e}"
  end

  soap_action "BulkImportSolitairesCompleted",
    :args => {
      :AuthCode => AuthCode,
    },
    :return => :string,
    :to     => :bulk_import_solitaires_completed

  def bulk_import_solitaires_completed
    auth_params = params[:AuthCode]
    Rails.logger.warn "RECEIVE: BulkImportSolitairesCompleted has been called @#{DateTime.now}"
    user = User.authenticate(auth_params)
    render :soap => "Invalid Username and password" and return unless user
    user.bulk_import_completed()
    Rails.logger.warn "INTERNAL: Successfully processed BulkImportSolitairesCompleted and background processing is queued @ #{DateTime.now}"
    render :soap => "Thank you for uploading inventory. You will be notified by email, in case of any problems/ errors." and return
  rescue => e
    raise SOAPError, "Error occured : #{e}"
  end

  soap_action "AddSolitaire",
    :args =>  {
      :AuthCode => AuthCode,
      :Entity => {
        :StockRefId => :string,
        :ProductRefId => :integer,
        :SalesmanId => :integer,
        :Description => :string,
        :Shape => :string,
        :Carat => :double,
        :Color => :string,
        :Clarity => :string,
        :Cut => :string,
        :Polish => :string,
        :Symmetry => :string,
        :Flourescence => :string,
        :Shade => :string,
        :CertifiedBy => :string,
        :CertifiedID => :string,
        :MeaWidth => :double,
        :MeaLength => :double,
        :MeaDepth => :double,
        :Depth => :double,
        :TableSpec => :double,
        :CrownHeight => :double,
        :PavilionDepth => :double,
        :Culet => :string,
        :Graining => :string,
        :GirdleFrom => :string,
        :GirdleTo => :string,
        :StoneType => :string,
        :Inclusion => :string,
        :Country => :string,
        :Discount => :double,
        :Price => :double,
        :PricePerCarat => :double,
        :Comments => :string,
        :ReportComments => :string,
        :Supplier => :string,
        :Treatment => :string,
        :LaserInscription => :boolean,
        :KeyToSymbol => :string,
        :GirdlePercentage => :double,
        :PavilionAngle => :double,
        :CrownAngle => :double,
        :ImageName1 => :string,
        :ImageName2 => :string,
        :ImageName3 => :string,
        :SecondaryPrice => :double,
        :IsSpecial => :boolean,
        :IsCalRapPrice => :boolean,
        :Col_0 => :string,
        :Col_1 => :string,
        :Col_2 => :string,
        :Col_3 => :string,
        :Col_4 => :string,
        :Col_5 => :string,
        :Col_6 => :string,
        :Col_7 => :string,
        :Col_8 => :string,
        :Col_9 => :string,
        :Col_10 => :string,
        :Col_11 => :string,
        :Col_12 => :string,
        :Col_13 => :string,
        :Col_14 => :string
      },
      :InputCurrency => :string,
      :bAssignCutGrade => :boolean
    },
    :return => :string,
    :to     => :add_item

  def add_item
    item_properties = params[:Entity]
    auth_params = params[:AuthCode]
    input_currency = params[:InputCurrency]
    b_assign_cut_grade = params[:bAssignCutGrade]
    Rails.logger.warn "RECEIVE: AddSolitaire has been called @#{DateTime.now}"
    # Authenticate using auth_params, and process only if valid else return
    user = User.authenticate(auth_params)
    render :soap => "Invalid Username and password" and return unless user
    Resque.enqueue(OdinAddSolitaire, user.id, item_properties, input_currency, b_assign_cut_grade)
    # Resque.enqueue(LDAddSolitaire, user.id, item_properties, input_currency, b_assign_cut_grade)
    Rails.logger.debug "Successfully processed add_item and background processing is queued"
    Rails.logger.warn "INTERNAL: Successfully processed AddSolitaire and background processing is queued @ #{DateTime.now}"
    render :soap => "Diamond Added/ Updated successfully. Response from ODIN is #{response}" and return
  rescue => e
    raise SOAPError, "Error occured : #{e}"
  end

  private
  def dump_parameters
    Rails.logger.debug params.inspect
  end

end
