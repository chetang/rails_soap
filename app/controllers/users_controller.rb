class UsersController < ApplicationController
  soap_service namespace: 'urn:WashOut'
  before_filter :dump_parameters

  before_action :authenticate_user!

  def index
    @users = User.all
  end

  def show
    @user = User.find(params[:id])
    unless @user == current_user
      redirect_to :back, :alert => "Access denied."
    end
  end

  def add_item
    response = User.add_odin_item({})
    redirect_to :back, :notice => "Response is #{response.inspect}"
  end

  # Complex structures
  soap_action "AddCircle",
              :args   => { :circle => { :center => { :x => :integer,
                                                     :y => :integer },
                                        :radius => :double } },
              :return => nil, # [] for wash_out below 0.3.0
              :to     => :add_circle
  def add_circle
    circle = params[:circle]
    response = User.add_odin_item({})

    raise SOAPError, "radius is too small" if circle[:radius] < 3.0

    Circle.new(circle[:center][:x], circle[:center][:y], circle[:radius])

    render :soap => nil
  end

  soap_action "concat",
              :args   => { :a => :string, :b => :string },
              :return => :string
  def concat
    response = User.add_odin_item({})
    render :soap => (params[:a] + params[:b])
  end


  private
  def dump_parameters
    Rails.logger.debug params.inspect
  end

end
