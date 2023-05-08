resource "google_project_iam_member" "iam" {
  for_each = { for index_key, value in local.final_merged_and_flattened :
    index_key => value
    # if value["type"] == "project"
    if contains([
      "project",
    ], value["type"])
  }
  project = each.value.project
  role    = each.value.role_id
  member  = each.value.principal

  condition {
    title      = each.value.title
    expression = each.value.expression
  }
}

resource "google_organization_iam_member" "iam" {
  for_each = { for index_key, value in local.final_merged_and_flattened :
    index_key => value
    # if value["type"] == "project"
    if contains([
      "organization",
    ], value["type"])
  }

  org_id = each.value.organization
  role   = each.value.role_id
  member = each.value.principal

  condition {
    title      = each.value.title
    expression = each.value.expression
  }
}

resource "google_folder_iam_member" "iam" {
  for_each = { for index_key, value in local.final_merged_and_flattened :
    index_key => value
    # if value["type"] == "project"
    if contains([
      "folder",
    ], value["type"])
  }

  folder = each.value.folder
  role   = each.value.role_id
  member = each.value.principal

  condition {
    title      = each.value.title
    expression = each.value.expression
  }
}