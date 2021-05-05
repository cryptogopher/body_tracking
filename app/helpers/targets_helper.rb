module TargetsHelper
  def target_markup(date, quantity, target)
    content = "#{'&emsp;'*quantity.depth}#{quantity.name} #{target.to_s}"

    classes = []
    if date == target&.effective_from
      classes << 'bolded' if @goal.quantities.include?(quantity)
    else
      classes << 'dimmed'
    end

    content_tag(:span, content, {class: classes}, false)
  end

  def action_links(date)
    link_to(l(:button_reapply), reapply_goal_target_path(@goal, date, @view_params),
            {remote: true, class: "icon icon-reload"}) +
    link_to(l(:button_edit), edit_goal_target_path(@goal, date, @view_params),
            {remote: true, class: "icon icon-edit"}) +
    delete_link(goal_target_path(@goal, date), {remote: true, data: {}})
  end
end
