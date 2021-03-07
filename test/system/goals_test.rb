require File.expand_path('../../application_system_test_case', __FILE__)

class GoalsTest < BodyTrackingSystemTestCase
  def setup
    super
    @project1 = projects(:projects_001)
    log_user 'jsmith', 'jsmith'
  end

  def test_index
    assert_not_equal 0, @project1.goals.count
    visit project_goals_path(@project1)
    assert_selector 'table#goals tbody tr', count: @project1.goals.count
  end
end
