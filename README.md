# Tall Life Simulator

[![Play Now!](https://img.shields.io/badge/Play-Web_Version-green?style=for-the-badge&logo=godotengine)](https://tinky44.github.io/tall_life_simulator/)

## 概要

**Tall Life Simulator (トールライフシミュレーター)** は、背の高い人の日常生活を追体験し、様々な視点でシミュレーションを行うGodot製のブラウザ・ネイティブ向けゲームプロジェクトです。
RGTS simulator canvasやHeight simulatorの知見を活かし、高身長ならではの日常の「あるある」や「不便さ」「楽しさ」をインタラクティブに体験できるものを目指しています。

🌐 **[MVP版をブラウザで今すぐプレイする](https://tinky44.github.io/tall_life_simulator/)**

## コンセプト

- **身長差のシミュレーション**: キャラクターの身長や体型（頭身、脚の長さなど）を調整し、環境とのインタラクションの変化を観察します。
- **日常生活の追体験**: 家具や障害物などのオブジェクトに対し、現実世界におけるスケール感の違いや物理的な制約を体験できます。
- **インタラクティブなアクション**: 障害物を前に自動でかがむなどのアクションを通じて「背の高さ」をゲーム内で表現します。

## 操作方法 (ベータ版)

- キーボードやオンスクリーン UI を使用してキャラクターを操作します。
- メニュー画面からキャラクターの頭身や各部位のバランスをカスタマイズ可能です。

*(※操作方法は開発中のもので適宜アップデートされます)*

## 開発環境

- Engine: **Godot Engine 4.x**
- Language: GDScript

## ローカルでの実行方法

1. リポジトリをクローンします
   ```bash
   git clone https://github.com/tinky44/tall_life_simulator.git
   ```
2. Godot Engine 4.x を起動します
3. プロジェクトマネージャーから `godot-project/project.godot` (設定ファイル) をインポートして開きます
4. 「▶ 再生」ボタンを押してゲームを実行します

## 開発メモ・プロジェクト管理

本プロジェクトは AI (Gemini) との共同開発を主軸として進行しています。
- AI向けの開発指示および進捗管理は `GEMINI.md` を参照してください。
- 仕様書等は `specs/` ディレクトリに整備される予定です。
