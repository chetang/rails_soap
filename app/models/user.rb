class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  def self.add_odin_item(item = {})
    user = User.find(3)
    # user = current_user
    auth = {
      "UserName" => user.odin_username,
      "Password" => user.odin_password
    }
    # auth = {
    #   :user_name => user.odin_username,
    #   :password => user.odin_password
    # }
    item_attributes = {
      "Carat" => 1.1,
      "Color" => "D",
      "Shape" => "Round",
      "Clarity" => "VS1",
      "Cut" => "EX",
      "Polish" => "EX",
      "Symmetry" => "EX",
      "Flourescence" => "None",
      "GirdleFrom" => "Thick",
      "GirdleTo" => "Thick",
      "Inclusion" => "Yellow",
      "IsCalRapPrice" => false,
      "Price" => 7500.00,
      "PricePerCarat" => 7500.00,
      "CertificateID" => "23847213921",
      "CertifiedBy" => "GIA"
    }
    # item_attributes = {
    #   :carat => 1.1,
    #   :color => "D",
    #   :shape => "Round",
    #   :clarity => "VS1",
    #   :cut => "EX",
    #   :polish => "EX",
    #   :symmetry => "EX",
    #   :flourescence => "None",
    #   :girdle_from => "Thick",
    #   :girdle_to => "Thick",
    #   :inclusion => "Yellow",
    #   :is_cal_rap_price => false,
    #   :price => 7500.00,
    #   :price_per_carat => 7500.00,
    #   :certified_iD => "238472391",
    #   :certified_by => "GIA"
    # }
    #
    # add_solitaire_message = {:auth_code => auth, :entity => item_attributes, :input_currency => "USD", :assign_cut_grade => false}
    add_solitaire_message = {"AuthCode" => auth, "Entity" => item_attributes, "InputCurrency" => "USD", "AssignCutGrade" => false}
    response = ODIN_CLIENT.call(:add_solitaire) do
      message add_solitaire_message
    end
    # response = ODIN_CLIENT.call(:add_solitaire) do
    #   convert_request_keys_to :camelcase
    #   message add_solitaire_message
    # end
    return response
  end
end
