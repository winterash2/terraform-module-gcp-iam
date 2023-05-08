# ---------------------------------------------------------
# "grants" = {
#   "CDDEVOPS-100" = {
#     "assignRoles" = [
#       {
#         "organizations" = [
#           "your-organization-id-1"
#           "your-organization-id-2"
#         ]
#         "roles" = [
#           {
#             "expression" = ""
#             "role_id" = "roles/compute.editor"
#           },
#         ]
#         "type" = "organization"
#       },
#     ]
#     "expirationDate" = "2023-03-22"
#     "principals" = {
#       "users" = [
#         "winterash2.cloud2@gmail.com",
#         "winterash2.cloud3@gmail.com",
#       ]
#     }
#   }
# }
# ---------------------------------------------------------

locals {
  result = {
    for jiraTicketCode, assignRoles in var.grants
    : jiraTicketCode => flatten([
      for assignRole in assignRoles
      : [for organization in assignRole["organizations"]
        : [for role in assignRole["roles"]
          : merge(
            role,
            {
              "organization" = organization
              "type"    = "organization"
            },
          )
        ]
      ]
    ])
  }
}