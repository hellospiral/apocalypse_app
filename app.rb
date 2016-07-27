require("bundler/setup")
Bundler.require(:default)
Dir[File.dirname(__FILE__) + '/lib/*.rb'].each { |file| require file}

get('/') do
  @users = User.all()
erb(:index)
end

patch('/users/:user_id/resources/:resource_id/increment') do
  user = User.find(params['user_id'].to_i)
  resource = Resource.find(params['resource_id'].to_i)
  if amount = Amount.find_by(user_id: user.id, resource_id: resource.id)
    if user.money >= resource.cost
      amount.update({:quantity => (amount.quantity + 1)})
      user.update({:money => (user.money - resource.cost)})
    else
      @money_message = "Money levels too low for purchase, current money:" + user.money.to_s
    end
  else
    if user.money >= resource.cost
      Amount.create({:user_id => user.id, :resource_id => resource.id, :quantity => 1})
    else
      @money_message = "Money levels too low for purchase, current money:" + user.money.to_s
    end
  end
  redirect('/users/' + user.id.to_s)
end

patch('/users/:user_id/resources/:resource_id/decrement') do
  user = User.find(params['user_id'].to_i)
  resource = Resource.find(params['resource_id'].to_i)
  if amount = Amount.find_by(user_id: user.id, resource_id: resource.id)
    if amount.quantity > 1
      amount.update({:quantity => (amount.quantity - 1)})
      user.update({:money => (user.money + resource.cost)})
    else
      amount.destroy
      user.update({:money => (user.money + resource.cost)})
    end
  end
  redirect('/users/' + user.id.to_s)
end

patch('/users/:user_id/resources/:resource_id/remove') do
  user = User.find(params['user_id'].to_i)
  resource = Resource.find(params['resource_id'].to_i)
  amount = Amount.find_by(user_id: user.id, resource_id: resource.id)
  amount.destroy
  user.update({:money => (user.money + resource.cost)})
  redirect('/users/' + user.id.to_s)
end

post('/new_user') do
  User.create({name: params['new_user']})
  if Resource.all.length == 0
    Resource.populate_items()
  end
  redirect to('/')
end

get('/users/:id') do
  @user = User.find(params['id'])
  @purchased_resource_names = []
  @resources = []
  @inventory = @user.resources
  @inventory.each do |resource|
    @purchased_resource_names.push(resource.name)
  end
  Resource.all.each do |resource|
    unless @purchased_resource_names.include?(resource.name)
      @resources.push(resource)
    end
  end
  @resources = @resources.sort_by do |resource|
    resource[:id]
  end
  erb(:user)
end

delete('/users/:id') do
  user = User.find(params['id'])
  user.destroy()
  redirect('/')
end

delete('/users/:user_id/resources/:resource_id') do
  item = Resource.find(params['resource_id'])
  item.destroy()
  redirect('/users/' + params['user_id'])
end

post('/users/:user_id/resources/:resource_id') do
  item = Resource.find(params['resource_id'])
  user = User.find(params['user_id'])
  new_amount = Amount.create({:user_id => user.id, :resource_id => item.id, :quantity => 1})
  user.update({:money => (user.money - item.cost)})
  redirect('/users/' + user.id.to_s)
end
