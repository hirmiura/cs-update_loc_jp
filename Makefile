# SPDX-License-Identifier: MIT
# Copyright 2023 hirmiura (https://github.com/hirmiura)
#
# cs-update_loc_jp/
# ├── src/
# ├── vanilla_content/ バニラデータ
# ├── tmp/ 作業用
# │   ├── core.txt
# │   ├── jp.txt
# │   ├── diff.txt
# │   └── vanilla_content/
# │       ├── normalized/ 正規化
# │       │   ├── core/
# │       │   ├── loc_jp/
# │       ├── diff/  差分
# │       ├── patch/ パッチ
# │       ├── patched-normalized/
# │       └── patched-cs/
# └── build/ パッケージ用
#
#
SHELL := /bin/bash
PROC := 4

F_JLB := JapaneseLocalizationBeta

D_VAN := vanilla_content
D_TMP := tmp
D_FMT := formatted
D_NOR := normalized
D_DIF := diff
D_PAT := patch
D_PAD := patched
D_SRC := src
D_BLD := build

D_CO := core
D_JP := loc_jp

# バニラの元ファイル群
D_VAN_C := $(D_VAN)/$(D_CO)
D_VAN_J := $(D_VAN)/$(D_JP)
L_VC := $(shell find $(D_VAN_C) -type f -name '*.json' \
	| sed -E -e '/\/cultures\//d' \
	-e '/\/(dicta|utilities|settings)\.json/d')
L_VJ := $(shell find $(D_VAN_J) -type f -name '*.json')

# 正規化後のファイル群
D_TMP_VAN        := $(D_TMP)/$(D_VAN)
D_TMP_VAN_NOR    := $(D_TMP_VAN)/$(D_NOR)
D_TMP_VAN_NOR_CO := $(D_TMP_VAN_NOR)/$(D_CO)
D_TMP_VAN_NOR_JP := $(D_TMP_VAN_NOR)/$(D_JP)
L_NC := $(L_VC:$(D_VAN)%=$(D_TMP_VAN_NOR)%)
L_NJ := $(L_VJ:$(D_VAN)%=$(D_TMP_VAN_NOR)%)

# 差分ファイル群
D_TMP_VAN_DIF := $(D_TMP_VAN)/$(D_DIF)
D_TMP_VAN_PAT := $(D_TMP_VAN)/$(D_PAT)
L_DI := $(L_VC:$(D_VAN_C)%=$(D_TMP_VAN_DIF)%)
L_PA := $(L_VC:$(D_VAN_C)%=$(D_TMP_VAN_PAT)%)

# 差分適用後の正規化ファイル群
D_TMP_VAN_PADNOR := $(D_TMP_VAN)/$(D_PAD)-$(D_NOR)
L_ND := $(L_VC:$(D_VAN_C)%=$(D_TMP_VAN_PADNOR)%)

# 差分適用後のCS形式ファイル群
D_TMP_VAN_PADCS := $(D_TMP_VAN)/$(D_PAD)-cs
L_FD := $(L_VC:$(D_VAN_C)%=$(D_TMP_VAN_PADCS)%)


#==============================================================================
# ヘルプ表示
#==============================================================================
define find.functions
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'
endef

.PHONY: help
help:
	@echo '以下のコマンドが使用できます'
	@echo ''
	$(call find.functions)


#==============================================================================
# バニラデータのリンク/ディレクトリを確認
#==============================================================================
.PHONY: check_vanilla
check_vanilla: ## バニラデータのリンク/ディレクトリを確認します
check_vanilla:
	@if [[ -d $(D_VAN) || -L $(D_VAN) && `readlink $(D_VAN) ` ]] ; then \
		echo "'vanilla_content' is OK." ; \
	else \
		echo "'vanilla_content'にバニラのcontentディレクトリのリンクかコピーを置いて下さい" ; \
	fi


#==============================================================================
# 初期化
#==============================================================================
.PHONY: init
init: ## 環境を構築します
init:
	poetry run python -m pip install --upgrade pip setuptools
	poetry update


#==============================================================================
# ビルド
#==============================================================================
.PHONY: all
all: ## ビルドします
all: check_vanilla init normalize diff apply-patch denormalize package


#==============================================================================
# 英語版と日本語版のファイルリストの差分を取得
#==============================================================================
.PHONY: diff-file-list
diff-file-list: ## 英語版と日本語版のファイルリストの差分を取得します
diff-file-list: file-list $(D_TMP)/diff.txt

$(D_TMP)/diff.txt:
	-diff $(D_TMP)/core.txt $(D_TMP)/jp.txt > $(D_TMP)/diff.txt

.PHONY: file-list
file-list: $(D_TMP)/core.txt $(D_TMP)/jp.txt

$(D_TMP)/core.txt:
	find $(D_VAN_C) -type f -name '*.json' | sed -e 's|^$(D_VAN_C)/||g' > $(D_TMP)/core.txt

$(D_TMP)/jp.txt:
	find $(D_VAN_J) -type f -name '*.json' | sed -e 's|^$(D_VAN_J)/||g' > $(D_TMP)/jp.txt


#==============================================================================
# JSONデータの正規化
#==============================================================================
.PHONY: normalize
normalize: ## JSONデータを正規化します
normalize:
	make -j $(PROC) _normalize

_normalize: $(L_NC) $(L_NJ)

$(L_NC) $(L_NJ):
	$(eval FN := $(@:$(D_TMP_VAN_NOR)/%=$(D_VAN)/%))
	@mkdir -p $(@D)
	@echo -e "\x1b[32mNormalizing\x1b[0m $(FN) > $@"
	@poetry run $(D_SRC)/normalize_cs_json.py $(FN) > $@


#==============================================================================
# 差分を取る
#==============================================================================
.PHONY: diff
diff: ## 差分を取ります
diff:
	make -j $(PROC) _diff

_diff: normalize $(L_DI)

$(L_DI):
	$(eval FNJ := $(@:$(D_TMP_VAN_DIF)/%=$(D_TMP_VAN_NOR_JP)/%))
	$(eval FNC := $(@:$(D_TMP_VAN_DIF)/%=$(D_TMP_VAN_NOR_CO)/%))
	$(eval FNP := $(@:$(D_TMP_VAN_DIF)/%=$(D_TMP_VAN_PAT)/%))
	@if [ -f $(FNJ) ] ; then \
		mkdir -p $(@D) ; \
		echo -e "\x1b[32mJSONdiffing\x1b[0m $(FNJ) $(FNC) > $@" ; \
		poetry run jsondiff --indent 4 $(FNJ) $(FNC) > $@ ; \
		mkdir -p $(dir $(FNP)) ; \
		echo -e "\x1b[32mJQing\x1b[0m $@ > $(FNP)" ; \
		jq '.[] | select(.op != "replace" or (.path | test("(/drawmessages/|(label|comments|description|descriptionunlocked)$$)") | not))' $@ | jq -s > $(FNP) ; \
	fi


#==============================================================================
# 差分を適用
#==============================================================================
.PHONY: apply-patch
apply-patch: ## 差分を適用します
apply-patch:
	make -j $(PROC) _apply-patch

_apply-patch: diff $(L_ND)

$(L_ND):
	$(eval FNJ := $(@:$(D_TMP_VAN_PADNOR)/%=$(D_TMP_VAN_NOR_JP)/%))
	$(eval FNP := $(@:$(D_TMP_VAN_PADNOR)/%=$(D_TMP_VAN_PAT)/%))
	$(eval FNC := $(@:$(D_TMP_VAN_PADNOR)/%=$(D_TMP_VAN_NOR_CO)/%))
	@mkdir -p $(@D)
	@if [[ -f $(FNJ) && -f $(FNP) && -s $(FNP) ]] ; then \
		echo -e "\x1b[32mJSONpatching\x1b[0m $(FNJ) $(FNP) > $@" ; \
		poetry run jsonpatch -u --indent 4 $(FNJ) $(FNP) > $@ ; \
	else \
		cp -f $(FNC) $@ ; \
	fi


#==============================================================================
# 元の形式に戻す
#==============================================================================
.PHONY: denormalize
denormalize: ## Cultist Simulator形式のJSONに戻します
denormalize:
	make -j $(PROC) _denormalize

_denormalize: apply-patch $(L_FD)

$(L_FD):
	$(eval FN := $(@:$(D_TMP_VAN_PADCS)/%=$(D_TMP_VAN_PADNOR)/%))
	@mkdir -p $(@D)
	@echo -e "\x1b[32mDe-Normalizing\x1b[0m $(FN) > $@"
	@poetry run $(D_SRC)/normalize_cs_json.py -d $(FN) > $@


#==============================================================================
# ビルド
#==============================================================================
.PHONY: build
build: ## ビルドします
build: denormalize


#==============================================================================
# パッケージ作成
#==============================================================================
.PHONY: package
package: ## パッケージを作成します
package: build copy $(F_JLB).zip

$(F_JLB).zip:
	ln -s $(D_BLD) $(F_JLB)
	7z.7zip a -tzip $@ $(F_JLB)
	rm -f $(F_JLB)


#==============================================================================
# ファイルコピー
#==============================================================================
.PHONY: copy
copy: ## パッケージ用にファイルをコピーします
copy: $(D_BLD)/synopsis.json $(D_BLD)/cover.png $(D_BLD)/serapeum_catalogue_number.txt
	@mkdir -p $(D_BLD)/loc
	cp -f README.md $(D_BLD)
	cp -fr $(D_TMP_VAN_PADCS) $(D_BLD)/loc/$(D_JP)

$(D_BLD)/%: $(D_SRC)/%
	@mkdir -p $(@D)
	cp -f $< $@


#==============================================================================
# お掃除
#==============================================================================
.PHONY: clean
clean: ## 削除します
clean: clean-build clean-tmp clean-build clean-package clean-cache

.PHONY: clean-tmp
clean-tmp: ## テンポラリファイルを削除します
clean-tmp:
	rm -fr $(D_TMP)

.PHONY: clean-diff-file-list
clean-diff-file-list: ## 英語版と日本語版のファイルリストの差分を削除します
clean-diff-file-list:
	rm -f $(D_TMP)/diff.txt $(D_TMP)/core.txt $(D_TMP)/jp.txt

.PHONY: clean-normalized
clean-normalized: ## 整形済みファイルを削除します
clean-normalized:
	rm -fr $(D_TMP_VAN_NOR)

.PHONY: clean-diff
clean-diff: ## 差分ファイルを削除します
clean-diff: clean-patch

.PHONY: clean-patch
clean-patch: ## 差分ファイルを削除します
clean-patch:
	rm -fr $(D_TMP_VAN_DIF)
	rm -fr $(D_TMP_VAN_PAT)

.PHONY: clean-patched-normalized
clean-patched-normalized: ## 差分適用正規化後ファイルを削除します
clean-patched-normalized:
	rm -fr $(D_TMP_VAN_PADNOR)

.PHONY: clean-patched-cs
clean-patched-cs: ## 差分適用後整形済みファイルを削除します
clean-patched-cs:
	rm -fr $(D_TMP_VAN_PADCS)

.PHONY: clean-build
clean-build: ## ビルドを削除します
clean-build:
	rm -fr $(D_BLD)

.PHONY: clean-package
clean-package: ## パッケージを削除します
clean-package:
	rm -f $(F_JLB).zip

.PHONY: clean-cache
clean-cache: ## キャッシュファイルを削除します
clean-cache:
	rm -rf .pytest_cache .mypy_cache
	# Remove all pycache
	find . | grep -E "(__pycache__|\.pyc|\.pyo$$)" | xargs rm -rf


#==============================================================================
# デバッグ用のテストルール
#==============================================================================
.PHONY: test
test: ## デバッグ用です(※pytestは走りません)
test:
	@echo $(A_NAME).zip
