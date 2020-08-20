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
end
