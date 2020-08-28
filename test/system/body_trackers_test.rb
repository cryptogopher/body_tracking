require File.expand_path('../../application_system_test_case', __FILE__)
require 'rake'

class BodyTrackersTest < BodyTrackingSystemTestCase
  def setup
    super
    @project1 = projects(:projects_001)
    log_user 'jsmith', 'jsmith'
  end

  def test_defaults_seed_and_load_into_empty_project
    Rails.application.load_tasks
    Rake::Task['redmine:body_tracking:seed'].invoke
    counts = [Source, Quantity, Formula, Unit].map do |model|
      assoc = model.to_s.downcase.pluralize
      @project1.send(assoc).delete_all unless assoc == 'formulas'
      ["@project1.#{assoc}.reload.count", model.defaults.count]
    end.to_h

    visit project_body_trackers_path(@project1)
    assert_difference counts do
      accept_alert t('layouts.sidebar.confirm_defaults') do
        click_link t('layouts.sidebar.link_defaults')
      end
      # click_link is asynchronuous, need to wait for page reload before
      # checking differences and wait a little longer than normally
      assert_selector 'div#flash_notice', wait: 10
      assert_no_selector 'div#flash_error'
    end
  end
end
