# Yaml 작성 가이드
이 모듈은 IAM 생성 시에 필요한 대부분의 정보를 terraform의 variable을 이용하지 않고, YAML 파일을 작성해야 합니다.

이 가이드는 IAM 권한 부여를 위한 YAML 파일을 작성하는 방법을 설명합니다.

## 주의 사항
- 파일을 여러 디렉토리에 나눠서 저장할 수 있지만, 동일한 파일 이름은 하나만 존재해야 합니다.

## IAM Policy YAML 작성 가이드

| Name | Name2 | Description |
| -- | -- | -- |
| expirationDate |  | "부여된 권한의 유효 기간" |
| principals | users | "권한을 부여할 계정" |
| | groups | "권한을 부여할 그룹" |
| | serviceAccounts | "권한을 부여할 서비스 계정" |
| assignRoles | type | "부여할 권한들" |

assginRoles에 들어가는 assignRole의 형태는 role을 적용하는 scope에 따라 다르고, custom 타입의 경우 개발한 형태마다 다름

각 타입의 yaml 파일 형태는 docs의 yaml 파일들을 참고하시기 바랍니다
