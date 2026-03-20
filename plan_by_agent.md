# plan_by_agent.md — AI エージェントメモ

## 最終更新: 2026-03-20

---

## 実施済み実装（3エージェントチーム）

### NPC3D.gd
- 腕・脚のシリンダーメッシュをピボット付きで動的生成（`_build_limbs()`）
- sin波による歩行アニメーション（`_update_walk_animation()`）
- body_mesh を胴体専用に変更（height * 0.40、腰から上に配置）

### Player3D.gd
- 三人称カメラ切替（Rキー、`_toggle_camera_mode()`）
- ThirdPersonCamera の初期化（`get_node_or_null("ThirdPersonCamera")`）
- 頭ぶつけ時のFOVパルス演出（95→75、Elastic補間）

### Player3D.tscn
- ThirdPersonCamera ノード追加（Vector3(0, 0.5, 2.2)、Y180°・X-8°）

### MainScene3D.gd
- BumpFlashRect（赤フラッシュ用ColorRect、z_index=50）
- 頭ぶつけ初回判定（`_bumped_obstacles` で管理）
- 成長演出（5cm閾値で身長ポップアップ + FOVパルス）

---

## 次回の候補タスク
- NPC の巡回歩行（NavigationServer3D 導入）
- 鏡ギミックの3D実装
- 衣装色の3Dモデル反映
