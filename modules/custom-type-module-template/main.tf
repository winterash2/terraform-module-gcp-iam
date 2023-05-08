# ---------------------------------------------------------
# "grants" = {
#   "CDDEVOPS-000" = [
#     {
#       "projects" = [
#         "prj-iam-terraform-test",
#       ]
#       "roles" = [
#         {
#           "role_id" = "roles/compute.viewer"
#         },
#       ]
#       "type" = "project"
#     },
#   ]
# }
# ---------------------------------------------------------

locals {
  result = {
    for jiraTicketCode, assignRoles in var.grants
    : jiraTicketCode => concat([
      for assignRole in assignRoles
      : {
        "type"     = assignRole["type"],
        "projects" = assignRole["projects"],
        "roles" = concat([{
          "role_id"    = "projects/prj-iam-terraform-test/roles/only_view_bucket_list",
          "expression" = "resource.name != \"for-unique-id(${jiraTicketCode})\""
        }])
      }
    ])
  }
}