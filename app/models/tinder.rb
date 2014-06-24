require 'pyro'

class Tinder
  def self.login
    api_keys = Sekrets.settings_for(Rails.root.join('sekrets', 'ciphertext'))
    @pyro = TinderPyro::Client.new
    @pyro.sign_in(api_keys['facebook_id'], api_keys['facebook_token'])
    @pyro
  end

  def self.like_and_load(client, location)
    results = client.get_nearby_users["results"]

    if results
      Tinder.load_users_into_db(client, results, location)
      Tinder.like_users(client)
      Tinder.like_and_load(client, location)
    end
  end

  def self.load_users_into_db(client, results, location)
    results.each do |res|
      User.create(
        tinder_id: res['_id'],
        name: res['name'],
        bio: res['bio'],
        gender: res['gender'],
        birth_date: res['birth_date'],
        last_login: res['last_login'],
        location: location
      )
    end
  end

  def self.like_users(client)
    User.unliked.each do |u|
      client.like(u.tinder_id)
      u.update(liked: true)
    end
  end

  def self.cycle_locations(client)
    Location.all.each do |l|
      client.update_location(l.latitude, l.longitude)
      sleep 30
      Tinder.like_and_load(client, l)
    end
  end
end