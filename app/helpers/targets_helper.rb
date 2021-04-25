module TargetsHelper
  def action_links(date)
    link_to(l(:button_reapply), reapply_goal_target_path(@goal, date, @view_params),
            {remote: true, class: "icon icon-reload"}) +
    link_to(l(:button_edit), edit_goal_target_path(@goal, date, @view_params),
            {remote: true, class: "icon icon-edit"}) +
    delete_link(goal_target_path(@goal, date), {remote: true, data: {}})
  end
end
