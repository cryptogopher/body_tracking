(Rails::VERSION::MAJOR < 5 ? ActionDispatch : ActiveSupport)::Reloader.to_prepare do
  Project.include BodyTracking::ProjectPatch
end

Redmine::Plugin.register :body_tracking do
  name 'Body tracking plugin'
  author 'cryptogopher'
  description 'Keep track of body related data to achieve your goals'
  version '0.1'
  url 'https://github.com/cryptogopher/body_tracking'
  author_url 'https://github.com/cryptogopher'

  project_module :body_tracking do
    permission :view_body_trackers, {
      :body_trackers => [:index],
      :units => [:index],
      :quantities => [:index]
    }, read: true
    permission :manage_common, {
      :body_trackers => [:defaults],
      :units => [:create, :destroy],
      :quantities => [:create, :destroy]
    }, require: :loggedin
  end

  menu :project_menu, :body_trackers, {:controller => 'body_trackers', :action => 'index'},
    :caption => :body_trackers_menu_caption, :before => :settings, :param => :project_id
end
