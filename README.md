# terraform-google-iam

이 모듈은 [terraform-google-module-template](https://github.com/kube-arc/terraform-google-module-template)에 의해서 생성되었습니다. 

The resources that this module will create are:

- Create IAM Rule

## Usage

모듈의 기본적인 사용법은 다음과 같습니다:

main.tf
```hcl
module "iam" {
  source = "https://github.com/kube-arc/terraform-module-gcp-iam"

  config_directories = var.config_directories
}
```
variables.tf
```hcl
impersonate_sa = "value"
config_directories = [
  "./default",
]
```

모듈 사용의 예시는 [examples](./examples/) 디렉토리에 있습니다.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| config_directories | yaml 포맷의 firewall config 파일이 위치한 폴더 경로의 List. 파일의 접미사는 반드시 .yaml여야 함. | list(string) | n/a | yes |

## Outputs

None

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Requirements

이 모듈을 사용하기 위해 필요한 사항을 표기합니다.

### Software

아래 dependencies들이 필요합니다:

- [Terraform][terraform] v0.13
- [Terraform Provider for GCP][terraform-provider-gcp] plugin v3.0

### Service Account

이 모듈의 리소스를 배포하기 위해서는 아래 역할이 필요합니다:

- Project IAM Admin: `roles/resourcemanager.projectIamAdmin`

[Project Factory module][project-factory-module] 과
[IAM module][iam-module]로 필요한 역할이 부여된 서비스 어카운트를 배포할 수 있습니다.

### APIs

이 모듈의 리소스가 배포되는 프로젝트는 아래 API가 활성화되어야 합니다:

- Identity and Access Management (IAM) API: `iam.googleapis.com`

[Project Factory module][project-factory-module]을 이용해 필요한 API를 활성화할 수 있습니다.

[iam-module]: https://registry.terraform.io/modules/terraform-google-modules/iam/google
[project-factory-module]: https://registry.terraform.io/modules/terraform-google-modules/project-factory/google
[terraform-provider-gcp]: https://www.terraform.io/docs/providers/google/index.html
[terraform]: https://www.terraform.io/downloads.html

## Contributing

- 이 모듈에 기여하기를 원한다면 [contribution guidelines](./CONTRIBUTING.md)를 참고 바랍니다.

## Changelog

- [CHANGELOG.md](./CHANGELOG.md)

## TO DO

- [ ]
- [X]
