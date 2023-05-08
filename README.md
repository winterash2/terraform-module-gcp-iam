# Terraform Module GDP IAM

이 모듈은 Google Cloud Platform을 사용할 때 IAM 권한 부여 및 관리를 위해 개발한 terraform 모듈임  
모듈에 대한 상세 설명과 사용 방법은 docs 폴더의 문서들을 참고해주시기 바람

## 요구 사항

모듈 개발에 대한 요구사항은 아래와 같음

1. yaml 형태로 작성할 수 있도록 개발(HCL을 몰라도 사용할 수 있도록)
2. 자주 함께 사용되는 여러 role을 간단하게 부여할 수 있게끔 개발  
    현재는 권한 부여 요청을 팀에서 받아 처리하지만,       
    추후 권한 요청을 먼저 외주 인력이 먼저 받아 yaml 파일을 작성하고,  
    팀에서는 적절한지 확인 후 terraform apply에 대한 승인만 하는 방식으로 업무 부하를 줄이기 위함
3. 반드시 유효 기간이 적용되게끔 개발  
    장기적으로 사용되는 권한이라고 하더라도 최대 6개월 단위로 부여하고, 추후 갱신을 하는 정책으로 운영
4. 유효 기간이 만료되었을 때 자동적으로 제거하는 방안을 고려하여 개발

## 개발 시 고려한 것들

### GCP의 권한 부여 단위
GCP에서 권한 부여는 다양한 리소스에 대해 설정 가능함  
예를 들면 project 단위로 설정하거나, 특정 리소스(GCS버킷, BigQuery 테이블)에만 적용되게끔 설정 하는 등임  
따라서 Google에서 공식적으로 제공하는 [terraform 모듈](https://github.com/terraform-google-modules/terraform-google-iam)은 다양한 리소스에 대한 모듈을 각 리소스마다 제공함. 아래는 리소스의 종류임
- Artifact Registry IAM
- Audit Config
- BigQuery IAM
- Billing Accounts IAM
- Cloud Run Service IAM
- Custom Role IAM
- DNS Zone IAM
- Folders IAM
- KMS Crypto Keys IAM
- KMS_Key Rings IAM
- Organizations IAM
- Projects IAM
- Pubsub Subscriptions IAM
- Pubsub Topics IAM
- Secret Manager IAM
- Service Accounts IAM
- Storage Buckets IAM
- Subnets IAM

이 리소스 종류는 Google Cloud Platform Provider 에서 제공하는 리소스 중 IAM과 관련된 것들의 종류와 일치함  
이렇게 여러 모듈을 제공하고 있지만, 실제 운영 환경에서 리소스마다 다른 모듈을 쓰는 것은 불편할 것으로 보여 한 모듈에서 여러 리소스에 대한 권한 부여가 가능하도록 개발함  
yaml 작성할 때, 각 role마다 `type`을 입력받아서 어떤 리소스에 대한 권한 부여인지 지정하게끔 개발함

### 유효기간 설정
GCP에서 권한을 부여할 때 유효기간을 설정하는 방법은 condition에 expire 구문을 추가하는 것임  
하지만 어떤 리소스들에 대한 IAM 권한 부여를 할 때는 condition 설정이 불가능함  
condition을 설정할 수 있어야 권한 부여 단계에서 유효 기간을 설정할 수 있기 때문에 condition 설정이 불가능한 리소스 IAM은 정책상 사용하기 힘듦  
예를 들면 GCS Bucket의 경우 ACL 정책을 uniform이 아니라 fine-grained로 설정한 경우 GCS 버킷 리소스 단위의 권한 부여 시 condition 설정이 불가능함  
이러한 경우에는 project 단위로 GCS Bucket에 대한 권한을 부여하면서 resource name prefix를 이용한 condition을 이용하여 권한 부여시에 특정 Bucket에만 접근이 가능하도록 설정

아래는 특정 버킷과 버킷 내의 Object들에만 권한이 적용되도록 작성한 condition임  

```
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
```

### 쉬운 권한 부여
위와 같이 권한 부여를 하는 것은 yaml파일을 작성할 때, condition 작성을 매번 하는것이 어렵고 오류가 많이 생길 수 있음  
이러한 문제를 해결하기 위해 자주 설정하는 것들은 간단하게 설정할 수 있도록 `custom type`을 추가할 수 있게끔 개발함

또한 custom type을 추가할 때, 기존에 작성된 모듈 코드의 변화를 최소화할 수 있도록 module in module 구조로 개발함  
특정 `type` 혹은 `custom type`을 추가할 때 기존 코드는 최소한으로 수정하고, 대부분의 로직은 해당 type을 처리하는 sub module을 개발할 때 추가할 수 있게끔 개발함  
이 부분에 대한 내용은 docs/00-module-description.md 문서를 참고할 것

### 유효기간이 만료된 권한 자동 제거
위에서 설명한 바와 같이 condition을 이용하여 부여한 권한의 유효 기간을 설정하더라도 자동으로 제거되지 않음  
따라서 유효기간이 만료되었을 때 제거가 되도록 자동화를 해야 함  
우리 팀에서는 이 방법으로 Jira의 Automation을 연동한 방법을 적용하기로 함. 방법은 아래와 같음
1. 권한 부여를 요청하는 Jira 티켓에 만료 기한을 지정함
2. yaml 파일을 작성할 때, 파일 이름을 Jira 티켓명으로 설정
3. Jira Automation 룰에 만료 기한이 지난 티켓에 대한 정보를 webhook으로 어딘가에 전송하는 룰 추가
4. 해당 webhook을 받아서 Jira 티켓명에 해당하는 yaml 파일을 삭제하고 terraform apply 하는 서버를 개발하여 운영, 혹은 Tekton이나 Argo Workflow 같은 CI 도구를 이용

## 개선이 필요한 사항
모듈을 개발할 때, 코드를 보고 이해하기 조금 더 용이하도록 locals.tf 내에서 여러 variable을 만들면서 로직을 나눴음  
로직을 나눠 가독성은 조금 좋아졌다고 생각하지만, 로직을 나눌때마다 사용한 variable들에 중복되는 정보들이 계속 쌓여 과도한 메모리를 사용할 수 있을 것 같음  
동일한 데이터가 덜 중복되면서도 로직을 나눌 수 있도록 구조 개선을 할 수 있으면 좋을 것 같음
