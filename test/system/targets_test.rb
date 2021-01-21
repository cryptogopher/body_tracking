require File.expand_path('../../application_system_test_case', __FILE__)

class TargetsTest < BodyTrackingSystemTestCase
  def setup
    super
    @project1 = projects(:projects_001)
    log_user 'jsmith', 'jsmith'
  end

  def test_index
    assert_not_equal 0, @project1.targets.count
    visit project_targets_path(@project1)
    assert_selector 'table#targets tbody tr', count: @project1.targets.count
  end

  def test_index_without_targets
    @project1.goals.delete_all
    assert_equal 0, @project1.targets.count
    visit project_targets_path(@project1)
    assert_current_path project_targets_path(@project1)
    assert_selector 'div#targets', visible: :yes, exact_text: t(:label_no_data)
  end

  def test_index_options_add_exposure
    visit project_targets_path(@project1)
    assert_no_selector 'table#targets thead th', text: quantities(:quantities_proteins).name
    within 'fieldset#options' do
      select quantities(:quantities_proteins).name
      click_on t(:button_add)
    end
    assert_selector 'table#targets thead th', text: quantities(:quantities_proteins).name
  end

  def test_index_table_header_close_exposure
    visit project_targets_path(@project1)
    within 'table#targets thead th', text: quantities(:quantities_energy).name do
      click_link class: 'icon-close'
    end
    assert_no_selector 'table#targets thead th', text: quantities(:quantities_energy).name
    assert_selector 'table#targets thead th'
  end

  # TODO: rename to test_new; move checking of default values here
  def test_index_show_and_hide_new_target_form
    visit project_targets_path(@project1)
    assert_no_selector 'form#new-target-form'
    click_link t('targets.contextual.link_new_target')
    assert_selector 'form#new-target-form', count: 1
    click_on t(:button_cancel)
    assert_no_selector 'form#new-target-form'
  end

  def test_create_binding_target
    assert_difference 'Goal.count' => 0, 'Target.count' => 1,
                      '@project1.targets.reload.count' => 1, 'Threshold.count' => 1 do
      visit project_targets_path(@project1)
      click_link t('targets.contextual.link_new_target')
      within 'form#new-target-form' do
        assert has_select?(t(:field_goal), selected: t('targets.form.binding_goal'))
        assert has_field?(t(:field_effective_from), with: Date.current.strftime)
        within 'p.target' do
          select quantities(:quantities_energy).name
          select '=='
          fill_in with: '1750'
          select units(:units_kcal).shortname
        end
        click_on t(:button_create)
      end
    end
    assert_equal @project1.goals.binding, Target.last.goal
    assert_no_selector 'form#new-target-form'
    assert_selector 'table#targets tbody tr', count: @project1.targets.count
  end

  def test_create_binding_target_when_binding_goal_does_not_exist
    @project1.goals.where(is_binding: true).delete_all
    assert_equal 0, @project1.goals.count(&:is_binding?)
    assert_difference ['Goal.count', '@project1.goals.reload.count(&:is_binding?)',
                       '@project1.targets.reload.count'], 1 do
      visit project_targets_path(@project1)
      click_link t('targets.contextual.link_new_target')
      within 'form#new-target-form' do
        # Assume binding Goal is selected by default
        within 'p.target' do
          select quantities(:quantities_energy).name
          select '=='
          fill_in with: '1750'
          select units(:units_kcal).shortname
        end
        click_on t(:button_create)
      end
    end
    assert_equal @project1.goals.binding, Target.last.goal
  end

  # TODO: test_create_failure(s)
  # * restoring user input
  # * removing empty targets

  # TODO: test edit and update separately
  def test_update
    visit project_targets_path(@project1)
    within 'table#targets tbody tr' do
      click_link t(:button_edit)
    end
  end
end
