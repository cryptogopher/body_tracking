module TargetsHelper
  def condition_options
    Target::CONDITIONS
  end

  def action_links(d)
    link_to(l(:button_reapply), reapply_project_targets_path(@project, d, @view_params),
            {remote: true, class: "icon icon-reload"}) +
    link_to(l(:button_edit), edit_target_path(@project, d, @view_params),
            {remote: true, class: "icon icon-edit"}) +
    delete_link(target_path(d), {remote: true, data: {}})
  end
end
