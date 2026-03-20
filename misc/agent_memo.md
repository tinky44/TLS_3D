# AIエージェントメモ — TLS_3D

## 2026-03-20: 3D化プロジェクト開始

### 状況
- `TLS_3D` リポジトリで3D版を独立開発する方針が決定
- 既存の2D版 (`tall_life_simulator`) のゲームロジック・データを最大限流用
- エンジンは Godot 4.x（Forward+レンダラー）

### 重要な判断
1. **Global.gd, DialogueDatabase.gd, AchievementDatabase.gd はそのまま流用**
   - これらは描画レイヤーに依存しないため、2D→3Dでも変更不要
2. **StageBuilder.gd の STAGES 辞書はデータとして流用**
   - 各ステージの幅・天井高・障害物定義は3Dでもそのまま使える
   - 描画部分だけ StageBuilder3D.gd として新規作成
3. **スケール換算は CM_TO_UNIT = 0.01 に統一**
   - Godot標準の 1ユニット = 1m に合わせる
   - 既存の CM_TO_PX (= 2.0) とは別概念

### 次にやること
- Phase 0 の残りタスク（project.godot設定、スケルトンシーン作成）
- Phase 1 の最小動作プロトタイプ（myroom を3Dで歩ける状態）
