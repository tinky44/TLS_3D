# プロジェクト仕様書 (spec.md)

本ドキュメントは、**Tall Life Simulator** の現在の実装状況および技術仕様を定義しますわ。

## 📍 ファイル構成クイックリファレンス
AIの皆様、迷った際はこちらを参照してくださいませ。
- **身体描画（オーケストラ）**: [CharacterDrawer.gd](../godot-project/scripts/CharacterDrawer.gd), [DrawContext.gd](../godot-project/scripts/DrawContext.gd)
- **身体描画（正面・側面）**: [CharacterDrawFront.gd](../godot-project/scripts/CharacterDrawFront.gd), [CharacterDrawSide.gd](../godot-project/scripts/CharacterDrawSide.gd)
- **身体描画（パーツ別）**: [CharacterHairDrawer.gd](../godot-project/scripts/CharacterHairDrawer.gd), [CharacterBodyDrawer.gd](../godot-project/scripts/CharacterBodyDrawer.gd), [CharacterClothingDrawer.gd](../godot-project/scripts/CharacterClothingDrawer.gd), [hair_drawing_system.md](hair_drawing_system.md)
- **プレイヤー操作・屈み**: [SkeletalPlayer.gd](../godot-project/scripts/SkeletalPlayer.gd), [CharacterPoseCalculator.gd](../godot-project/scripts/CharacterPoseCalculator.gd)
- **NPC反応**: [SkeletalNPC.gd](../godot-project/scripts/SkeletalNPC.gd)
- **ステージ構築**: [StageBuilder.gd](../godot-project/scripts/StageBuilder.gd), [stage_design.md](stage_design.md)
- **データ管理**: [Global.gd](../godot-project/scripts/Global.gd)

---

## 1. プロジェクト概要
高身長の主人公が、その体格ゆえに遭遇する日常の「摩擦」や「視線」、そして成長に伴う世界の小型化を体験する2D高身長シミュレーターですわ。

## 2. コアシステム仕様

### 2.1. 身体描画・ポーズシステム
- **主要ファイル**: `CharacterDrawer.gd`（オーケストラ）, `CharacterDrawUtils.gd`（描画ユーティリティ）
- **詳細仕様**: [character_drawing_system.md](specs/character_drawing_system.md), [hair_drawing_system.md](specs/hair_drawing_system.md)
- **概要**: `Global.gd` の身体パラメータ（身長、頭身、股下比率）に基づき、各パーツの座標をリアルタイム計算。
- **多角的描画**: 正面・背面・側面の3視点をサポート。
  - 服装、髪型のレイヤー管理。詳細は [clothing_and_hair_logic.md](specs/clothing_and_hair_logic.md) を参照。
- **描画サブシステム構成**（2026-03-10 リファクタリング済み）:

  | ファイル | 役割 |
  |---|---|
  | `DrawContext.gd` | 描画に必要な全状態を保持する共有コンテキスト（`RefCounted`）。引数チェーンを排除 |
  | `CharacterDrawFront.gd` | 正面・背面ビューの描画ロジック（`static func draw(ctx)`） |
  | `CharacterDrawSide.gd` | 側面ビューの描画ロジック（`static func draw(ctx)`） |
  | `CharacterHairDrawer.gd` | 髪型描画（前髪・後ろ髪・サイドヘア、正面・側面・背面対応） |
  | `CharacterBodyDrawer.gd` | 腕（袖付き）・脚（パンツ付き）・スカート描画 |
  | `CharacterClothingDrawer.gd` | 服装オーバーレイ（セーラー・ブレザー・リボン・ジャンパースカート） |

### 2.2. 物理干渉・屈みシステム
- **主要ファイル**: `SkeletalPlayer.gd`, `CharacterPoseCalculator.gd`
- **自動屈み (Auto-Crouch)**:
  - 頭上のレイキャスト（センサー）により障害物を検知。
  - `CharacterPoseCalculator.gd` による二段階の屈み（背を丸める ⇔ 膝を曲げる）を二分探索で最適化。
- **頭の衝突 (Head Bump)**: 屈みが不十分な状態での衝突検知と演出。

### 2.3. 多段階NPCリアクションシステム
- **主要ファイル**: `SkeletalNPC.gd`
- **概要**: プレイヤーとの身長差をリアルタイムに判定。

| 身長差(Player - NPC) | 反応キー | セリフ例 | 特殊挙動 |
| :--- | :--- | :--- | :--- |
| **+60cm 以上** | `very_huge` | 「でかっ…！」 | **全力で後退/回避** |
| **+35cm 以上** | `huge` | 「見上げちゃう」 | **緩やかに後退/回避** |
| **+15cm 以上** | `tall` | 「背、高いな」 | 特になし |
| **-15cm 以下** | `shorter` | 「今日は私の方が高い」 | 特になし |
| **それ以外** | `same` | (無言) | 特になし |

- **視線同期**: NPCが頭の角度（`look_head_angle`）を動的に変えてプレイヤーを見る。

### 2.4. 成長・ライフサイクル
- **主要ファイル**: `Global.gd`, `MainScene.gd`
- **身体測定**: 保健室の身長計で学期進行（詳細は [spec.local.md](specs/spec.local.md) のメモ参照）。
- **成長ロジック**: 年齢に応じた成長速度の変化と履歴保存。

## 3. ステージ構成
- **主要ファイル**: `StageBuilder.gd`
- **詳細仕様**: [stage_design.md](specs/stage_design.md), [room_stage_objects.md](specs/room_stage_objects.md)
- **構成**: 家(room), 駅(station), 屋外(outdoor), 学校(school)等。各オブジェクトの干渉判定を定義。

## 4. 技術仕様
- **エンジン**: Godot Engine 4.x
- **座標系**: 1cm = 2.0px (`CM_TO_PX`)
- **描画方式**: `_draw()` 関数による動的ポリゴン（スプライト未使用）。
- **データ保存**: JSON形式によるスロットセーブ (`user://save_slot_N.json`)。

---
*Co-Authored-By: gemini <218195315+gemini-cli@users.noreply.github.com>*
