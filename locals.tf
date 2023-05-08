locals {
  config_file_names_with_abspath = flatten([
    for config_path in var.config_directories
    : [for config_file_name in fileset(config_path, "**100.yaml")
      : join("/", [abspath(path.root), config_path, config_file_name])
    ]
  ])

  jiraTicketCodes = [
    for config_file_name in local.config_file_names_with_abspath
    : trimsuffix(basename(config_file_name), ".yaml")
  ]

  # All file contents
  grants = {
    for file_name in local.config_file_names_with_abspath
    : trimsuffix(basename(file_name), ".yaml") => yamldecode(file(file_name))
  }

  flattened_principals = {
    for jiraTicketCode, grant in local.grants
    : jiraTicketCode => flatten([
      for p_type in keys(grant["principals"]) # users, groups, serviceAccounts 키로 순회
      : [for principal in grant["principals"][p_type]
        : join("", [trimsuffix(p_type, "s"), ":", principal])
      ]
    ])
  }

  # 각 모듈에서 나온 결과를 취합
  # TODO: 아래에서 하는 expirationDate 주입도 이 단계에서 할 수 있도록 하면 메모리 사용량을 줄일 수 있을 것 같음
  merged_handled_roles = {
    for jiraTicketCode in local.jiraTicketCodes
    : jiraTicketCode => concat(
      module.handle_project.result[jiraTicketCode],
      module.handle_specific_bucket_admin.result[jiraTicketCode],
      module.handle_organization.result[jiraTicketCode],
      module.handle_folder.result[jiraTicketCode],
      # type 추가 시 여기에 추가해줘야 함
    )
  }

  expirationDate_injected_roles = {
    for jiraTicketCode, roles in local.merged_handled_roles
    : jiraTicketCode => [
      for role in roles
      : merge(
        role,
        {
          "expression" = can(role["expression"]) ? join("", [
            "request.time < timestamp(\"${local.grants[jiraTicketCode]["expirationDate"]}T15:00:00.000Z\")", # expression이 있는 경우
            " && (",
            role["expression"],
            ")"
          ]) : "request.time < timestamp(\"${local.grants[jiraTicketCode]["expirationDate"]}T15:00:00.000Z\")" # expression이 없는 경우
      })
    ]
  }

  # Google Cloud Platform에서 IAM(members)의 ID는 
  # {project_id} or {organization_id} or {folder_id}
  # {role_id}
  # {principal}
  # {condition.title}
  # {condition.description}
  # {condition.expression}
  # 을 "/"로 구분하며 전부 이어붙인 형태임
  # 여기서는 하나의 iam에 대한 index_key를 sha256(id)로 한다
  final_merged_and_flattened = { for _, elem in flatten([
    for jiraTicketCode in local.jiraTicketCodes
    : [
      for principal in local.flattened_principals[jiraTicketCode]
      : [
        for role in local.expirationDate_injected_roles[jiraTicketCode]
        : merge(
          {
            "index_key" = sha256(join("/", [
              join("", [
                can(role["project"]) ? role["project"] : "",
                can(role["organization"]) ? role["organization"] : "",
                can(role["folder"]) ? role["folder"] : "",
                can(role["bucket"]) ? join("/", ["b", role["bucket"]]) : "",
                # TODO: 새로운 resource를 사용하는 type을 추가했을 시, 해당 resource에서 사용하는 필드값을 여기에 추가해줘야 함
                # try(role["project"], role["organization"], role["folder"])
              ]),
              role["role_id"],
              principal,
              format("EXP-%s-%s", local.grants[jiraTicketCode]["expirationDate"], jiraTicketCode),
              "", # 이 모듈에서는 description을 아예 설정하지 않기 때문에 그냥 ""로 처리함, 굳이 넣은 이유는 delimeter인 /가 들어가야 하기 때문임
              role["expression"]
            ])),
            "principal" = principal,
            "title"     = format("EXP-%s-%s", local.grants[jiraTicketCode]["expirationDate"], jiraTicketCode),
          },
          {
            for key in keys(role)
            : key => role[key]
          }
        )
      ]
    ]]) # 위에서 한 번 index_key, title을 만들어서 주입한 것을 가지고 index_key => else 형태로 변환
    : elem["index_key"] => {
      for key in keys(elem)
      : "${key}" => elem[key]
      if key != "index_key"
    }
  }
}
