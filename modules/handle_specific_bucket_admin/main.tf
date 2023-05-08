# ---------------------------------------------------------

# ---------------------------------------------------------

locals {
  result = {
    for jiraTicketCode, assignRoles in var.grants
    : jiraTicketCode => flatten(concat([
      for assignRole in assignRoles
      : [
        for project in assignRole["projects"]
        : [
          concat(
            [{ // 콘솔에서 bucket쪽 찾아서 들어가려면 있어야 함. 대신 소유하지 않는 버킷도 보임
              "type"    = "project",
              "project" = project,
              "role_id" = "projects/${project}/roles/only_view_bucket_list",
              # "expression" = "resource.name != \"for-unique-id(${jiraTicketCode})\""
            }],
            [
              for bucket_id in assignRole["bucket_ids"]
              : {
                "type"       = "project",
                "project"    = project,
                "role_id"    = "roles/storage.admin",
                "expression" = <<-EOF
                  (
                    resource.name == "projects/_/buckets/${bucket_id}"
                    &&
                    resource.type == "storage.googleapis.com/Bucket"
                  )
                  || 
                  (
                    resource.name.startsWith("projects/_/buckets/${bucket_id}")
                    &&
                    resource.type == "storage.googleapis.com/Object"
                  )
                  EOF
              }
            ],
          )
        ]
      ]]
    ))
  }
}