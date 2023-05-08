# 모듈 설명
이 설명은 IAM 모듈을 유지보수하고, 특정 요구조건에 대해 간편하게 권한 부여를 할 수 있도록 custom type을 만들 때, 참고할 수 있도록 

개발한 모듈의 구조와, 특히 관리가 필요한 부분들에 대한 설명을 남겨두기 위해 작성함

이 IAM 모듈은 IAM 모듈이 사용하기 위한 모듈을 사용함(module in module 구조)

IAM 모듈에서 사용하기 위해 사용하는 모듈을 서브모듈이라고 칭함

## Custom Type 추가 방법

Custom type을 추가하기 위해서는 아래 부분들을 수정해야 함

1. handler 서브 모듈 작성

    module_root_path/modules 폴더에 handle_{custom type 이름} 폴더를 생성하고, custom-type-module-template 폴더에 있는 내용을 전부 복사

    Custom 타입을 처리하는 handler는 사용자가 YAML 파일에 작성한 assignRole을 type(resource type), role_id, +a 형태로 flatten하여 반환함
    
    예) resource 타입이 project인 경우

    ```hcl
    {
        type: project
        role_id: 부여하려는 role의 id
        project: 해당 role을 부여하려는 project의 id //project 타입의 resource를 생성할 때 필요함
    }
    ```
    ```hcl
    locals {
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
    ```
    
    project 타입 핸들러는 list로 입력받은 project_id와 role_id를 flatten 함

    예: resource 타입이 organization인 경우

    ```hcl
    {
        type: organization
        role_id: 부여하려는 role의 id
        organization: 해당 role을 부여하려는 조직의 id
    }
    ```
    ```hcl
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
    ```
    organization 타입 핸들러는 list로 입력받은 organization_id와 role_id를 flatten 함

    단순히 resource와 1:1로 매핑되는 타입이 아니라, 팀의 필요에 의해 타입을 만들 수 있음

    아래는 specific_bucket_admin 이라는 커스텀 타입임

    specific_bucket_admin 타입은 사용자에게 특정 버킷에 대한 admin 권한을 부여하는 타입임

    admin 권한 부여는 GCS 에서의 권한부여가 아닌, project 단위의 storage admin 권한을 주되 condition을 이용해 특정 버킷으로 영향을 제한시키는 방법으로 부여함

    이 예시에서 부여하는 only_view_bucket_list 라는 role은 콘솔에서 bucket list를 볼 수 있도록 storage.bucket.list 퍼미션만 들어있는 custom role임

    ```hcl
    locals {
        result = {
            for jiraTicketCode, assignRoles in var.grants
            : jiraTicketCode => flatten(concat([
            for assignRole in assignRoles
            : [
                for project in assignRole["projects"]
                : [
                concat(
                    [{
                    "type"    = "project",
                    "project" = project,
                    "role_id" = "projects/prj-iam-terraform-test/roles/only_view_bucket_list",
                    # "description" = "${grant["jiraTicketCode"]}",
                    # "expression" = "resource.name != \"for-unique-id(${jiraTicketCode})\""
                    }],
                    [
                    for bucket_id in assignRole["bucket_ids"]                                                       // 각각의 버킷에 대해 storage admin 권한을 부여
                    : {
                        "type"       = "project",
                        "project"    = project,
                        "role_id"    = "roles/storage.admin",
                        "expression" = <<-EOF
                        (
                            resource.name == "projects/_/buckets/${bucket_id}"                                      // 해당 버킷에만 접근 가능하도록 제한
                            &&
                            resource.type == "storage.googleapis.com/Bucket"
                        )
                        ||
                        (
                            resource.name.startsWith("projects/_/buckets/${bucket_id}")                             // 해당 버킷에만 접근 가능하도록 제한
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
    ```
2. iam 모듈에서 handler 서브 모듈 호출
    서브모듈 호출은 module_root_path/submodules.tf 파일에서 함

    여기에 다른 타입과 동일하게 submodule 을 호출하는 코드를 삽입해야 함

    예: project 타입

    ```hcl
    module "handle_project" {                         // module에 새로 생성한 폴더와 동일한 이름으로 지정
        source = "./modules/handle_project"        // 모듈 소스 위치를 새로 생성한 폴더로 지정
        grants = {
            for jiraTicketCode, grant in local.grants
            : jiraTicketCode => [
            for assignRole in grant["assignRoles"]
            : assignRole
            if assignRole["type"] == "project"         // 새로운 custom type으로 변경
            ]
        }
    }
    ```
3. handler 서브 모듈에서 반환하는 결과를 병합
    module_root_path/locals.tf 파일에 merged_handled_roles 로컬 변수가 handler 서브 모듈에서 반환하는 결과를 병합하는 역할을 함

    ```hcl
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
    ```

## 새로운 Terraform google resource 추가 방법

새로운 terraform google resource를 사용하도록 추가하는 경우 아래 부분들을 수정해야 함

1. main.tf에 resource 구문 추가
    module_root_path/main.tf 파일에 추가하는 resource 구문을 추가해줘야 함

    ```hcl
    resource "google_organization_iam_member" "iam" {                               // 모듈명은 iam으로 고정, resource의 종류만 수정
        for_each = { for index_key, value in local.final_merged_and_flattened :
            index_key => value
            if contains([
            "organization",                                                                                   // 이 부분 수정
            ], value["type"])  Google Cloud Platform에서 IAM(members)의 ID는
        {project_id} or {organization_id} or {folder_id}
        {role_id}
        {principal}
        {condition.title}
        {condition.description}
        {condition.expression}
        을 "/"로 구분하며 전부 이어붙인 형태임
        여기서는 하나의 iam에 대한 index_key를 sha256(id)로 한다
        }
        
        org_id = each.value.organization
        role   = each.value.role_id
        member = each.value.principal
        
        condition {
            title      = each.value.title
            expression = each.value.expression
        }
    }
    ```
2. unique한 id를 생성할 수 있도록 코드 수정

    Google Cloud Platform에서 IAM(members)의 ID는

    {project_id} or {organization_id} or {folder_id}

    {role_id}

    {principal}

    {condition.title}

    {condition.description}

    {condition.expression}

    을 "/"로 구분하며 전부 이어붙인 형태임

    여기서는 하나의 iam에 대한 index_key를 sha256(id)로 함

    리소스가 추가되는 경우, 해당 리소스에서 사용하는 필드의 값을 추가해줘야 함

    ```hcl
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
                            can(role["bucket"]) ? join("/", ["b", role["bucket"]]) : "",    // 이 부분에 추가
                                                                                            // 새로운 resource를 사용하는 type을 추가했을 시, 해당 resource에서 사용하는 필드값을 여기에 추가해줘야 함
                                                                                            // bucket 타입의 경우 그냥 bucket_id가 아니라 b/{bucket_id} 형태로 id가 생성되어 앞에 b/ 를 붙임
                            # try(role["project"], role["organization"], role["folder"])
                            ]),
                            role["role_id"],
                            principal,
                            format("EXP-%s-%s", local.grants[jiraTicketCode]["expirationDate"], jiraTicketCode),
                            "",   # 이 모듈에서는 description을 아예 설정하지 않기 때문에 그냥 ""로 처리함, 굳이 넣은 이유는 delimeter인 /가 들어가야 하기 때문임
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
    ```
