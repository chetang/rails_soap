class ApiKey < ActiveRecord::Base
  belongs_to :user
  scope :unexpired, -> { where("expired_at >= ?", Time.now) }
  scope :active, -> {where(is_active: true)}

  def self.mark_as_inactive(user)
    active_apikeys = ApiKey.where(user_id: user.id).where(is_active: true)
    active_apikeys.each do |apk|
      apk.is_active = false
      apk.save!
    end
  rescue => e
    Rails.logger.error "Error occured while marking User ApiKeys as inactive. Error is #{e}"
  end
end
