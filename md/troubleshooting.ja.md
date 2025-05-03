# GPosingway トラブルシューティングガイド

<div align="right">
  <b>このドキュメントを読む:</b>
  <a href="./troubleshooting.md">English</a> | 
  <b>日本語</b> | 
  <a href="./troubleshooting.ko.md">한국어</a> 
</div>

---

GPosingwayで問題が発生しましたか？ このガイドを使用して、一般的な問題を解決してください。

---

## インストールの問題

### 権限エラー (Permissions Error)
- **問題**: インストールスクリプトにファイルを変更する権限がありません。
- **解決策**:
  1. `game` フォルダを右クリックし、`プロパティ` (`Properties`) を選択します。
  2. `セキュリティ` (`Security`) タブに移動し、`Users` を選択します。
  3. `編集` (`Edit`) をクリックし、`変更` (`Modify`) の権限を確認（チェック）します。
  4. `適用` (`Apply`) をクリックして変更を保存します。

### GPosingwayが機能しない (GPosingway Not Working)
- **問題**: 不適切なインストールまたはバージョンの不一致。
- **解決策**:
  - 使用しているReShadeバージョンに対応する正しいGPosingwayバージョンがインストールされていることを確認してください。
  - インストーラースクリプトまたは展開したファイルを直接 `game` フォルダに配置してください。
  - 競合を避けるために、古いシェーダー (`reshade-shaders`) およびプリセット (`reshade-presets`) フォルダの名前を変更してください。

### エラーメッセージ (Error Messages)
- **問題**: 他のMODとの競合またはファイルが見つからない。
- **解決策**:
  - 特にDalamudなど、他のMODとの競合を確認してください。
  - `dxgi.log` ファイルを削除し、ゲームを再起動してください。

---

## 使用上の問題

### プリセットが保存されない (Presets Not Saving)
- **問題**: ReShadeに変更を保存する権限がありません。
- **解決策**:
  1. `reshade-presets` フォルダを右クリックし、`プロパティ` (`Properties`) を選択します。
  2. `セキュリティ` (`Security`) タブに移動し、`Users` を選択します。
  3. `編集` (`Edit`) をクリックし、`変更` (`Modify`) の権限を確認（チェック）します。
  4. `適用` (`Apply`) をクリックして変更を保存します。

### スクリーンショットでエフェクトがずれる (Misaligned Effects in Screenshots)
- **問題**: 互換性のない解像度スケーリング設定。
- **解決策**:
  - 以下のオプションを無効にしてください:
    - `キャラクターライティング` (`Enable dynamic resolution`)
    - `リムライト` (`Limb Darkening`)
    - `被写界深度表現` (`Enable depth of field`)
  - `3D解像度スケール` (`3D Resolution Scaling`) を `100` に設定し、`アンチエイリアス` (`Edge Smoothing`) を `FXAA` または `オフ` (`Off`) に設定してください。

### 空またはプレースホルダーファイル (Empty or Placeholder Files)
- **理解**: `zfast_crt.fx` のように `_x_gposingway_placeholder` technique のみを含むファイルは意図的なものです。
- **目的**: これらのプレースホルダーファイルは、異なるシェーダーコレクション間の technique 競合を防ぎます。
- **対処法**: これらのファイルは互換性のために不可欠なため、削除したり変更したりしないでください。

---

## Q&A

### GPosingwayはどのように機能しますか？
GPosingwayは、互換性と安定性を確保するために、厳選されたシェーダー、テクスチャ、プリセットのコレクションを提供します。これにより、ファイルが見つからない、シェーダーの競合といった一般的な問題が解消され、プリセットが意図したとおりに機能するようになります。

### 既存のReShadeインストールでGPosingwayを使用できますか？
はい、可能ですが、GPosingwayをインストールする前に、既存の `reshade-shaders` および `reshade-presets` フォルダの名前を変更することをお勧めします。これにより、2つのセットアップ間で競合が発生しないようにします。

### すべてのシェーダーコレクションがGPosingwayに含まれていますか？
いいえ、[iMMERSE](https://github.com/martymcmodding/iMMERSE/blob/main/LICENSE) のような一部のシェーダーコレクションは、ライセンス制限のため再配布できません。これらは別途ダウンロードする必要がある場合があります。

### GPosingwayで任意のプリセットを使用できますか？
はい、ほとんどのプリセットは追加設定なしで機能するはずです。GPosingwayには必要なシェーダーがすでに含まれているため、`.fx` および `.fxh` ファイルをコピーするように指示する手順は無視してください。

---

## パフォーマンスの問題

### ゲームの動作が遅い (Game Running Slowly)
- **問題**: シェーダーによる高いリソース使用量。
- **解決策**:
  - `Shift + F3` を押してエフェクトを切り替えます。
  - 未使用のシェーダーを無効にします。

---

## さらにサポートが必要な場合 (Need More Help?)
- **GitHub Issues**: [GitHub Issues](https://github.com/gposingway/gposingway/issues) を通じて問題を報告したり、サポートをリクエストしたりしてください。
- **Discord**: コミュニティサポートについては [Sights of Eorzea Discord サーバー](https://discord.com/servers/sights-of-eorzea-1124828911700811957) に参加してください。(注意: サーバーは主に英語ベースですが、他の言語でサポートを提供できるユーザーがいる場合もあります。)

---

## 重要事項 (Important Reminders)
- **ファイルのバックアップ**: ツールをインストールする前に、必ずFFXIVゲームファイルをバックアップしてください。
- **互換性**: ReShadeとGPosingwayの互換性のあるバージョンを使用してください。
