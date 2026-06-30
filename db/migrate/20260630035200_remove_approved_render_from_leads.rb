class RemoveApprovedRenderFromLeads < ActiveRecord::Migration[8.1]
  def change
    remove_column :leads, :approved_render, :boolean
  end
end
