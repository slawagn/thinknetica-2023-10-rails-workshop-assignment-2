class PrepareDelivery
  class ValidationError < StandardError
  end

  TRUCK_MAX_WEIGHTS = { kamaz: 3000, gazel: 1000 }.freeze

  def initialize(order, destination_address, delivery_date)
    @order = order
    @destination_address = destination_address
    @delivery_date = delivery_date
  end

  def perform
    validate_delivery_date!
    validate_delivery_address!

    delivery_weight = calculate_delivery_weight
    truck = find_truck_for_delivery(weight: delivery_weight)

    {
      status: :ok,
      truck: truck,
      weight: delivery_weight,
      order_number: @order.id,
      address: @destination_address
    }
  rescue StandardError
    { status: :error }
  end

  private

  def validate_delivery_date!
    return if @delivery_date > Time.current

    raise ValidationError, 'Дата доставки уже прошла'
  end

  def validate_delivery_address!
    raise ValidationError, 'Не указан город' if @destination_address.city.empty?
    raise ValidationError, 'Не указана улица' if @destination_address.street.empty?
    raise ValidationError, 'Не указан дом' if @destination_address.house.empty?

    raise ValidationError, 'Нет адреса'
  end

  def calculate_delivery_weight
    @order.products.sum(&:weight)
  end

  def find_truck_for_delivery(weight:)
    truck = TRUCK_MAX_WEIGHTS.keys.find { |truck| TRUCK_MAX_WEIGHTS[truck] > weight }

    raise ValidationError, 'Нет машины' unless TRUCK_MAX_WEIGHTS.keys.include?(truck)
  end
end

class Order
  def id
    'id'
  end

  def products
    [OpenStruct.new(weight: 20), OpenStruct.new(weight: 40)]
  end
end

class Address
  def city
    'Ростов-на-Дону'
  end

  def street
    'ул. Маршала Конюхова'
  end

  def house
    'д. 5'
  end
end

PrepareDelivery.new(Order.new, Address.new, Date.tomorrow).perform
