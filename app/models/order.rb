class Order < ActiveRecord::Base

  belongs_to :user

  belongs_to :billing, class_name:  "Address"

  belongs_to :shipping, class_name:  "Address"

  has_many :order_contents
  has_many :products, through: :order_contents
  has_many :categories, through: :products

  validates_with OrderValidator

  def value
    self.order_contents.reduce(0){|sum, oc| sum += oc.quantity * oc.product.price}
  end

  def status
    self.checkout_date.nil? ?  "UNPLACED" : "PLACED"
  end


  def self.time_series_day(days=7)
    self.select("date_trunc('day', orders.checkout_date) AS day, count(DISTINCT orders.id), SUM(order_contents.quantity * products.price)").
    joins('JOIN order_contents ON orders.id = order_contents.order_id').
    joins('JOIN products ON products.id = order_contents.product_id').
    where('orders.checkout_date >= ? AND orders.checkout_date < ?',
      DateTime.now - 7,DateTime.now).
    group('day').
    order('day DESC')
  end

  def created_or_checkout_date
    self.checkout_date.nil? ? self.created_at : self.checkout_date
  end

  def self.time_series_week(weeks=7)

    self.select("date_trunc('week', orders.checkout_date) AS week, count(DISTINCT orders.id), SUM(order_contents.quantity * products.price)").
    joins('JOIN order_contents ON orders.id = order_contents.order_id').
    joins('JOIN products ON products.id = order_contents.product_id').
    where('orders.checkout_date >= ? AND orders.checkout_date < ?',
      DateTime.now - (7 * weeks), DateTime.now).
    group('week').
    order('week DESC')
  end

  def self.get_statistics
    overall = {'Last 7 Days' => 7, 'Last 30 Days' => 30, 'Total' => nil}
    overall.each do |key, limit|
      result = []
      result << ["Number of Orders", self.in_last(limit)]
      result << ["Total Revenue", self.revenue_in_last(limit)]
      result << ["Average Order Value", self.average_in_last(limit)]
      result << ["Largest Order Value", self.largest_in_last(limit)]
      overall[key] = result
    end
    overall
  end

  def self.in_last(days=nil)
    if days.nil?
      self.count
    else
      self.where('checkout_date > ?', DateTime.now - days).count
    end
  end

  def self.revenue_in_last(days=nil)
    if days.nil?
      revenue.where('orders.checkout_date IS NOT NULL').first.cost
    else
      revenue.where('orders.checkout_date > ?', DateTime.now - days).first.cost
    end
  end

  def self.average_in_last(days = nil)
    if days
      self.select('(SUM(products.price * order_contents.quantity)/COUNT(DISTINCT orders.id)) as average_order').
      joins(:products).
      where('orders.checkout_date > ?', DateTime.now - days).
      order('1').
      first.average_order
    else
      self.select('(SUM(products.price * order_contents.quantity)/COUNT(DISTINCT orders.id)) as average_order').
      joins(:products).
      where('orders.checkout_date IS NOT NULL').
      order('1').
      first.average_order
    end
  end

  def self.largest_in_last(days = nil)
    if days
      self.get_largest_overall.
      where('orders.checkout_date > ?', DateTime.now - days).
      group('orders.id').order('max_order DESC').first.max_order
    else
      self.get_largest_overall.
      where('orders.checkout_date IS NOT NULL').
      group('orders.id').order('max_order DESC').first.max_order
    end
  end

  def self.revenue_in_last(days)
    self.revenue(days).first.cost
  end

  def has_cart?
    Order.where("user_id = ? AND checkout_date IS NULL", self.user_id).present?
  end

  private

    def self.checked_out
      self.where('orders.checkout_date IS NOT NULL')
    end

    def self.get_largest_overall
      self.select('SUM(products.price * order_contents.quantity) as max_order').joins(:products)
    end

    def self.revenue(days=nil)
      if days
        self.select('SUM(products.price * order_contents.quantity) as cost').
        joins(:products).
        where('orders.checkout_date > ?', DateTime.now - days).
        order('cost')
      else
      self.select('SUM(products.price * order_contents.quantity) as cost').
      joins(:products).
      order('cost')
      end
    end
end





