# ビジュアルガイド：GPosingway向けReShadeインストール

<div align="right">
  <b>このドキュメントを読む:</b>
  <a href="./reshade_installation.md">English</a> | 
  <b>日本語</b> | 
  <a href="./reshade_installation.ko.md">한국어</a> 
</div>

---

## ReShadeのダウンロード

> [!NOTE]
> ReShadeは、[作者によるこの投稿で示されているように](https://reshade.me/forum/general-discussion/2207-older-versions)、すべてのバージョンのリポジトリとしてMediaFireを使用しています。

[ReShadeの公式サイト](https://reshade.me/)から、[アドオンサポート付きのReShade 6.1.0インストーラー](https://www.mediafire.com/file/idoy853fmll52h1/ReShade_Setup_6.1.1_Addon.exe/file)をダウンロードしてください。公式サイトでは「～with full add-on support」を選択することが重要です。

## ReShadeのインストール

ダウンロードしたファイルを実行します。実行時にWindows SmartScreenの保護が発動する場合があります：

> **Windows SmartScreen メッセージ:**
> ```
> Windows によってPCが保護されました
> Windows Defender SmartScreen により、認識されないアプリの起動が防止されました。このアプリを実行すると、PCに問題が起こる可能性があります。
> ```
> 
> 「詳細情報」をクリックし、「実行」ボタンを選択してください。

警告ダイアログが表示される場合は「OK」を押下します：

> **ReShade 警告メッセージ:**
> ```
> ReShade is intended for single-player games only. Use in online games may be considered cheating and could result in permanent bans. Use at your own risk.
> ```
> 
> この警告は「シングルプレイゲームでの利用が意図されており、マルチプレイゲームで利用してBANされても自己責任です」という内容です。

<img src='https://github.com/gposingway/gposingway/assets/18711130/6a57b0d1-5684-441b-94b3-01254d38095a' alt='ReShadeインストーラーの起動画面（SmartScreen警告例）' width='408' /><br/><br/>

`Browse...` ボタンをクリックし、`game` ディレクトリ下の `ffxiv_dx11.exe` ファイルを見つけて `Open` をクリックします。

> **ファイル選択画面:**
> ```
> Select the application you wish to use ReShade with
> 
> アプリケーション: [Browse...]
> 
> ファイルの種類: Executable files (*.exe)
> ```

デフォルトのインストール先の場合、ファイルは以下の場所にあります：
`C:\Program Files (x86)\SquareEnix\FINAL FANTASY XIV - A Realm Reborn\game\ffxiv_dx11.exe`

<img src='https://github.com/gposingway/gposingway/assets/18711130/433815f2-3648-4efd-b8c3-18786bd1a657' alt='ReShadeでFFXIV実行ファイルを選択する画面' width='408' /><br/><br/>

ゲームファイルが正しく選択されていることを確認し、`Next` をクリックします：  
<img src='https://github.com/gposingway/gposingway/assets/18711130/8d8062b8-cbe4-4d9c-bcaf-c252c20d2faf' alt='ReShadeでゲームファイル選択後の確認画面' width='408' /><br/><br/>

希望するレンダリングAPIを選択します（Windows 10/11ユーザーの場合、通常はDirectX 10/11/12を選択します）。選択後、`Next` をクリックします：

> **レンダリングAPI選択画面:**
> ```
> Select the rendering API
> 
> ○ Direct3D 9
> ● Direct3D 10/11/12  ← 推奨
> ○ OpenGL
> ○ Vulkan
> ```

<img src='https://github.com/gposingway/gposingway/assets/18711130/45358023-2100-455c-9619-7c04f5487b4d' alt='レンダリングAPI選択画面（DirectX 10/11/12推奨）' width='408' /><br/><br/>

エフェクトパッケージの選択画面では、すべてのチェックを外すために `Uncheck All` をクリックし、その後 `Next` をクリックします：

> **プリセット選択画面:**
> ```
> Select preset to install
> 
> [Uncheck All] [Check All]
> 
> □ Standard effects
> □ Additional effects
> □ Legacy effects
> ```

<img src='https://github.com/gposingway/gposingway/assets/18711130/c458f994-5b5e-495f-9c4e-04122a63b4a6' alt='エフェクトプリセット選択画面（Uncheck All推奨）' width='408' /><br/><br/>

`Select effect packages to install` ウィンドウでも、`Uncheck All` をクリックしてから `Next` をクリックします：

> **エフェクトパッケージ選択画面:**
> ```
> Select effect packages to install
> 
> [Uncheck All] [Check All]
> 
> □ Standard effects (ReShade)
> □ SweetFX
> □ Legacy effects
> □ OtisFX
> ```  
<img src='https://github.com/gposingway/gposingway/assets/18711130/0ff6a3ae-32f4-408a-935a-db9c8d30fb89' alt='エフェクトパッケージ選択画面（Uncheck All推奨）' width='408' /><br/><br/>

ダウンロード、展開、インストールが開始されます。しばらくお待ちください。

> **インストール進行画面:**
> ```
> Installing ReShade...
> 
> Downloading effects...  [████████████████████] 100%
> Extracting files...     [████████████████████] 100%
> Setting up ReShade...   [████████████████████] 100%
> ```

インストールアドオンの選択画面が表示された場合は、必要に応じて `ReshadeEffectShaderToggler` を選択してください。

> **アドオン選択画面:**
> ```
> Select add-ons to install (optional)
> 
> □ ReshadeEffectShaderToggler  ← 推奨
> □ Other available add-ons
> ```

`Finish` をクリックします。これでゲーム内でReShadeを実行する準備ができました。

> **インストール完了画面:**
> ```
> ReShade has been successfully installed!
> 
> The ReShade overlay will appear when you start your game.
> Press [Home] to open the ReShade configuration menu.
> 
> [Finish]
> ```  
<img src='https://github.com/gposingway/gposingway/assets/18711130/9ab2bf1f-a809-4130-aea7-0f767e8dbe84' alt='ReShadeインストール完了画面（Finishボタン）' width='408' />
