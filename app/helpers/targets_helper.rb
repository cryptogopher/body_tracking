module TargetsHelper
  def action_links(date)
    link_to(l(:button_reapply), reapply_goal_targets_path(@goal, date, @view_params),
            {remote: true, class: "icon icon-reload"}) +
    link_to(l(:button_edit), edit_goal_targets_path(@goal, date, @view_params),
            {remote: true, class: "icon icon-edit"}) +
    delete_link(target_path(date), {remote: true, data: {}})
  end
end
