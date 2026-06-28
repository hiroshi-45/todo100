# ユメツミ リリース提出チェックリスト

内部名「ゾン100」／ストア公開名「**ユメツミ**」。
収益化＝フリーミアム＋買い切りIAP（`yumetsumi_premium` 非消費型・¥600 リリース記念）。

> 最終更新: 2026-06-28 ／ まずは **Android（Google Play）** から提出する方針。

---

## 📊 進捗サマリ（2026-06-28 時点）

### ✅ 準備完了（素材・ビルド）
- [x] 署名鍵 `~/yumetsumi-upload.jks` 生成・`android/key.properties` 配置
- [x] 署名済みリリースAAB生成（`build/app/outputs/bundle/release/app-release.aab`／署名検証済み）
- [x] ストア掲載文（`STORE_LISTING.md`・文字数OK）
- [x] プライバシーポリシー公開（`https://hiroshi-45.github.io/todo100/docs/privacy.html`・HTTP 200確認済み）
- [x] スクリーンショット5枚（`store_screenshots/`・縦横比2:1=1080x2160に調整済み）
- [x] フィーチャーグラフィック（`store_assets/feature_graphic_1024x500.png`）
- [x] アイコン512px（`store_assets/play_icon_512.png`）
- [x] データセーフティ回答整理（すべて「収集なし」。`STORE_LISTING.md` 末尾参照）

### ⬜ 残タスク（＝あなた側のPlay Console操作。私が代行不可）
1. [ ] **Google Play デベロッパー登録（$25・一度きり）＋本人確認（身分証）**
2. [ ] 個人アカウントの公開要件＝**クローズドテスト テスター20人 × 14日間**（最短経路のため早めに開始）
3. [ ] アプリ作成（パッケージ名 `com.maruno.zom100`）
4. [ ] 掲載情報・スクショ・フィーチャーグラフィック・アイコンをアップロード（素材は上記に準備済み）
5. [ ] コンテンツレーティング アンケート
6. [ ] データセーフティ申告（「収集なし／外部送信なし／広告ID無し」）
7. [ ] IAP商品 `yumetsumi_premium`（管理対象/非消費型）¥600 を作成・有効化
8. [ ] ターゲットSDK/対象年齢/広告の有無（=広告なし）を申告
9. [ ] クローズドテストへAABをアップロード → 招待リンク配布 → 20人オプトイン → 14日後に本番申請

> ⚠️ **最重要バックアップ**: `~/yumetsumi-upload.jks` とパスワード（store/key 共通）・エイリアス `upload` を
> 別媒体（クラウド＋USB等）に必ず保管。紛失するとアプリを二度と更新できません。

### 📁 素材の保管場所（このリポジトリ内）
- スクショ: `store_screenshots/01〜05_*.png`
- フィーチャーグラフィック: `store_assets/feature_graphic_1024x500.png`
- Play用アイコン512px: `store_assets/play_icon_512.png`
- 掲載文（コピペ用）: `STORE_LISTING.md`

---

## 0. 共通の前提

- [x] ストア公開名は「**ユメツミ｜やりたいことリスト・人生のバケットリスト**」
      （※アプリ内/ランチャー表示名は「やりたい100」系のまま。ストア表示名はコンソールで別設定）
- [ ] ゾンビ作品（『ゾン100』小学館）の要素は名称・アイコン・説明文・スクショに一切使わない（提出物を再確認）
- [x] プライバシーポリシーを公開しURL確保（`.../todo100/docs/privacy.html`）
- [ ] バージョン: `pubspec.yaml` の `version` を確認（現 `1.0.0+1`）

---

## 1. Android（Google Play）

### 署名（完了）
- [x] アップロード鍵を生成（`keytool ... -alias upload`）
- [x] `android/key.properties` を作成（`.gitignore` 済み・コミットされない）
- [x] リリースAAB生成: `flutter build appbundle --release`
- [ ] パスワード・jksファイルをバックアップ（**未実施なら最優先**）
- [ ] Play App Signing を有効化（推奨。アップロード鍵とは別にGoogleが配布鍵を管理）

### Play Console（残タスク＝上記「残タスク」と同じ）
- [ ] アプリ作成、パッケージ名 `com.maruno.zom100`
- [ ] ストア掲載情報（タイトル/簡単な説明/詳しい説明）← `STORE_LISTING.md` からコピペ
- [ ] スクリーンショット（`store_screenshots/`）、アイコン512px、フィーチャーグラフィック1024x500
- [ ] コンテンツレーティング アンケート
- [ ] データセーフティ申告（写真＝端末内のみ／通知／外部送信なしを正しく記載）
- [ ] アプリ内商品: `yumetsumi_premium`（管理対象/非消費型）¥600 を作成・有効化
- [ ] ターゲットSDK/対象年齢/広告の有無（=広告なし）を申告

---

## 2. iOS（App Store）※Android公開後に着手予定

- [ ] Apple Developer Program 登録（年額 $99）
- [ ] App Store Connect でアプリ作成、Bundle ID `com.maruno.zom100` を登録
- [ ] Xcode で Team / 署名（自動署名 or 手動プロビジョニング）を設定
- [ ] `Info.plist` の写真利用説明文（`NSPhotoLibraryUsageDescription` 等）が用途に合っているか確認
- [ ] App内課金 `yumetsumi_premium`（非消費型）¥600 を作成、税・契約（Paid Apps契約）締結
- [ ] スクリーンショット（6.7型/6.5型など必須サイズ）、アイコン、プレビュー
- [ ] App Privacy（プライバシー）申告
- [ ] `flutter build ipa --release` → Transporter/Xcode でアップロード → TestFlight 確認

---

## 3. 実機での最終動作確認

- [ ] 課金フロー（購入→100個解放→テーマ解放）／「購入を復元する」
- [ ] 写真の追加・達成記録・シェア画像書き出し
- [ ] ローカル通知（許可ダイアログ→指定時刻に発火→端末再起動後も維持）
- [ ] バックアップ書き出し／読み込み（zip）
- [ ] ダークモード表示

---

## 4. 既知の留意点

- 領収書のサーバー検証なし（クライアント信頼モデル）。低単価買い切りのため許容するが認識しておく。
- クラウドバックアップ未実装（ローカルのみ＝機種変で消失）。将来の年額サブスク候補。
- `flutter analyze` はディレクトリ名「ゾン100」(日本語) でLSPがクラッシュする既知のツール問題。
  必要なら英数字パスにcloneして実行するか、リリースをユメツミ等の英数字ディレクトリへ移すと解消。
- GitHub Pages のソースは「root」設定のため、`docs/privacy.html` は `.../todo100/docs/privacy.html` で公開される
  （`/docs/` なしのURLは404。掲載文・申告では必ず `/docs/` 付きを使う）。
