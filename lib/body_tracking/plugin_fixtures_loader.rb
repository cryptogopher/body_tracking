module BodyTracking::PluginFixturesLoader
  def self.included(base)
    base.class_eval do
      def self.plugin_fixtures(*symbols)
        fixtures_dir = File.expand_path('../../test/fixtures/', __FILE__)
        ActiveRecord::Fixtures.create_fixtures(fixtures_dir, symbols)
      end
    end
  end
end
