class PrepareDelivery
  class ValidationError < StandardError
  end

  TRUCK_MAX_WEIGHTS = { kamaz: 3000, gazel: 1000 }.freeze

  def initialize(order, user)
    @order = order
    @user = user
  end

  def perform(destination_address, delivery_date)
    validate_delivery_date!(delivery_date)
    validate_delivery_address!(destination_address)

    delivery_weight = calculate_delivery_weight
    truck = find_truck_for_delivery(weight: delivery_weight)

    validate_truck_presence!(truck)

    {
      status: :ok,
      truck: truck,
      weight: delivery_weight,
      order_number: @order.id,
      address: destination_address
    }
  rescue StandardError
    { status: :error }
  end

  private

  def validate_delivery_date!(delivery_date)
    return if delivery_date > Time.current

    raise ValidationError, 'Дата доставки уже прошла'
  end

  def validate_delivery_address!(delivery_address)
    return if delivery_address.city.present? && delivery_address.street.present? && delivery_address.house.present?

    raise ValidationError, 'Нет адреса'
  end

  def calculate_delivery_weight
    @order.products.map(&:weight).sum
  end

  def find_truck_for_delivery(weight:)
    TRUCK_MAX_WEIGHTS.keys.find { |truck| TRUCK_MAX_WEIGHTS[truck] > weight }
  end

  def validate_truck_presence!(truck)
    return if TRUCK_MAX_WEIGHTS.keys.include?(truck)

    raise ValidationError, 'Нет машины'
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

PrepareDelivery.new(Order.new, OpenStruct.new).perform(Address.new, Date.tomorrow)
