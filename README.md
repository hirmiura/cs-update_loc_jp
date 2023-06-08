# Japanese Localization updated in Beta branch (Gate of Horn)

これは、[Cultist Simulator](https://weatherfactory.biz/cultist-simulator/)の公式日本語版に、ベータブランチのアップデートを取り込んだものです。※翻訳は増えていません。  
[Steamストア](https://store.steampowered.com/app/718670/Cultist_Simulator/)

## やっていること

1. 環境を作る。  
   `make init`
2. vanilla_contentにバニラのcontentディレクトリのリンクを貼る。  
   `ln -s HOGE/Cultist Simulator/cultistsimulator_Data/StreamingAssets/content vanilla_content`
3. 処理しにくいので綺麗なJSONに整形する。  
   `make formatting`
4. リスト形式を辞書(ハッシュ)形式に変換する。  
   `make normalize`
5. jsondiffで差分を取る。  
   `make diff`
6. jqで日本語化以外の差分を抽出する。  
   `make diff`
7. jsonpatchで差分を日本語化データに統合する。  
   `make apply-patch`
8. 辞書形式のデータをリスト形式に戻す。  
   `make denormalize`

## ビルド環境

[GitHubページ](https://github.com/hirmiura/cs-update_loc_jp)

- Cultist Simulator 2023.5.p.5 PEONY
- WSL Debian(unstable)
- GNU make 4.3
- JQ 1.6
- Python 3.11
  - poetry 1.5.1
  - pyenv 2.3.18-9-ge0084304

## ライセンス

オリジナルがあるものは、元々のライセンスに準じます。  
私が追加/作成した部分はMITライセンスとします。(好きに使って下さい)

[MIT License](https://opensource.org/license/mit/)
