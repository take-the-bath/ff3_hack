FC版FF3プチDS化パッチ
v0.7.9 (2007-08-31)
=======================================================================================================

## 概要
 このパッチはDS版FF3発売時まだDSを所持していなかった作者が、
 一部のジョブにDS版で新たに実装されたジョブ特性を実装したり、
 FC版でプレイ上の障害になるバグを修正したり、機能改善を行ったものです。
 DS化と銘打ってはありますが、アイテム、敵モンスター、マップなど、基本はFC版FF3そのものです。
 本家オリジナル版との詳しい違いは下記の「オリジナル版との違い」をご覧下さい。
 なお、それなりにテストはしてありますが、最悪プレイ中フリーズする可能性があります。

_______________________________________________________________________________
## 各バージョンの説明
 お好みに応じてどれか一つあててください。

- ff3_hack:
  安定版。現在同梱していません。

- ff3_hack_beta:
  新たに実装してテストが十分でない機能も含む版。

- ff3_hack_another:
  betaを基本に挑発の仕様が「敵全体・使用ターンのみ」から「味敵単体・3ターン継続」になる版。

- ff3_soundtest:
  サウンドテスト機能がついてるおまけ版。テスト後フリーズするので通常プレイには全く不向き。

_______________________________________________________________________________
## オリジナル版との違い

- ### 戦士に「ふみこむ」を実装
  
  敵の懐に潜り込んで渾身の一撃を叩き込みます。
  DS版とは違い、攻撃後、敵が行動可能な場合は即反撃を受けます。
  熟練するとより効果的な一撃を繰り出せるようになります。
  #### (仕様)
  - 攻撃力倍率(%) = 100 * (8 + (熟練度/8)) / 16
  - ダメージ上限65535

- ### 狩人に「みだれうち」を実装
  
  対象を定めずランダムに4回攻撃します。威力と命中率は通常時に比べ低下します。
  熟練に従い通常時と遜色がなくなります。
  #### (仕様)
  - 補正率(%) = 70 + 熟練度/4


- ### バイキングに「ちょうはつ」を実装
  
  敵全体を挑発しそのターン中自分を狙うように仕向けます。
  盾を持ったり後列に下がったりしていると実は怖がっているのがばれます。
  #### (仕様)
  - 成功率(%) = max(1, (100 + 使用者Lv + 使用者熟練度 - 対象Lv - 盾装備数*20)/後列補正 )
  - 後列補正は後列なら2，前列なら1


- ### 魔剣士に「あんこく」を実装
  
  HPを消費し敵全体に暗黒のオーラで攻撃します。
  闇の力を受けた対象は分裂する能力を失います。
  #### (仕様)
  - 回数 = 1 + 熟練度/16 + 精神/8
  - 威力 =75 + 熟練度 + 精神 (max255)


- ### モンクの特性としてカウンターを実装:
  打撃被弾時に一定の確率で反撃します。
  熟練すると相手の攻撃をよく見切るようになります。
  #### (仕様)
  - 反撃率(%) = 25 + 熟練度/2


- ### 学者がアイテムを使用すると効果2倍:
  戦闘中のみアイテムの効果が2倍になります。


- ### 「ためる」の仕様変更
  #### (本家仕様)
  - 1回ためるごとに「右手分のダメージ」が2倍→3倍と増加。
  - 全攻撃に対して防御0回避0で2倍ダメージを受ける。
  - ダメージ上限65535
  #### (パッチ版仕様)
  - 1回ためるごとに「両手の攻撃力」が2.25倍→3.5倍と増加。
  - 全攻撃に対して防御0回避0で2倍ダメージを受ける。
  - ダメージ上限65535

- ### 「ジャンプ」の仕様変更
  #### (本家仕様)
  - 着地時に「右手分のダメージ」が3倍。
  - ダメージ上限65535
  #### (パッチ版仕様)
  - 着地時に「両手の攻撃力」が2.5倍。
  - ダメージ上限65535


- ### 「ちけい」をやや強化
  熟練度の影響が若干大きくなっています。


- ### 「おどかす」を強化
  #### (本家仕様)
  - 敵全員のLv = 一番左上の敵Lv - 3
  #### (パッチ版仕様)
  - 各敵のLv = 各敵自身のLvの3/4


- ### 「おうえん」を強化
  #### (本家仕様)
  - 味方全員の右手攻撃力+10
  #### (パッチ版仕様)
  - 味方全員の追加攻撃力+32
  追加攻撃力というのは両手に追加されるステータスでは見えないもうひとつの攻撃力。
  手裏剣やオニオンソードが数字以上に強い理由。


- ### 戦闘中のウインドウの描画速度変更
  オリジナルでは1frame(1/60秒)に1行ずつ描画していた(計10frame)ものを可能な限り速く描画します。


- ### 打撃モーションの速度が可変
  ヒット数が多くなると振りが速くなります。
  本家版の片手あたりの制限回数も大幅に緩和。
  竪琴・弓矢・ブーメラン・円月輪はもとのままです。


- ### 戦闘時の乱数を変更
  ドロップ率が1に設定されているモンスター(3色ドラゴン以外全て)でも
  ドロップテーブルにある8種のアイテム全てを落とす可能性があります。
  本家版は乱数の性質により確率の高い上位3種のみしか落としません。


- ### 属性ボーナス("xxのまりょくアップ!")が反映されるように変更 
  ボーナスがついてる属性の魔法攻撃を行った場合、
  ヒット回数が20%増加します(本家仕様、端数は切り捨て=5回未満なら無意味)


- ### ウインドウイレースバグを修正
  装備を変更しない限り、プロテス・ヘイストの効果が消えることはありません。
  変更した場合は当該キャラのみ消えます。


- ### 戦闘中のアイテムウインドウの仕様変更
  スクロール速度が倍。
  装備変更したとき同種のアイテムがあればカーソル位置によらず重なります。
  装備変更してもウインドウが閉じません。(続けて変更可能)


- ### 吸収属性の仕様変更とバグ修正
  不死に対して吸収属性の攻撃を行うと相手が逆に回復します。
  また現HPにかかわらず攻撃側はダメージを数字通りにうけます。


- ### LvUp時の最大HP上昇量を16bit精度に変更 
  本家版は体力とLvが高すぎると逆に上昇量が低くなることがあります。


- ### 逃走試行中に敵の攻撃がミスするとターゲットの次の打撃ダメージが255倍になるバグを修正
  バックアタックを食らったときに逃げようとしてやっぱりあきらめるとたまになるアレです。


- ### 特定フロアでの「降りる」移動回数が37回程度に制限
  オリジナルでは45回程度
  (とはいえ40回程度移動すると正常動作は期待できなくなります、最悪セーブデータも消えます)
  MAP切り替え時の音が両側で同じ場所が該当します


- ### 逃走禁止に設定された戦闘において「にげる」「とんずら」を選択できないように変更
  選択しようとしても音が鳴るだけです。


- ### 赤魔道士を強化
  Lv5の魔法を使用可能。
  Lv20ぐらいから徐々にLv5のMPが増加(最大で5)。
  ディフェンダーとブレイクブレイドが装備可能。

_______________________________________________________________________________
## 未修正の問題 
- 戦闘を重ねると先頭のキャラがバグジョブになる(>>359)
  item99バグの可能性あり(ハイポーションがあやしい)

- 開発中1度だけカウンターしたときにカウンターした方が死んだ
  以後再現せず
  ステータスキャッシュ絡みと思われるが通常はまともな値が入っている
  分裂がきっかけだろうか

- 混乱と素手エフェクトに問題あり？

_______________________________________________________________________________
## 実装予定 

- ### 「ちけい」にランダム性を持たせる(一つの地形で複数の効果をランダムに出す)
  実装は出来てるが容量が勿体無いので当分保留

- ### フィールドのウインドウも高速化する
  課題が多すぎる

- ### ジョブチェンジ時に装備がある場合は自動解除するようにする

- ### 「ジャンプ」の攻撃力調整

