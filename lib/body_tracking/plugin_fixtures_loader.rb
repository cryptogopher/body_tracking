module BodyTracking::PluginFixturesLoader
  def self.included(base)
    base.class_eval do
      def self.plugin_fixtures(*symbols)
        plugin_fixtures_path = Rails.root.join('plugins', 'body_tracking', 'test', 'fixtures')
        ActiveRecord::FixtureSet.create_fixtures(plugin_fixtures_path, symbols)
        # ActiveRecord::TestFixtures#fixtures creates model_name(:fixture_name) accessors
        fixtures *symbols
      end
    end
  end

  #private

  ## Load fixtures giving preference for plugin defined ones
  #def load_fixtures(*args)
  #  # call create_fixtures directly instead of load_fixtures
  #  # or
  #  # create_fixtures in plugin_fixtures (include method in
  #  # ActiveRecord::TestFixtures) + load by calling #fixtures (like in issue_recurring)
  #  byebug
  #  redmine_fixture_path = self.fixture_path
  #  plugin_fixture_path = Rails.root.join('plugins', 'body_tracking', 'test', 'fixtures')
  #  all_ft_names = fixture_table_names

  #  plugin_ft_names, redmine_ft_names = fixture_table_names.partition do |ft_name|
  #    File.exists?(plugin_fixture_path.join("#{ft_name.to_s}.yml"))
  #  end

  #  self.fixture_table_names = redmine_ft_names
  #  fixtures = super
  #  ActiveSupport::TestCase.fixture_path = plugin_fixture_path 
  #  self.fixture_table_names = plugin_ft_names
  #  fixtures.merge(super)

  #  ActiveSupport::TestCase.fixture_path = redmine_fixture_path
  #  self.fixture_table_names = all_ft_names
  #  fixtures
  #end
end
