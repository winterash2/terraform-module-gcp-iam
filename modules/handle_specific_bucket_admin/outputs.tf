// argument 체크
output "grants" {
  value = var.grants
}

// return 값 체크
# "result" = {
#   "CDDEVOPS-000" = [
#     {
#       "projects" = [
#         "prj-iam-terraform-test",
#       ]
#       "roles" = [
#         {
#           "expression" = "resource.name != \"for-unique-id(CDDEVOPS-000)\""
#           "role_id" = "projects/prj-iam-terraform-test/roles/only_view_bucket_list"
#         },
#         {
#           "expression" = <<-EOT
#           (
#             resource.name == "projects/_/buckets/bkt-terraform-iam-test"
#             &&
#             resource.type == "storage.googleapis.com/Bucket"
#           )
#           || 
#           (
#             resource.name.startsWith("projects/_/buckets/bkt-terraform-iam-test")
#             &&
#             resource.type == "storage.googleapis.com/Object"
#           )

#           EOT
#           "role_id" = "roles/storage.admin"
#         },
#         {
#           "expression" = <<-EOT
#           (
#             resource.name == "projects/_/buckets/bkt-test-module"
#             &&
#             resource.type == "storage.googleapis.com/Bucket"
#           )
#           || 
#           (
#             resource.name.startsWith("projects/_/buckets/bkt-test-module")
#             &&
#             resource.type == "storage.googleapis.com/Object"
#           )

#           EOT
#           "role_id" = "roles/storage.admin"
#         },
#       ]
#       "type" = "specific_bucket_admin"
#     },
#   ]
#   "CDDEVOPS-001" = [] // specific_bucket_admin 타입의 role이 없는 경우
# }
output "result" {
  value = local.result
}