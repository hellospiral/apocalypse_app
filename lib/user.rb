class User < ActiveRecord::Base
  has_many :amounts
  has_many :resources, through: :amounts
  before_create(:set_money)

  define_method(:compile_resources) do
    self.update({food_count: 0, water_count: 0, medicine_count: 0, protection_count: 0, event_flag: true})
    self.resources.each() do |resource|
      amount = Amount.find_by(user_id: self.id, resource_id: resource.id)
      if resource.item_type == 'Food'
        self.update({food_count: (resource.value * amount.quantity + self.food_count.to_i)})
      elsif resource.item_type == 'Medicine'
        self.update({medicine_count: (resource.value * amount.quantity + self.medicine_count.to_i)})
      elsif resource.item_type == 'Protection'
        self.update({protection_count: (resource.value * amount.quantity + self.protection_count.to_i)})
      elsif resource.item_type == 'Water'
        self.update({water_count: (resource.value * amount.quantity + self.water_count.to_i)})
      end
    end
  end

  define_method(:bottleneck_resource) do
    self.compile_resources()
    lowest_items = []
    check_number = (self.food_count.to_i + self.water_count.to_i + self.protection_count.to_i + self.medicine_count.to_i) / 5
    if self.food_count.to_i  < check_number
      lowest_items.push("Food")
    end
    if self.water_count.to_i < check_number
      lowest_items.push("Water")
    end
    if self.medicine_count.to_i < check_number
      lowest_items.push("Medicine")
    end
    if self.protection_count.to_i < check_number
      lowest_items.push("Protection")
    elsif check_number == 0
      lowest_items.push('everything')
    end
    return lowest_items
  end

private
  define_method(:set_money) do
    self.money = rand(1000.00..2000.00).round(2)
  end
end
