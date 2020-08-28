
require Rails.root.join('config', 'environment')

namespace :redmine do
  namespace :body_tracking do
    desc "Loads body_tracking plugin seed data from db/seeds.rb. Requires pending" \
      " migrations to be applied before running. Purges and reloads all seed data."
    task seed: [:environment, 'db:abort_if_pending_migrations'] do
      seed_fn = Rails.root.join('plugins', 'body_tracking', 'db', 'seeds.rb')
      if seed_fn.exist?
        print "Loading seed data from #{seed_fn}..."
        load(seed_fn)
        puts "done"
      else
        puts "Seed data file #{seed_fn} is missing :/"
      end
    end
  end
end

