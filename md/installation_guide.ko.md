# GPosingway 설치 가이드

GPosingway는 강력한 후처리 도구인 ReShade로 구동됩니다. 시작하려면 먼저 ReShade를 설치한 다음 GPosingway를 설치해야 합니다. 아래 단계에 따라 환경을 설정하십시오.

---

## ReShade 설치

### 일반 단계
1. **설치 프로그램 다운로드**:
    - [ReShade 웹사이트](https://reshade.me)를 방문하거나 [MediaFire 리포지토리](https://www.mediafire.com/folder/reshade_versions)를 사용하여 애드온 지원이 포함된 최신 버전의 ReShade를 다운로드합니다.

2. **설치 프로그램 실행**:
    - ReShade 설치 프로그램을 실행하고 `Browse...`를 클릭합니다.
        ![Browse Button](https://github.com/gposingway/gposingway/assets/18711130/6a57b0d1-5684-441b-94b3-01254d38095a)
    - `game` 폴더에서 `ffxiv_dx11.exe` 파일을 찾아 `Open`을 클릭합니다.
        ![Select Game File](https://github.com/gposingway/gposingway/assets/18711130/433815f2-3648-4efd-b8c3-18786bd1a657)

3. **렌더링 API 선택**:
    - 적절한 렌더링 API를 선택합니다 (대부분의 사용자는 DirectX 10/11/12).
        ![Rendering API](https://github.com/gposingway/gposingway/assets/18711130/45358023-2100-455c-9619-7c04f5487b4d)

4. **선택적 단계 건너뛰기**:
    - `Select preset to install` 및 `Select effect packages to install` 창에서 `Skip`을 클릭합니다.  
        ![Skip Preset](https://github.com/gposingway/gposingway/assets/18711130/c458f994-5b5e-495f-9c4e-04122a63b4a6)  
        ![Skip Effects](https://github.com/gposingway/gposingway/assets/18711130/0ff6a3ae-32f4-408a-935a-db9c8d30fb89)

5. **설치 완료**:
    - `Finish`를 클릭하여 설정을 완료합니다.  
        ![Finish Installation](https://github.com/gposingway/gposingway/assets/18711130/9ab2bf1f-a809-4130-aea7-0f767e8dbe84)

### 참고 사항
- ReShade 버전과 GPosingway 간의 호환성을 확인하십시오.  
- 문제가 발생하면 [문제 해결 가이드](troubleshooting.ko.md)를 참조하십시오.

---

## GPosingway 설치

### 수동 설치
1. **패키지 압축 해제**:
    - 다운로드한 GPosingway 패키지를 마우스 오른쪽 버튼으로 클릭하고 `압축 풀기...` (`Extract All...`)를 선택합니다.  
        ![Extract All](https://github.com/gposingway/gposingway/assets/18711130/7968f27b-f5b5-4c1c-ba07-5911a8f7a79e)
    - 대화 상자에서 `압축 풀기` (`Extract`)를 클릭합니다.  
        ![Extract Button](https://github.com/gposingway/gposingway/assets/18711130/7d3c3978-355e-4b0e-9a74-c64ab2318f65)

2. **파일 복사**:
    - 압축 해제된 패키지의 모든 파일과 폴더를 FFXIV 설치 경로의 `game` 폴더(예: `SquareEnix\FINAL FANTASY XIV - A Realm Reborn\game`)로 복사합니다.  
        ![Copy Files](https://github.com/gposingway/gposingway/assets/18711130/5654b154-4599-4623-94f2-d177c5668a18)

3. **설치 확인**:
    - 게임을 실행합니다. 시작 시 GPosingway 안내가 표시되면 설치가 성공한 것입니다.  
        ![Startup Instructions](https://github.com/gposingway/gposingway/assets/18711130/65ef0e5f-f49e-4903-9105-acd9bb9c41e9)

### 설치 프로그램 사용
1. **설치 프로그램 준비**:
    - `gposingway-update.bat` 파일을 FFXIV 설치 경로의 `game` 폴더로 복사합니다.  
        ![Installer File](https://github.com/gposingway/gposingway/assets/18711130/ab2da9d6-bf6c-4c15-bf44-20a8ddae69a1)

2. **설치 프로그램 실행**:
    - `gposingway-update.bat`를 더블 클릭합니다.  
        ![Run Installer](https://github.com/gposingway/gposingway/assets/18711130/9cf1ac93-20b7-41f3-b17e-4e44babb59fc)
    - Windows Defender 메시지가 나타나면 `추가 정보` (`More Info`)를 클릭한 다음 `실행` (`Run Anyway`)을 클릭합니다.  
        ![Run Anyway](https://github.com/gposingway/gposingway/assets/18711130/a47d0795-caa3-4a7e-a9f8-75d7b2d8961e)
    - 화면의 지침에 따라 설치를 완료합니다.  
        ![Installer Instructions](https://github.com/gposingway/gposingway/assets/18711130/57dbca2b-be15-4e7a-af70-ec97fbe3e03a)

3. **GPosingway 업데이트**:
    - 업데이트하려면 `gposingway-update.bat`를 다시 실행합니다. 설치 프로그램이 설치를 패치합니다.  
        ![Update Installer](https://github.com/gposingway/gposingway/assets/18711130/6dc7431a-9793-46b3-9889-434b645bac8e)

---

## 추가 리소스
- [GPosingway GitHub 리포지토리](https://github.com/gposingway/gposingway)
- [Sights of Eorzea Discord 서버](https://discord.com/servers/sights-of-eorzea-1124828911700811957) (참고: 서버는 주로 영어를 사용하지만, 다른 언어로 도움을 줄 수 있는 사용자가 있을 수 있습니다.)
