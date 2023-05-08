# handle project
module "handle_project" {
  source = "./modules/handle_project"
  grants = {
    for jiraTicketCode, grant in local.grants
    : jiraTicketCode => [
      for assignRole in grant["assignRoles"]
      : assignRole
      if assignRole["type"] == "project"
    ]
  }
}

# handle specitic bucket admin
module "handle_specific_bucket_admin" {
  source = "./modules/handle_specific_bucket_admin"
  grants = {
    for jiraTicketCode, grant in local.grants
    : jiraTicketCode => [for assignRole in grant["assignRoles"]
      : assignRole
      if assignRole["type"] == "specific_bucket_admin"
    ]
  }
}

# handle organization
module "handle_organization" {
  source = "./modules/handle_organization"
  grants = {
    for jiraTicketCode, grant in local.grants
    : jiraTicketCode => [for assignRole in grant["assignRoles"]
      : assignRole
      if assignRole["type"] == "organization"
    ]
  }
}

# handle folder
module "handle_folder" {
  source = "./modules/handle_folder"
  grants = {
    for jiraTicketCode, grant in local.grants
    : jiraTicketCode => [for assignRole in grant["assignRoles"]
      : assignRole
      if assignRole["type"] == "folder"
    ]
  }
}

# 추가 type 지원 서브모듈 생성 시 여기에 추가해줘야 함