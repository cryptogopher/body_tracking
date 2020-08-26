require File.expand_path('../../application_system_test_case', __FILE__)

class BodyTrackersTest < BodyTrackingSystemTestCase
  def setup
    super
    @project1 = projects(:projects_001)
    log_user 'jsmith', 'jsmith'
  end

  def test_defaults_load
    visit project_body_trackers_path(@project1)
    accept_alert t('layouts.sidebar.confirm_defaults') do
      click_link t('layouts.sidebar.link_defaults')
    end
    assert_selector 'div#flash_notice'
    assert_no_selector 'div#flash_error'
  end
end
