# 여기서 처음 받는건
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
# 이 형태가 될 것, type이 project인 것만

variable "grants" {
  type = any
}