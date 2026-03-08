# Tall Life Simulator (トールライフシミュレーター)

[![Play Now!](https://img.shields.io/badge/Play-Web_Version-green?style=for-the-badge&logo=godotengine)](https://tinky44.github.io/tall_life_simulator/)

## 概要

**Tall Life Simulator** は、高身長な人物が体験する「独自の視点」と「日常の工夫」を追体験する、Godot製のライフシミュレーターです。
100cmから240cmを超える極端な身長差まで、環境や周囲のNPCとのインタラクションを通じて、スケール感の違いを楽しむことができます。

🌐 **[ブラウザで今すぐプレイする](https://tinky44.github.io/tall_life_simulator/)**

## 主な機能

### 📏 リアルな身体シミュレーション
- **動的プロポーション**: 7頭身、8頭身、脚の長さなど、詳細なパラメータでキャラクターを作成。
- **自動屈みアクション**: 天井の低い場所や電車のつり革に対し、頭がぶつからないよう自然にかがみ込む動作をシミュレート。

### 🏫 成長と時間の流れ
- **保健室での測定**: 学期ごとに身長を測定し、自分の成長を記録。
- **成長曲線**: 年齢に応じて成長速度が変化。平均身長と比較して「いかに自分が大きいか（あるいは小さいか）」を実感できます。
- **学年による変化**: 成長に合わせて、教室の机の高さや環境が変化していきます。

### 🌏 広がる世界
- **多様なステージ**: 自宅、学校（教室・廊下・校庭・保健室）、駅、電車内、屋外など、多数のステージを実装。
- **NPCとの比較**: クラスメイトや教師、通行人など、周囲の人々の視線や反応をリアルタイムに体験。

## スクリーンショット / デモ
*(※最新のプレイ映像は開発の進捗に合わせて順次公開されます)*

## 開発環境
- **Engine**: Godot Engine 4.x
- **Language**: GDScript
- **Architecture**: Gemini AI とのペアプログラミングによる AI 駆動開発

## ローカルでの実行方法
1. リポジトリをクローンします
   ```bash
   git clone https://github.com/tinky44/tall_life_simulator.git
   ```
2. Godot Engine 4.x を起動します
3. `godot-project/project.godot` をインポートして開きます
4. 「▶ 再生」ボタンを押して実行してください

## ドキュメント
- [詳細仕様書 (spec.md)](specs/spec.md)
- [開発用メモ (GEMINI.md)](GEMINI.md)
