# GPosingway インストールガイド

<div align="right">
  <b>このドキュメントを読む:</b>
  <a href="./installation_guide.md">English</a> | 
  <b>日本語</b> | 
  <a href="./installation_guide.ko.md">한국어</a> 
</div>

---

GPosingwayは、強力なポストプロセッシングツールであるReShadeによって動作します。開始するには、まずReShadeをインストールし、次にGPosingwayをインストールする必要があります。以下の手順に従って環境を設定してください。

---

## ReShadeのインストール

### 一般的な手順
1. **インストーラーのダウンロード**:
    - [ReShadeウェブサイト](https://reshade.me)にアクセスするか、[MediaFireリポジトリ](https://www.mediafire.com/folder/reshade_versions)を使用して、アドオンサポート付きの最新バージョンのReShadeをダウンロードします。

2. **インストーラーの実行**:
    - ReShadeインストーラーを起動し、`Browse...`をクリックします。  
        ![Browse Button](https://github.com/gposingway/gposingway/assets/18711130/6a57b0d1-5684-441b-94b3-01254d38095a)
    - `game`フォルダ内の`ffxiv_dx11.exe`ファイルを見つけて、`Open`をクリックします。  
        ![Select Game File](https://github.com/gposingway/gposingway/assets/18711130/433815f2-3648-4efd-b8c3-18786bd1a657)

3. **レンダリングAPIの選択**:
    - 適切なレンダリングAPIを選択します（ほとんどのユーザーはDirectX 10/11/12）。  
        ![Rendering API](https://github.com/gposingway/gposingway/assets/18711130/45358023-2100-455c-9619-7c04f5487b4d)

4. **オプション手順のスキップ**:
    - `Select preset to install` および `Select effect packages to install` ウィンドウで、`Skip`をクリックします。  
        ![Skip Preset](https://github.com/gposingway/gposingway/assets/18711130/c458f994-5b5e-495f-9c4e-04122a63b4a6)
        ![Skip Effects](https://github.com/gposingway/gposingway/assets/18711130/0ff6a3ae-32f4-408a-935a-db9c8d30fb89)

5. **インストールの完了**:
    - `Finish`をクリックしてセットアップを完了します。  
        ![Finish Installation](https://github.com/gposingway/gposingway/assets/18711130/9ab2bf1f-a809-4130-aea7-0f767e8dbe84)

### 注意事項
- ReShadeバージョンとGPosingwayの互換性を確認してください。  
- 問題が発生した場合は、[トラブルシューティングガイド](troubleshooting.ja.md)を参照してください。

---

## GPosingwayのインストール

### 手動インストール
1. **パッケージの展開**:
    - ダウンロードしたGPosingwayパッケージを右クリックし、`すべて展開...` (`Extract All...`) を選択します。  
        ![Extract All](https://github.com/gposingway/gposingway/assets/18711130/7968f27b-f5b5-4c1c-ba07-5911a8f7a79e)
    - ダイアログボックスで`展開` (`Extract`) をクリックします。  
        ![Extract Button](https://github.com/gposingway/gposingway/assets/18711130/7d3c3978-355e-4b0e-9a74-c64ab2318f65)

2. **ファイルのコピー**:
    - 展開されたパッケージからすべてのファイルとフォルダを、FFXIVのインストール先の`game`フォルダ（例: `SquareEnix\FINAL FANTASY XIV - A Realm Reborn\game`）にコピーします。  
        ![Copy Files](https://github.com/gposingway/gposingway/assets/18711130/5654b154-4599-4623-94f2-d177c5668a18)

3. **インストールの確認**:
    - ゲームを起動します。起動時にGPosingwayの説明が表示されれば、インストールは成功です。  
        ![Startup Instructions](https://github.com/gposingway/gposingway/assets/18711130/65ef0e5f-f49e-4903-9105-acd9bb9c41e9)

### インストーラーの使用
1. **インストーラーの準備**:
    - `gposingway-update.bat`ファイルをFFXIVのインストール先の`game`フォルダにコピーします。  
        ![Installer File](https://github.com/gposingway/gposingway/assets/18711130/ab2da9d6-bf6c-4c15-bf44-20a8ddae69a1)

2. **インストーラーの実行**:
    - `gposingway-update.bat`をダブルクリックします。  
        ![Run Installer](https://github.com/gposingway/gposingway/assets/18711130/9cf1ac93-20b7-41f3-b17e-4e44babb59fc)
    - Windows Defenderによってプロンプトが表示された場合は、`詳細情報` (`More Info`) をクリックし、次に `実行` (`Run Anyway`) をクリックします。  
        ![Run Anyway](https://github.com/gposingway/gposingway/assets/18711130/a47d0795-caa3-4a7e-a9f8-75d7b2d8961e)
    - 画面の指示に従ってインストールを完了します。  
        ![Installer Instructions](https://github.com/gposingway/gposingway/assets/18711130/57dbca2b-be15-4e7a-af70-ec97fbe3e03a)

3. **GPosingwayの更新**:
    - 更新するには、`gposingway-update.bat`を再度実行します。インストーラーがインストールをパッチします。
        ![Update Installer](https://github.com/gposingway/gposingway/assets/18711130/6dc7431a-9793-46b3-9889-434b645bac8e)

---

## 追加リソース
- [GPosingway GitHub リポジトリ](https://github.com/gposingway/gposingway)
- [Sights of Eorzea Discord サーバー](https://discord.com/servers/sights-of-eorzea-1124828911700811957) (注意: サーバーは主に英語ベースですが、他の言語でサポートを提供できるユーザーがいる場合もあります。)
