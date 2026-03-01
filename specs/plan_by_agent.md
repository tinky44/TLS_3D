# AI 検討メモ (plan_by_agent)

このファイルはAIがアイデアや実装計画、既存コードの分析結果を書き溜めるためのメモ帳です。

## 前回実装 (`grep_simulator`) の分析結果
`app/src/character.ts` と `app/src/game.ts` を解析しました。

### 1. 姿勢制御と物理計算 (Canvas時代)
- **前方運動学と二分探索**: 腰から曲がり、一定角度(約40度)から膝も曲がり始める数式モデル(t=0.0〜2.0)を使用。目標の頭頂高さ(`targetCrouchHeight`)になるような `t` を**二分探索**で逆算して姿勢を決定していました。
- **衝突判定用高さ**: 描画上の計算とは別に、物理的な判定用高さ `currentTop` を明確に管理（しゃがみはデフォルト身長の65%、かがみは80%か障害物高さ-2cm）。

### 2. Auto-Crouch (自動屈み) の仕組み
- 毎フレーム、進行方向前方（40cm先まで）にある「頭上障害物」のX座標と高さをチェック。
- 自身の頭頂の高さが障害物より高い場合、`shouldCrouch = true` となり、目標の屈み高さを衝突ギリギリ(`minObstacleHeight - 2`)に設定。

---

## Godot 2D への移植アイディア (アーキテクチャ設計)

Godotのノードシステムと強力な物理エンジンに合わせて、以下のような構成を提案します。今回は2Dということで、サイドスクロールまたはトップダウンのどちらにも対応できる形を考慮しますが、主にサイドスクロールベースの横からの視点を想定します。

### ノード構成案 (`CharacterBody2D` ベース)
- **Player (CharacterBody2D)**
  - `CollisionShape2D` (メインの当たり判定。カプセルまたは矩形)
  - `Sprite2D` または `Skeleton2D` / `Polygon2D` (描画用。Canvasのようにコードで計算して描くか、ボーンアニメーションを使用)
  - `RayCast2D` (前方障害物検知用: HeadForwardCast)
  - `RayCast2D` (頭上検知用: CeilingCast)

### 屈みシステムのGodot的アプローチ
1. **マニュアル屈み (`pose == crouch/squat`)**
   - 屈みボタン押下時、`CollisionShape2D` の `shape.height` (または `extents.y`) をTweenで滑らかに小さくする。
   - 同時にビジュアル（SpriteのスケールYの縮小、またはアニメーションの再生）もTweenで変化させる。
2. **自動屈み機能 (Auto-Crouch)**
   - 前方上部に向けて `RayCast2D` (`HeadForwardCast`) を飛ばす（例：長さ40px）。
   - RayCastが障害物にヒットした場合、そのヒット地点のY座標（高さ）を取得し、自キャラの目標高さを計算。
   - `CollisionShape2D` の高さを動的（Tween等）にターゲット高さへ遷移させる。
3. **立ち上がり防止 (Ceiling Detection)**
   - 屈み状態から立ち上がる際、頭上へ向けて `RayCast2D` (`CeilingCast`) を飛ばす。
   - 真上に障害物がある間は、ボタンを離しても（あるいは前方の障害物がなくなっても）立ち上がれないように制御する。

これで、Canvas時代の手動計算に頼らず、Godotの物理RayCastを用いたより堅牢でアクション性の高い屈みシステムが実現できます！
