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
    assert_selector 'table#targets tbody tr',
      count: goal.targets.distinct.pluck(:effective_from).count
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
    date = Date.current + rand(-10..10).days
    quantity = @project.quantities.except_targets.sample
    threshold_quantity = @project.quantities.target.roots.sample
    threshold_value = rand(-2000.0..2000.0).to_d(4)
    threshold_unit = @project.units.sample

    assert_difference 'Goal.count' => 0, 'Target.count' => 1,
                      '@project.targets.reload.count' => 1, 'Threshold.count' => 1 do
      visit goal_targets_path(@project.goals.binding)
      click_link t('targets.contextual.link_new_target')

      within 'form#new-target-form' do
        fill_in t(:field_effective_from), with: date
        within 'p.target' do
          select quantity.name
          select threshold_quantity.name
          fill_in with: threshold_value
          select threshold_unit.shortname
        end
        click_on t(:button_create)
      end
    end

    t = Target.last
    assert_equal @project.goals.binding, t.goal
    assert_equal date, t.effective_from
    assert_equal quantity, t.quantity
    assert_equal threshold_quantity, t.thresholds.first.quantity
    assert_equal threshold_value, t.thresholds.first.value
    assert_equal threshold_unit, t.thresholds.first.unit

    assert_no_selector 'form#new-target-form'
    assert_selector 'table#targets tbody tr',
      count: @project.goals.binding.targets.distinct.pluck(:effective_from).count
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
          select @project.quantities.except_targets.sample.name
          select @project.quantities.target.roots.sample.name
          fill_in with: rand(-2000.0..2000.0).to_d(4)
          select @project.units.sample.shortname
        end
        click_on t(:button_create)
      end
    end
    assert_equal @project.goals.binding, Target.last.goal
  end

  def test_create_with_subthresholds
    quantity = @project.quantities.except_targets.sample
    thresholds =
      @project.quantities.target.where.not(parent: nil).sample.self_and_ancestors.map do |q|
        [q, rand(-2000.0..2000.0).to_d(4), @project.units.sample]
      end

    assert_difference 'Goal.count' => 0, 'Target.count' => 1,
                      '@project.targets.reload.count' => 1,
                      'Threshold.count' => thresholds.length do
      visit goal_targets_path(@project.goals.binding)
      click_link t('targets.contextual.link_new_target')

      within 'form#new-target-form' do
        within 'p.target' do
          select quantity.name
          thresholds.each do |t_quantity, t_value, t_unit|
            within select(t_quantity.name).ancestor('select') do
              find(:xpath, 'following-sibling::input[not(@type="hidden")][1]').set(t_value)
              find(:xpath, 'following-sibling::select[1]').select(t_unit.shortname)
            end
          end
        end
        click_on t(:button_create)
      end
    end

    t = Target.last
    assert_equal thresholds.length, t.thresholds.length
    thresholds.each_with_index do |threshold, index|
      t_quantity, t_value, t_unit = threshold
      assert_equal t_quantity, t.thresholds[index].quantity
      assert_equal t_value, t.thresholds[index].value
      assert_equal t_unit, t.thresholds[index].unit
    end
  end

  def test_create_multiple_targets
    # TODO
  end

  def test_create_properly_handles_data_on_failure
    # TODO
    # * restoring non-empty targets values
    # * removing empty targets
  end

  def test_create_duplicate_for_persisted_target_should_fail
    # TODO: extend with item + scope
    source = @project.targets.sample
    msg = t('activerecord.errors.models.target.attributes.base.duplicated_record')

    visit goal_targets_path(source.goal)
    click_link t('targets.contextual.link_new_target')

    assert_no_difference 'Target.count' do
      within 'form#new-target-form' do
        fill_in t(:field_effective_from), with: source.effective_from

        within 'p.target' do
          select source.quantity.name
          select @project.quantities.target.roots.sample.name
          fill_in with: rand(-2000.0..2000.0).to_d(4)
          select @project.units.sample.shortname
        end

        click_on t(:button_create)
        assert_selector :xpath, '//p[@class="target"]//preceding-sibling::div', text: msg
      end
    end
  end

  def test_create_duplicated_targets_should_fail
    date = Date.current + rand(-10..10).days
    quantity = @project.quantities.except_targets
      .joins("LEFT OUTER JOIN targets ON targets.quantity_id = quantities.id \
                AND targets.effective_from = #{date}")
      .where(targets: {id: nil}).sample
    assert quantity
    msg = t('activerecord.errors.models.target.attributes.base.duplicated_record')

    visit goal_targets_path(@project.goals.binding)
    click_link t('targets.contextual.link_new_target')

    assert_no_difference 'Target.count' do
      within 'form#new-target-form' do
        fill_in t(:field_effective_from), with: date

        within :xpath, '//p[@class="target"][1]' do
          select quantity.name
          select @project.quantities.target.roots.sample.name
          fill_in with: rand(-2000.0..2000.0).to_d(4)
          select @project.units.sample.shortname
        end
        click_link t('targets.form.button_new_target')

        within :xpath, '//p[@class="target"][2]' do
          select quantity.name
          select @project.quantities.target.roots.sample.name
          fill_in with: rand(-2000.0..2000.0).to_d(4)
          select @project.units.sample.shortname
        end
        click_on t(:button_create)

        assert_selector :xpath, '//p[@class="target"][last()]//preceding-sibling::div',
          text: msg
      end
    end
  end

  def test_edit_binding_target
    date = @project.goals.binding.targets.distinct.pluck(:effective_from).sample

    visit goal_targets_path(@project.goals.binding)
    assert_no_selector 'form#edit-target-form'

    within find('td', text: date).ancestor('tr') do
      click_link t(:button_edit)
      # Form count check is done implicitly by [within 'form#edit-target-form'] below
      assert_selector :xpath, 'following-sibling::tr//form[@id="edit-target-form"]'
    end

    within 'form#edit-target-form' do
      assert has_field?(t(:field_effective_from), with: date, count: 1)

      targets = @project.goals.binding.targets.where(effective_from: date)
      assert_selector 'p.target', count: targets.length

      targets.each do |target|
        within find('option[selected]', exact_text: target.quantity.name)
                 .ancestor('p.target') do
          assert_selector 'input, select', count: 1 + 3*target.thresholds.length

          target.thresholds.each do |threshold|
            within find('option[selected]', exact_text: threshold.quantity.name)
                     .ancestor('select') do
              assert has_selector?(:xpath,
                                   'following-sibling::input[not(@type="hidden")][1]',
                                   exact_text: threshold.value)
              assert has_selector?(:xpath, 'following-sibling::select//option[@selected]',
                                   exact_text: threshold.unit.shortname)
            end
          end

          if targets.length == 1
            assert has_no_link?(t('targets.form.button_delete_target'))
          else
            assert has_link?(t('targets.form.button_delete_target'))
          end
        end
      end

      assert has_link?(t('targets.form.button_new_target'), count: 1)
    end
  end

  def test_update_binding_target
    # TODO: extend with item + scope
    target = @project.goals.binding.targets.sample
    existing_quantities = @project.goals.binding.targets.joins(:quantity)
      .where(effective_from: target.effective_from).pluck(:quantity_id)
    date = Date.current + rand(-10..10).days
    quantity = @project.quantities.except_targets.where.not(id: existing_quantities).sample
    assert quantity
    thresholds =
      @project.quantities.target.where.not(parent: nil).sample.self_and_ancestors.map do |q|
        [q, rand(-2000.0..2000.0).to_d(4), @project.units.sample]
      end

    visit goal_targets_path(@project.goals.binding)
    find('td', text: target.effective_from).ancestor('tr').click_link t(:button_edit)

    assert_difference 'Goal.count' => 0, 'Target.count' => 0,
                      'Threshold.count' => thresholds.length - target.thresholds.length do
      within 'form#edit-target-form' do
        fill_in t(:field_effective_from), with: date

        within find('option[selected]', exact_text: target.quantity.name)
                 .ancestor('p.target') do
          select quantity.name
          thresholds.each do |t_quantity, t_value, t_unit|
            within select(t_quantity.name).ancestor('select') do
              find(:xpath, 'following-sibling::input[not(@type="hidden")][1]').set(t_value)
              find(:xpath, 'following-sibling::select[1]').select(t_unit.shortname)
            end
          end
        end

        click_on t(:button_save)
      end
    end

    target.reload
    assert_equal date, target.effective_from
    assert_equal quantity, target.quantity
    assert_equal thresholds.length, target.thresholds.length
    thresholds.each_with_index do |threshold, index|
      t_quantity, t_value, t_unit = threshold
      assert_equal t_quantity, target.thresholds[index].quantity
      assert_equal t_value, target.thresholds[index].value
      assert_equal t_unit, target.thresholds[index].unit
    end
  end

  def test_update_swap_targets
    # TODO: extend with item + scope
    date, goal_id = Target.joins(:goal).group(:effective_from, :goal_id).count
      .select { |k,v| v > 1 }.keys.sample
    assert date
    goal = Goal.find(goal_id)
    target1, target2 = goal.targets.where(effective_from: date).sample(2)
    quantity1, quantity2 = target1.quantity.name, target2.quantity.name

    visit goal_targets_path(goal)
    find('td', text: date).ancestor('tr').click_link t(:button_edit)

    assert_no_difference 'Target.count' do
      within 'form#edit-target-form' do
        select1 = find('option[selected]', exact_text: quantity1).ancestor('select')
        select2 = find('option[selected]', exact_text: quantity2).ancestor('select')

        select1.select quantity2
        select2.select quantity1

        click_on t(:button_save)
        assert_no_selector 'div#errorExplanation'
      end
    end

    target1.reload
    target2.reload
    assert quantity2, target1.quantity.name
    assert quantity1, target2.quantity.name
  end

  def test_update_add_and_simultaneously_remove_persisted_duplicate
    # TODO
  end
end
