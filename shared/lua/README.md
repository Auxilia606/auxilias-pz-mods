# Shared Lua

여러 모드에서 동일하게 사용하는 Project Zomboid 런타임 Lua의 원본 위치다. Workshop은
레포 밖의 공통 모듈을 직접 참조할 수 없으므로, 배포 시 각 모드 트리에 실제 파일을
복사해야 한다.

공유 파일을 추가할 때 `config/mods.json`의 해당 모드에 다음과 같이 매핑한다.

```json
{
  "source": "Auxilia/Example.lua",
  "destination": "media/lua/shared/Auxilia/Example.lua"
}
```

그다음 `./tools/sync-shared.ps1`을 실행한다. `./tools/validate.ps1`은 원본과 배포본의
SHA-256이 다르면 실패한다. 자동 로드되는 Lua는 전역 부작용을 최소화하고, 공개 함수와
이벤트 등록의 소유권을 파일 상단에 문서화한다.
