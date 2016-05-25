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

  soap_action "UpdateSolitairePrice",
    :args => {
      :AuthCode => AuthCode,
      :Collection => ArrayOfPriceUpdatedEntity,
      :InputCurrency => :string
    },
    :return => :string,
    :to     => :udpate_item_price

  def udpate_item_price
    auth_params = params[:AuthCode]
    collection = params[:Collection]
    input_currency = params[:InputCurrency]
    user = User.authenticate(auth_params)
    render :soap => "Invalid Username and password" and return unless user
    response = user.update_prices(collection, input_currency)
    Rails.logger.debug "Successfully processed update_item_prices and background processing is queued"
    render :soap => "Diamonds processing added successfully. You will be notified by email, in case of any problems/ errors." and return
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
    user = User.authenticate(auth_params)
    render :soap => "Invalid Username and password" and return unless user
    # response = user.delete_item(certificate_id, certified_by)
    Resque.enqueue(OdinDeleteSolitaire, user.id, certificate_id, certified_by)
    Rails.logger.debug "Successfully processed delete_item and background processing is queued"
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
    user = User.authenticate(auth_params)
    render :soap => "Invalid Username and password" and return unless user
    Resque.enqueue(OdinDeleteAll, user.id)
    # response = user.delete_all_items()
    Rails.logger.debug "Successfully processed delete_all_items and background processing is queued"
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
    # Authenticate using auth_params, and process only if valid else return
    user = User.authenticate(auth_params)
    render :soap => "Invalid Username and password" and return unless user
    response = user.bulk_import_items(collection, input_currency, b_assign_cut_grade)
    Rails.logger.debug "Successfully processed bulk_import_solitaires and background processing is queued"
    render :soap => "Diamonds processing added successfully. You will be notified by email, in case of any problems/ errors." and return
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
    # Authenticate using auth_params, and process only if valid else return
    user = User.authenticate(auth_params)
    render :soap => "Invalid Username and password" and return unless user
    Resque.enqueue(OdinAddSolitaire, user.id, item_properties, input_currency, b_assign_cut_grade)
    Rails.logger.debug "Successfully processed add_item and background processing is queued"
    render :soap => "Diamond Added/ Updated successfully. Response from ODIN is #{response}" and return
  rescue => e
    raise SOAPError, "Error occured : #{e}"
  end

  private
  def dump_parameters
    Rails.logger.debug params.inspect
  end

end
