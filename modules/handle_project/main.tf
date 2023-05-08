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
#   "CDDEVOPS-001" = [
#     {
#       "projects" = [
#         "prj-iam-terraform-test",
#       ]
#       "roles" = [
#         {
#           "role_id" = "roles/storage.viewer"
#         },
#       ]
#       "type" = "project"
#     },
#   ]
# }
# ---------------------------------------------------------

locals {
  # result = var.grants
  result = {
    for jiraTicketCode, assignRoles in var.grants
    : jiraTicketCode => flatten([
      for assignRole in assignRoles
      : [for project in assignRole["projects"]
        : [for role in assignRole["roles"]
          : merge(
            role,
            {
              "project" = project
              "type"    = "project"
            },
          )
        ]
      ]
    ])
  }
}