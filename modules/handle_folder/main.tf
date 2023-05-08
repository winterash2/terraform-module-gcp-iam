# ---------------------------------------------------------
# "grants" = {
#   "CDDEVOPS-100" = {
#     "assignRoles" = [
#       {
#         "folders" = [
#           "your-folder-id-1",
#           "your-folder-id-2",
#         ]
#         "roles" = [
#           {
#             "expression" = ""
#             "role_id" = "roles/compute.editor"
#           },
#         ]
#         "type" = "folder"
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
  # result = var.grants
  result = {
    for jiraTicketCode, assignRoles in var.grants
    : jiraTicketCode => flatten([
      for assignRole in assignRoles
      : [for folder in assignRole["folders"]
        : [for role in assignRole["roles"]
          : merge(
            role,
            {
              "folder" = folder
              "type"    = "folder"
            },
          )
        ]
      ]
    ])
  }
}