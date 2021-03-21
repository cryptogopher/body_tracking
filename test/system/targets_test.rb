require File.expand_path('../../application_system_test_case', __FILE__)

class TargetsTest < BodyTrackingSystemTestCase
  def setup
    super
    @project = projects(:projects_001)
    log_user 'jsmith', 'jsmith'
  end

  # TODO: add binding_and_nonbinding method to run same test for 2 target types
  # TODO: set values taken randomly from fixtures, not hardcoded

  def test_index_binding_goal
    goal = @project.goals.binding
    assert_not_equal 0, goal.targets.count
    visit goal_targets_path(goal)
    assert_selector 'table#targets tbody tr', count: goal.targets.count
  end

  def test_index_binding_goal_without_targets
    goal = @project.goals.binding
    goal.targets.delete_all
    assert_equal 0, goal.targets.count
    visit goal_targets_path(goal)
    assert_current_path goal_targets_path(goal)
    assert_selector 'div#targets', visible: :yes, exact_text: t(:label_no_data)
  end

  def test_index_options_add_exposure
    # Select random unexposed quantity
    quantity = @project.quantities.except_targets
      .joins("LEFT OUTER JOIN exposures ON exposures.quantity_id = quantities.id \
                AND exposures.view_type = 'Goal' \
                AND exposures.view_id = #{Project.first.goals.binding.id}")
      .where(exposures: {view: nil}).sample
    assert quantity

    visit goal_targets_path(@project.goals.binding)
    assert_no_selector 'table#targets thead th', text: quantity.name
    within 'fieldset#options' do
      select quantity.name
      click_on t(:button_add)
    end
    assert_selector 'table#targets thead th', text: quantity.name
  end

  def test_index_table_header_close_exposure
    quantity = @project.goals.binding.exposures.sample.quantity

    visit goal_targets_path(@project.goals.binding)
    within 'table#targets thead th', text: quantity.name do
      click_link class: 'icon-close'
    end
    assert_no_selector 'table#targets thead th', text: quantity.name
    assert_selector 'table#targets thead th'
  end

  def test_new_binding_target
    visit goal_targets_path(@project.goals.binding)
    assert_no_selector 'form#new-target-form'
    click_link t('targets.contextual.link_new_target')
    assert_selector 'form#new-target-form', count: 1
    within 'form#new-target-form' do
      assert has_field?(t(:field_effective_from), with: Date.current, count: 1)
      assert has_no_link?(t('targets.form.button_delete_target'))
    end
    assert has_link?(t('targets.form.button_new_target'), count: 1)
  end

  def test_new_cancel
    visit goal_targets_path(@project.goals.binding)
    click_link t('targets.contextual.link_new_target')
    assert_selector 'form#new-target-form', count: 1
    click_on t(:button_cancel)
    assert_no_selector 'form#new-target-form'
  end

  def test_create_binding_target
    quantity = @project.quantities.except_targets.sample
    target = @project.quantities.target.roots.sample
    target_value = rand(-2000.0..2000.0).to_d(4)
    target_unit = @project.units.sample

    assert_difference 'Goal.count' => 0, 'Target.count' => 1,
                      '@project.targets.reload.count' => 1, 'Threshold.count' => 1 do
      visit goal_targets_path(@project.goals.binding)
      click_link t('targets.contextual.link_new_target')
      within 'form#new-target-form' do
        within 'p.target' do
          select quantity.name
          select target.name
          fill_in with: target_value
          select target_unit.shortname
        end
        click_on t(:button_create)
      end
    end

    t = Target.last
    assert_equal @project.goals.binding, t.goal
    assert_equal Date.current, t.effective_from
    assert_equal quantity, t.quantity
    assert_equal target, t.thresholds.first.quantity
    assert_equal target_value, t.thresholds.first.value
    assert_equal target_unit, t.thresholds.first.unit

    assert_no_selector 'form#new-target-form'
    assert_selector 'table#targets tbody tr', count: @project.targets.count
  end

  def test_create_binding_target_when_binding_goal_does_not_exist
    @project.goals.where(is_binding: true).delete_all
    assert_equal 0, @project.goals.count(&:is_binding?)
    assert_difference ['Goal.count', '@project.goals.reload.count(&:is_binding?)',
                       '@project.targets.reload.count'], 1 do
      visit goal_targets_path(@project.goals.binding)
      click_link t('targets.contextual.link_new_target')
      within 'form#new-target-form' do
        within 'p.target' do
          select quantities(:quantities_energy).name
          select quantities(:quantities_target_equal).name
          fill_in with: '1750'
          select units(:units_kcal).shortname
        end
        click_on t(:button_create)
      end
    end
    assert_equal @project.goals.binding, Target.last.goal
  end

  def test_create_with_multiple_thresholds
    # TODO
  end

  def test_create_multiple_targets
  end

  # TODO: test_create_failure(s)
  # * restoring non-empty targets values
  # * removing empty targets

  def test_edit_binding_target
    t = Target.offset(rand(Target.count)).take
    visit project_targets_path(@project)
    assert_no_selector 'form#edit-target-form'

    within find('td', text: t.effective_from).ancestor('tr') do
      click_link t(:button_edit)

      within find(:xpath, 'following-sibling::*//form[@id="edit-target-form"]') do
        assert has_select?(t(:field_goal), selected: t.goal.name)
        assert has_field?(t(:field_effective_from), with: t.effective_from)

        threshold = t.thresholds.first
        within find('select option[selected]', exact_text: threshold.quantity.name)
                 .ancestor('p') do
          assert has_select?(selected: t.condition)
          assert has_field?(with: threshold.value)
          assert has_select?(selected: threshold.unit.shortname)
        end
      end
    end

    assert_selector 'form#edit-target-form', count: 1
  end

  def test_update
    t = Target.offset(rand(Target.count)).take
    date = t.effective_from - 1.week
    quantity = (quantities - [t.thresholds.first.quantity]).first
    condition = (Target::CONDITIONS - [t.condition]).first
    value = 3*t.thresholds.first.value
    unit = (units - [t.thresholds.first.unit]).first
    visit project_targets_path(@project)

    find('td', text: t.effective_from).ancestor('tr').click_link t(:button_edit)
    assert_no_difference ['Goal.count', 'Target.count', 'Threshold.count'] do
      within 'form#edit-target-form' do
        # Assume binding Goal and don't change
        fill_in t(:field_effective_from), with: date
        within 'p.target:nth-child(1)' do
          select quantity.name
          select condition
          fill_in with: value
          select unit.shortname
        end
        click_on t(:button_save)
      end
    end

    t.reload
    assert_equal date, t.effective_from
    assert_equal quantity, t.thresholds.first.quantity
    assert_equal condition, t.condition
    assert_equal value, t.thresholds.first.value
    assert_equal unit, t.thresholds.first.unit
  end
end
