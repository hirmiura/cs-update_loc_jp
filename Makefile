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
# │       ├── formatted/ 整形
# │       │   ├── core/
# │       │   ├── loc_jp/
# │       │   └── patched/
# │       ├── normalized/ ハッシュ化
# │       │   ├── core/
# │       │   ├── loc_jp/
# │       │   └── patched/
# │       ├── diff/
# │       └── patch/
# └── build/ パッケージ用
#
#
SHELL := /bin/bash

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
	-e '/\/(dicta|credits|versionnews|utilities|settings)\.json/d')
L_VJ := $(shell find $(D_VAN_J) -type f -name '*.json')

# 整形後のファイル群
D_TMP_VAN     := $(D_TMP)/$(D_VAN)
D_TMP_VAN_FMT := $(D_TMP_VAN)/$(D_FMT)
D_TMP_VAN_FMT_CO := $(D_TMP_VAN_FMT)/$(D_CO)
D_TMP_VAN_FMT_JP := $(D_TMP_VAN_FMT)/$(D_JP)
L_FC := $(L_VC:$(D_VAN)/%=$(D_TMP_VAN_FMT)/%)
L_FJ := $(L_VJ:$(D_VAN)/%=$(D_TMP_VAN_FMT)/%)

# 正規化後のファイル群
D_TMP_VAN_NOR := $(D_TMP_VAN)/$(D_NOR)
D_TMP_VAN_NOR_CO := $(D_TMP_VAN_NOR)/$(D_CO)
D_TMP_VAN_NOR_JP := $(D_TMP_VAN_NOR)/$(D_JP)
L_NC := $(L_VC:$(D_VAN)/%=$(D_TMP_VAN_NOR)/%)
L_NJ := $(L_VJ:$(D_VAN)/%=$(D_TMP_VAN_NOR)/%)

# 差分ファイル群
D_TMP_VAN_DIF := $(D_TMP_VAN)/$(D_DIF)
D_TMP_VAN_PAT := $(D_TMP_VAN)/$(D_PAT)
L_DI := $(L_VC:$(D_VAN_C)/%=$(D_TMP_VAN_DIF)/%)
L_PA := $(L_VC:$(D_VAN_C)/%=$(D_TMP_VAN_PAT)/%)

# 差分適用後の正規化ファイル群
D_TMP_VAN_NOR_PAD := $(D_TMP_VAN_NOR)/$(D_PAD)
L_ND := $(L_VC:$(D_VAN_C)/%=$(D_TMP_VAN_NOR_PAD)/%)

# 差分適用後のCS形式ファイル群
D_TMP_VAN_FMT_PAD := $(D_TMP_VAN_FMT)/$(D_PAD)
L_FD := $(L_VC:$(D_VAN_C)/%=$(D_TMP_VAN_FMT_PAD)/%)


define find.functions
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'
endef

.PHONY: help
help:
	@echo '以下のコマンドが使用できます'
	@echo ''
	$(call find.functions)


.PHONY: check_vanilla
check_vanilla: ## バニラデータのリンク/ディレクトリを確認します
check_vanilla:
	@if [[ -d $(D_VAN) || -L $(D_VAN) && `readlink $(D_VAN) ` ]] ; then \
		echo "'vanilla_content' is OK." ; \
	else \
		echo "'vanilla_content'にバニラのcontentディレクトリのリンクかコピーを置いて下さい" ; \
	fi


.PHONY: init
init: ## 環境を構築します
init:
	poetry run python -m pip install --upgrade pip setuptools
	poetry update


.PHONY: all
all: ## ビルドします
all: check_vanilla init build package


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


.PHONY: formatting
formatting: ## ルーズJSONを整形します
formatting: $(L_FC) $(L_FJ)

$(L_FC) $(L_FJ):
	$(eval FN := $(@:$(D_TMP_VAN_FMT)/%=$(D_VAN)/%))
	@mkdir -p $(@D)
	@echo -e "\x1b[32mFormatting\x1b[0m $(FN) > $@"
	@poetry run $(D_SRC)/format_json.py $(FN) > $@


.PHONY: normalize
normalize: ## ハッシュテーブルを再構築します
normalize: formatting $(L_NC) $(L_NJ)

$(L_NC) $(L_NJ):
	$(eval FN := $(@:$(D_TMP_VAN_NOR)/%=$(D_TMP_VAN_FMT)/%))
	@mkdir -p $(@D)
	@echo -e "\x1b[32mNormalizing\x1b[0m $(FN) > $@"
	@poetry run $(D_SRC)/normalize_json.py $(FN) > $@


.PHONY: diff
diff: ## 差分を取ります
diff: normalize $(L_DI)

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


.PHONY: apply-patch
apply-patch: ## 差分を適用します
apply-patch: diff $(L_ND)

$(L_ND):
	$(eval FNJ := $(@:$(D_TMP_VAN_NOR_PAD)/%=$(D_TMP_VAN_NOR_JP)/%))
	$(eval FNP := $(@:$(D_TMP_VAN_NOR_PAD)/%=$(D_TMP_VAN_PAT)/%))
	$(eval FNC := $(@:$(D_TMP_VAN_NOR_PAD)/%=$(D_TMP_VAN_NOR_CO)/%))
	@mkdir -p $(@D)
	@if [[ -f $(FNJ) && -f $(FNP) && -s $(FNP) ]] ; then \
		echo -e "\x1b[32mJSONpatching\x1b[0m $(FNJ) $(FNP) > $@" ; \
		poetry run jsonpatch -u --indent 4 $(FNJ) $(FNP) > $@ ; \
	else \
		cp -f $(FNC) $@ ; \
	fi


.PHONY: denormalize
denormalize: ## Cultist Simulator形式のJSONに戻します
denormalize: apply-patch $(L_FD)

$(L_FD):
	$(eval FN := $(@:$(D_TMP_VAN_FMT_PAD)/%=$(D_TMP_VAN_NOR_PAD)/%))
	@mkdir -p $(@D)
	@echo -e "\x1b[32mDe-Normalizing\x1b[0m $(FN) > $@"
	@poetry run $(D_SRC)/normalize_json.py -d $(FN) > $@


.PHONY: build
build: ## ビルドします
build: denormalize


.PHONY: package
package: ## パッケージを作成します
package: build copy $(F_JLB).zip

$(F_JLB).zip:
	ln -s $(D_BLD) $(F_JLB)
	7z.7zip a -tzip $@ $(F_JLB)
	rm -f $(F_JLB)


.PHONY: copy
copy: ## パッケージ用にファイルをコピーします
copy: $(D_BLD)/synopsis.json
	@mkdir -p $(D_BLD)/loc
	cp -fr $(D_TMP_VAN_FMT_PAD) $(D_BLD)/loc/$(D_JP)

$(D_BLD)/synopsis.json: $(D_SRC)/synopsis.json
	@mkdir -p $(D_BLD)
	cp -f $(D_SRC)/synopsis.json $(D_BLD)/


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

.PHONY: clean-formatted
clean-formatted: ## 整形済みファイルを削除します
clean-formatted:
	rm -fr $(D_TMP_VAN_FMT)

.PHONY: clean-normalized
clean-normalized: ## 整形済みファイルを削除します
clean-normalized:
	rm -fr $(D_TMP_VAN_NOR)

.PHONY: clean-patch
clean-patch: ## 差分ファイルを削除します
clean-patch:
	rm -fr $(D_TMP_VAN_DIF)
	rm -fr $(D_TMP_VAN_PAT)

.PHONY: clean-patched-normalized
clean-patched-normalized: ## 差分適用正規化後ファイルを削除します
clean-patched-normalized:
	rm -fr $(D_TMP_VAN_NOR_PAD)

.PHONY: clean-patched-denormalized
clean-patched-denormalized: ## 差分適用後整形済みファイルを削除します
clean-patched-denormalized:
	rm -fr $(D_TMP_VAN_FMT_PAD)

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


.PHONY: test
test: ## デバッグ用です(※pytestは走りません)
test:
	@echo $(A_NAME).zip
