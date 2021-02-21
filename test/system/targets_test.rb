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

  def test_new
    visit project_targets_path(@project1)
    assert_no_selector 'form#new-target-form'
    click_link t('targets.contextual.link_new_target')
    assert_selector 'form#new-target-form', count: 1
    within 'form#new-target-form' do
      assert has_select?(t(:field_goal), selected: t('targets.form.binding_goal'))
      assert has_field?(t(:field_effective_from), with: Date.current)
      assert has_no_link?(t('targets.form.button_delete_target'))
    end
  end

  def test_new_cancel
    visit project_targets_path(@project1)
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
        within 'p.target' do
          select quantities(:quantities_energy).name
          select quantities(:quantities_target_equal).name
          fill_in with: '1750'
          select units(:units_kcal).shortname
        end
        click_on t(:button_create)
      end
    end

    t = Target.last
    assert_equal @project1.goals.binding, t.goal
    assert_equal Date.current, t.effective_from
    assert_equal quantities(:quantities_energy), t.quantity
    assert_equal quantities(:quantities_target_equal), t.thresholds.first.quantity
    assert_equal 1750, t.thresholds.first.value
    assert_equal units(:units_kcal), t.thresholds.first.unit

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

  def test_create_multiple_targets
  end

  # TODO: test_create_failure(s)
  # * restoring user input
  # * removing empty targets

  def test_edit
    t = Target.offset(rand(Target.count)).take
    visit project_targets_path(@project1)
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
    visit project_targets_path(@project1)

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
