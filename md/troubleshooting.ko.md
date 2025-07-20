# GPosingway 문제 해결 가이드

<div align="right">
  <b>이 문서를 다음 언어로 읽기:</b>
  <a href="./troubleshooting.md">English</a> | 
  <a href="./troubleshooting.ja.md">日本語</a> | 
  <b>한국어</b> 
</div>

---

GPosingway 사용 중 문제가 발생했나요? 이 가이드를 사용하여 일반적인 문제를 해결하세요.

---

## 설치 문제

### 권한 오류
- **문제**: 설치 스크립트에 파일 수정 권한이 없습니다.
- **해결책**:
  1. `game` 폴더를 마우스 오른쪽 버튼으로 클릭하고 `속성` (`Properties`)을 선택합니다.
  2. `보안` (`Security`) 탭으로 이동하여 `Users`를 선택합니다.
  3. `편집` (`Edit`)을 클릭하고 `수정` (`Modify`) 권한을 확인(체크)합니다.
  4. `적용` (`Apply`)을 클릭하여 변경 사항을 저장합니다.

### GPosingway가 작동하지 않음
- **문제**: 잘못된 설치 또는 버전 불일치.
- **해결책**:
  - 사용 중인 ReShade 버전에 맞는 올바른 GPosingway 버전이 설치되었는지 확인하십시오.
  - 설치 스크립트 또는 압축 해제된 파일을 `game` 폴더에 직접 배치하십시오.
  - 충돌을 피하기 위해 이전 셰이더 (`reshade-shaders`) 및 프리셋 (`reshade-presets`) 폴더의 이름을 변경하십시오.

### 오류 메시지
- **문제**: 다른 모드와의 충돌 또는 누락된 파일.
- **해결책**:
  - 특히 Dalamud와 같은 다른 모드와의 충돌을 확인하십시오.
  - `dxgi.log` 파일을 삭제하고 게임을 다시 시작하십시오.

---

## 사용 문제

### 프리셋이 저장되지 않음
- **문제**: ReShade에 변경 사항을 저장할 권한이 없습니다.
- **해결책**:
  1. `reshade-presets` 폴더를 마우스 오른쪽 버튼으로 클릭하고 `속성` (`Properties`)을 선택합니다.
  2. `보안` (`Security`) 탭으로 이동하여 `Users`를 선택합니다.
  3. `편집` (`Edit`)을 클릭하고 `수정` (`Modify`) 권한을 확인(체크)합니다.
  4. `적용` (`Apply`)을 클릭하여 변경 사항을 저장합니다.

### 스크린샷에서 효과가 어긋나 있음
- **문제**: 해상도 스케일 설정이 호환되지 않습니다.
- **해결책**:
  - 다음 옵션을 비활성화하십시오:
    - `동적 해상도 활성화` (`Enable dynamic resolution`)
    - `암부 영역 보정` (`Limb Darkening`)
    - `피사계 심도 표현 활성화` (`Enable depth of field`)
  - `3D 해상도 스케일링` (`3D Resolution Scaling`)을 `100`으로 설정하고 `가장자리 다듬기` (`Edge Smoothing`)를 `FXAA` 또는 `끄기` (`Off`)로 설정하십시오.

### 빈 파일 또는 플레이스홀더 파일
- **설명**: `_x_gposingway_placeholder` Technique만 포함된 `zfast_crt.fx`와 같은 파일은 의도된 것입니다.
- **목적**: 이러한 플레이스홀더 파일은 서로 다른 셰이더 컬렉션 간의 Technique(기법) 충돌을 방지합니다.
- **해야 할 일**: 이러한 파일은 호환성을 위해 필수이므로 삭제하거나 수정하지 마세요.

---

## Q&A

### GPosingway는 어떻게 작동하나요?
GPosingway는 호환성과 안정성을 보장하기 위해 엄선된 셰이더, 텍스처 및 프리셋 컬렉션을 제공합니다. 이를 통해 누락된 파일이나 셰이더 충돌과 같은 일반적인 문제를 제거하여 프리셋이 의도한 대로 작동하도록 합니다.

### 기존 ReShade 설치와 함께 GPosingway를 사용할 수 있나요?
예, 하지만 GPosingway를 설치하기 전에 기존 `reshade-shaders` 및 `reshade-presets` 폴더의 이름을 바꾸는 것이 좋습니다. 이렇게 하면 두 설정 간에 충돌이 발생하지 않습니다.

### 모든 셰이더 컬렉션이 GPosingway에 포함되어 있나요?
아니요, [iMMERSE](https://github.com/martymcmodding/iMMERSE/blob/main/LICENSE)와 같은 일부 셰이더 컬렉션은 라이선스 제한으로 인해 재배포할 수 없습니다. 이러한 컬렉션은 별도로 다운로드해야 할 수 있습니다.

### GPosingway와 함께 모든 프리셋을 사용할 수 있나요?
예, 대부분의 프리셋은 추가 구성 없이 작동해야 합니다. GPosingway에는 필요한 셰이더가 이미 포함되어 있으므로 `.fx` 및 `.fxh` 파일을 복사하라는 지침은 무시하세요.

---

## 성능 문제

### 게임 실행 속도 저하
- **문제**: 셰이더로 인한 높은 리소스 사용량.
- **해결책**:
  - `Shift + F3`을 눌러 효과를 켜거나 끕니다.
  - 사용하지 않는 셰이더를 비활성화합니다.

---

## 추가 도움이 필요하다면
- **GitHub Issues**: [GitHub Issues](https://github.com/gposingway/gposingway/issues)를 통해 문제를 보고하거나 지원을 요청하세요.
- **Discord**: 커뮤니티 지원을 받으려면 [Sights of Eorzea Discord 서버](https://discord.com/servers/sights-of-eorzea-1124828911700811957)에 가입하세요. (참고: 서버는 주로 영어를 사용하지만, 다른 언어로 도움을 줄 수 있는 사용자가 있을 수 있습니다.)

---

## 중요 알림
- **파일 백업**: 도구를 설치하기 전에 항상 FFXIV 게임 파일을 백업하세요.
- **호환성**: ReShade와 GPosingway의 호환되는 버전을 사용하세요.
