require File.expand_path('../../application_system_test_case', __FILE__)

class TargetsTest < BodyTrackingSystemTestCase
  def setup
    super
    
    @project1 = projects(:projects_001)

    log_user 'alice', 'foo'
  end

  def teardown
    logout_user
    super
  end

  def test_index
    assert_not_equal 0, @project1.targets.count
    visit project_targets_path(@project1)
    assert_current_path project_targets_path(@project1)
    assert_selector 'table#targets tbody tr', count: @project1.targets.count
  end

  def test_index_without_targets
    #assert_equal 0, @project1.targets.count
    #assert_selector 'div#targets', visible: :yes, exact_text: l(:label_no_data)
  end

  def test_create_saves_binding_goal_if_nonexistent
  end
end
