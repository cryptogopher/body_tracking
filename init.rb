(Rails::VERSION::MAJOR < 5 ? ActionDispatch : ActiveSupport)::Reloader.to_prepare do
  Project.include BodyTracking::ProjectPatch
  CollectiveIdea.include BodyTracking::AwesomeNestedSetPatch
  ActiveSupport::TestCase.include BodyTracking::PluginFixturesLoader if Rails.env == 'test'
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
      body_trackers: [:index],
      goals: [:index],
      targets: [:index, :show],
      meals: [:index],
      measurement_routines: [:show],
      measurements: [:index, :filter],
      readouts: [:index],
      foods: [:index, :nutrients, :filter, :autocomplete],
      sources: [:index],
      quantities: [:index, :parents, :filter],
      units: [:index],
    }, read: true
    permission :manage_body_trackers, {
      body_trackers: [:defaults],
      goals: [:new, :create, :edit, :update],
      targets: [:new, :create, :edit, :update, :destroy, :reapply, :toggle_exposure,
                :subthresholds],
      meals: [:new, :create, :edit, :update, :destroy, :edit_notes, :update_notes,
              :toggle_eaten, :toggle_exposure, :adjust],
      measurement_routines: [:edit],
      measurements: [:new, :create, :edit, :update, :destroy, :retake],
      readouts: [:toggle_exposure],
      foods: [:new, :create, :edit, :update, :destroy, :toggle, :toggle_exposure,
                    :import],
      sources: [:create, :destroy],
      quantities: [:new, :create, :edit, :update, :destroy, :move, :new_child,
                   :create_child],
      units: [:create, :destroy],
    }, require: :loggedin
  end

  menu :project_menu, :body_trackers, {controller: 'body_trackers', action: 'index'},
    caption: :body_trackers_menu_caption, before: :settings, param: :project_id
end
