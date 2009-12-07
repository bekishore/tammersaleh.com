class Recommendation < ActiveRecord::Base
  attr_accessible :quote, :who, :who_url, :where, :where_url, :position, :company, :company_url
  validates_presence_of :quote, :who, :where, :where_url
  validates_format_of :where_url,   :with => URL_REGEX, :allow_blank => true
  validates_format_of :company_url, :with => URL_REGEX, :allow_blank => true
  validates_format_of :who_url,     :with => URL_REGEX, :allow_blank => true

  def to_s
    "recommendation from #{who}"
  end
end
