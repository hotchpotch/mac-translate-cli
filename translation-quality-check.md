# Translation Quality Check

Date: 2026-06-08

This document summarizes a translation-quality investigation of `trn`, the macOS command-line translator in this project.

Evaluator note: this was recorded as a GPT-5.5 translation-quality investigation. The qualitative scores below were assigned by reading the `trn` output and judging meaning preservation, terminology, proper names, numbers, naturalness, and round-trip information loss.

## Summary

`trn` produced generally usable translations for short English/Japanese sentences across ten domains. One pass used `-q high`; a second pass used `-q low` on the same source strings. The strongest results were in ordinary explanatory prose, literary comparison, travel logistics, emergency instructions, and simple software operations. The weakest points were proper-name stability, honorifics and roles, some domain-specific terms, and round-trip degradation from Japanese back into Japanese through English.

Average scores for `-q high` on a 5-point scale:

| Direction | Average | Interpretation |
| --- | ---: | --- |
| English to Japanese | 3.83 | Mostly understandable, with local awkwardness in roles, names, and terminology. |
| Japanese to English | 4.35 | More stable in direct translation, though some context terms were mistranslated. |
| English to Japanese to English | 4.24 | Most core information returned, but name spelling drift appeared. |
| Japanese to English to Japanese | 3.57 | More fragile; polarity reversal, broken fragments, and punctuation artifacts appeared. |

Average scores for `-q low` on the same source strings:

| Direction | Average | Interpretation |
| --- | ---: | --- |
| English to Japanese | 3.84 | Similar average to high mode, with some better terminology and some worse contextual errors. |
| Japanese to English | 4.32 | Similar to high mode in direct translation, but still weak on education/title handling. |
| English to Japanese to English | 3.86 | Lower than high mode; round trips lost subjects and proper-name detail more often. |
| Japanese to English to Japanese | 3.84 | Better average than the high-mode round trip in this small sample, but still produced broken fragments. |

README translation speed, measured once for each quality mode:

| Input | Direction | Quality | Wall time | Relative speed |
| --- | --- | --- | ---: | ---: |
| `README.md` 4,818 characters / 5,039 bytes | English to Japanese | `high` | 39.777 s | 1.00x |
| `README.md` 4,818 characters / 5,039 bytes | English to Japanese | `low` | 3.461 s | 11.49x faster |

## Usage Guidance

Use `low` for normal English/Japanese translation:

```sh
trn --from en --to ja "Hello world!"
trn --from ja --to en "こんにちは"
```

Use `high` when evaluating translation quality or checking whether Apple Intelligence high-fidelity translation improves a specific sentence:

```sh
trn --from en --to ja --quality high "Hello world!"
trn --from ja --to en --quality high "こんにちは"
```

This evaluation compared both `high` and `low`. For the tested English/Japanese cases, `low` was sufficient for ordinary use, while the README benchmark showed `low` running about 11.49x faster than `high`; the long-text checks showed roughly 9.38x to 16.80x faster direct translation. In practical terms, `low` was about 10x faster in this local sample.

Long-text direct translation speed, measured once per passage and quality mode:

| Passage | Source length | Direction | `high` | `low` | Low speedup |
| --- | ---: | --- | ---: | ---: | ---: |
| Incident report | 1,006 characters | English to Japanese | 6.387 s | 0.681 s | 9.38x faster |
| Municipal notice | 884 characters | Japanese to English | 16.231 s | 0.966 s | 16.80x faster |

## Main Findings

### Strengths

| Area | Observation | Examples |
| --- | --- | --- |
| Numbers and deadlines | Usually preserved in direct translation. | `12%`, `3 p.m.`, `by noon`, `another meter`, `within seven days` |
| Causal relations | Usually preserved. | Train delay caused bus booking; warm nights lowered oxygen levels; river rise risk caused evacuation. |
| General prose | Literary and explanatory sentences translated well. | The culture/literature case was the best overall case in both directions. |
| Direction tendency | Japanese-to-English direct translation was often more natural than English-to-Japanese direct translation for this test set. | Travel, software, emergency, and culture/literature cases. |

### Weaknesses

| Area | Problem | Examples |
| --- | --- | --- |
| Proper names | Names drifted during translation or round trip. | `Ruiz` to `Lewis`; `Nair` to `Neil` or `Nile`; `Sofia` to `Sophia`. |
| Roles and titles | Honorifics and roles were unstable. | `Ms. Tanaka` to `ミズ 田中` to `Ms. Mizu Tanaka`; `田中先生` to `Mr. Tanaka`; emergency `Captain` to `船長`. |
| Domain terms | Some terms were too literal or contextually wrong. | `rotate expired tokens` to `期限が切れたトークンを回転させる`; `Pier 4` to `4番のピエア`; `決算説明会` to `closing meeting` to `閉会式`. |
| Round-trip loss | Round trips exposed information loss not obvious in direct output. | Legal condition reversed from "if he signed" to "if he did not sign"; `crabs` broke into `クラ...bs`; artifacts such as `ys。`, `bs。`, and doubled punctuation appeared. |

## Scoring Scale

| Score | Meaning |
| ---: | --- |
| 5 | Nearly publication-ready for the tested sentence. |
| 4 | Usable after light editing. |
| 3 | Meaning is mostly recoverable, but editing is required for serious use. |
| 2 | Important meaning is damaged, reversed, or hard to recover. |
| 1 | Translation is not reliable for the sentence. |

## High Quality Mode Case Tables

The following tables show the explicit `-q high` results. They are split by source direction so each row stays scannable.

### High Mode: English Source Cases

| Domain | English source | High English to Japanese | High English round trip | Scores | Assessment |
| --- | --- | --- | --- | --- | --- |
| Medicine | At St. Mary's Clinic, Dr. Elena Ruiz told Noah that the rash was likely an allergy, not an infection, and advised rest. | セントメリーズクリニックで、エレナ・ルイス博士はノアに、発疹は感染ではなくアレルギーの可能性が高く、休息を取ることを勧めました。 | At St. Mary's Clinic, Dr. Elena Lewis advised Noah that the rash was likely an allergy rather than an infection and recommended that he take a rest. | E-J 4.3; E-J-E 4.4 | Clinical meaning was preserved. The main issue was name drift from `Ruiz` to `Lewis`, plus `Dr.` becoming closer to `博士` than `医師`. |
| Legal | Attorney Maya Chen warned Oliver that signing the lease before Monday could waive his right to cancel within seven days. | 弁護士マヤ・チェンは、月曜日までに賃貸契約に署名すると、7日以内にキャンセルする権利を放棄する可能性があるとオリバーに警告した。 | Attorney Maya Chen warned Oliver that if he signs the lease agreement by Monday, he may forfeit his right to cancel within 7 days. | E-J 3.6; E-J-E 3.8 | The legal consequence was mostly preserved, but `before Monday` weakened to `by Monday`. |
| Finance | During the earnings call, CFO Daniel Kim said Apex Robotics cut inventory by 12% while protecting cash for repairs. | 収益発表会で、CFOのダニエル・キム氏は、Apex Roboticsは修理のための現金を保護しながら在庫を12%削減したと語った。 | At the earnings conference, CFO Daniel Kim said that Apex Robotics reduced its inventory by 12% while protecting cash for repairs. | E-J 4.1; E-J-E 4.5 | Inventory, cash, repairs, and `12%` were preserved. `earnings call` was understandable but slightly literal. |
| Climate Science | Professor Aisha Khan found that the bay's summer oxygen levels fell after warm nights, harming small crabs near Pier 4. | アイシャ・カーン教授は、湾の夏の酸素レベルが暖かい夜の後低下し、4番のピエアの近くの小さなカニに害を与えたことを発見した。 | Professor Aisha Khan found that the oxygen levels in the bay during the summer decreased after warm nights, harming small crabs near Pier 4. | E-J 3.6; E-J-E 4.6 | Cause and effect were preserved. `Pier 4` became awkward Japanese, but the round trip recovered it. |
| Software | Engineer Priya Nair fixed the login bug by rotating expired tokens instead of forcing every user to reset a password. | エンジニアのプリヤ・ナイールは、すべてのユーザーにパスワードを再設定することを強制する代わりに、有効期限が切れたトークンを回転させることでログインバグを修正しました。 | Engineer Priya Neil fixed the login bug by rotating expired tokens instead of forcing all users to reset their passwords. | E-J 4.0; E-J-E 4.2 | The operation and contrast were preserved. `トークンを回転させる` is too literal, and `Nair` drifted. |
| Travel and Transportation | When the Kyoto train was delayed, Liam booked Sara a bus through Nagoya so she could reach the workshop by 3 p.m. | 京都の電車が遅れたとき、リアムはサラに名古屋経由のバスを手配して、午後3時までにワークショップに着くようにしました。 | When the train in Kyoto was delayed, Liam arranged a bus via Nagoya for Sarah so that she could arrive at the workshop by 3 p.m. | E-J 3.7; E-J-E 4.2 | Route, deadline, and booking action were preserved. The train direction was less precise. |
| Education | Ms. Tanaka asked Miguel to explain his answer aloud, because the worksheet showed the result but not his reasoning. | ミズ 田中は、ワークシートには結果が表示されているが、その根拠が書かれていないため、ミゲルに答えを声に出して説明するように依頼しました。 | Ms. Mizu Tanaka asked Miguel to explain the answer aloud because the worksheet shows the results, but the basis for them is not written. | E-J 2.7; E-J-E 3.0 | The classroom intent remained, but `Ms.` became a name-like token and round-tripped as `Mizu Tanaka`. |
| Culture and Literature | In her review, Julia compared Haruki's quiet ending to a door left open after the rain, not to a solved mystery. | 彼女のレビューでは、ジュリアはハルキの静かな結末を、解決された謎ではなく、雨が降った後に開いたままになっているドアに例えました。 | In her review, Julia compared Haruki's quiet ending to a door that remained open after the rain, rather than a solved mystery. | E-J 4.7; E-J-E 4.8 | This was one of the strongest cases. The metaphor, contrast, names, and tone were mostly preserved. |
| E-Commerce and Support | After Nina received the wrong charger, Ken at BrightCart offered a refund or a replacement shipped by Friday. | ニナは間違った充電器を受け取った後、BrightCartのケンが金曜日までに返金または交換品の発送を申し出ました。 | After Nina received the wrong charger, Ken from BrightCart offered to refund or ship a replacement by Friday. | E-J 3.5; E-J-E 4.4 | The offer was preserved, but the Japanese wording can be read as if the refund is shipped. |
| Emergency and Disaster Response | Captain Sofia Lopez told residents on Cedar Street to leave by noon because the river could rise another meter overnight. | ソフィア・ロペス船長は、シダーストリートの住民に対し、川の水位が夜間にさらに1メートル上昇する可能性があるため、正午までに避難するよう指示した。 | Captain Sophia Lopez instructed residents of Cedar Street to evacuate by noon due to the possibility that the river level could rise another meter overnight. | E-J 4.1; E-J-E 4.5 | The emergency instruction was clear. `Captain` became `船長`, and `Sofia` became `Sophia` in the round trip. |

### High Mode: Japanese Source Cases

| Domain | Japanese source | High Japanese to English | High Japanese round trip | Scores | Assessment |
| --- | --- | --- | --- | --- | --- |
| Medicine | 聖マリア診療所で、エレナ・ルイス医師はノアに、その発疹は感染ではなくアレルギーの可能性が高く、休養が必要だと伝えた。 | At the St. Mary's Clinic, Dr. Elena Lewis told Noah that the rash was likely an allergy rather than an infection, and that he needed to rest. | セントメリーズクリニックで、エレナ・ルイス博士はノアに、発疹は感染ではなくアレルギーの可能性が高く、休む必要があると語った。。 | J-E 4.4; J-E-J 4.0 | Meaning was almost exact. The round trip kept the medical instruction but added doubled punctuation and `博士`. |
| Legal | 弁護士のマヤ・チェンはオリバーに、月曜前に賃貸契約へ署名すると、七日以内の解約権を失う恐れがあると警告した。 | Lawyer Maya Chen warned Oliver that if he signed the lease agreement before Monday, he would risk losing his right to cancel within seven days. | 弁護士のマヤ・チェンはオリバーに、月曜日までに賃貸借契約書に署名しないと、7日以内にキャンセルする権利を失う可能性があると警告しました。ys。 | J-E 4.6; J-E-J 2.0 | Direct translation was strong. The round trip reversed the condition from signing to not signing and added `ys。`. |
| Finance | 決算説明会で、CFOのダニエル・キムは、Apex Roboticsが修理費の現金を確保しつつ在庫を12%削減したと述べた。 | At the closing meeting, CFO Daniel Kim said that Apex Robotics reduced its inventory by 12% while securing cash for repair costs. | 閉会式で、CFOのダニエル・キム氏は、Apex Roboticsは在庫を12%削減しながら、修理費用の現金を確保したと語った。 | J-E 3.6; J-E-J 3.8 | Operational details survived, but `決算説明会` became `closing meeting` and then `閉会式`. |
| Climate Science | アイシャ・カーン教授は、暖かい夜の後に湾の夏季酸素濃度が低下し、4番桟橋近くの小さなカニに悪影響を与えたと確認した。 | Professor Aisha Khan confirmed that the summer oxygen levels in the bay dropped after a warm night, which had a negative impact on small crabs near Pier 4. | アイシャ・カーン教授は、湾の夏の酸素レベルが暖かい夜の後低下したことを確認し、これは小さなクラに悪影響を及ぼしたと述べた。4番のピアの近くにあるbs。 | J-E 4.5; J-E-J 2.8 | Direct translation was clear. The round trip broke `crabs` into unreadable fragments. |
| Software | エンジニアのプリヤ・ナイルは、全利用者にパスワード再設定を強制せず、期限切れトークンを更新してログイン不具合を直した。 | Engineer Priya Nile fixed the login problem by updating the expired tokens without forcing all users to reset their passwords. | エンジニアのプリヤ・ナイルは、すべてのユーザーにパスワードを再設定することを強制することなく、期限切れになったトークンを更新することでログインの問題を解決しました。 | J-E 4.6; J-E-J 4.5 | Natural and practical. Name spelling drifted to `Nile`, but the technical content was preserved. |
| Travel and Transportation | 京都行きの列車が遅れたため、リアムはサラが午後3時までに研修会へ着けるよう、名古屋経由のバスを予約した。 | Because the train to Kyoto was delayed, Liam booked a bus via Nagoya so that Sarah could arrive at the training session by 3 p.m. | 京都への列車が遅れたので、リアムはサラの午後3時までにトレーニングセッションに到着できるように、名古屋経由のバスに予約しました。 | J-E 4.7; J-E-J 3.8 | Direct translation was strong. The Japanese round trip became unnatural but understandable. |
| Education | 田中先生はミゲルに、ワークシートには答えだけで考え方が書かれていなかったため、解き方を声に出して説明するよう求めた。 | Mr. Tanaka asked Miguel to explain aloud how to solve it because the worksheet only had the answers and no way of thinking. | ミスター タナカは、ワークシートには答えしかなく、考え方の方法がなかったので、ミゲルにそれをどのように解決するか大声で説明するように頼みました。 | J-E 3.2; J-E-J 2.6 | `先生` became `Mr.`, losing the teacher role and adding gender. `考え方` was also unnatural. |
| Culture and Literature | ジュリアは書評で、春樹の静かな結末を、解けた謎ではなく、雨上がりに開いたままの扉にたとえた。 | In her book review, Julia compared Haruki's quiet ending to a door that remained open after the rain, rather than a solved mystery. | ジュリアは彼女の書評の中で、春樹の静かな結末を、解決された謎ではなく、雨が降った後に開かれたままのドアに例えました。 | J-E 4.8; J-E-J 4.6 | The metaphor and contrast were preserved very well. |
| E-Commerce and Support | ニナに違う充電器が届いた後、BrightCartのケンは返金か、金曜までに発送される交換品を提案した。 | After Nina received a different charger, Ken from BrightCart suggested a refund or a replacement that would be shipped by Friday. | ニナは別の充電器を受け取った後、BrightCartのケンが金曜日までに発送される返金または交換を提案しました。 | J-E 4.5; J-E-J 3.5 | Direct translation was natural. The round trip made the refund/replacement shipping relationship ambiguous. |
| Emergency and Disaster Response | ソフィア・ロペス隊長は、川が夜間にさらに1メートル上昇する恐れがあるため、Cedar Streetの住民へ正午までの避難を指示した。 | Captain Sophia Lopez ordered residents of Cedar Street to evacuate by noon due to the risk that the river could rise another meter overnight. | ソフィア・ロペス船長は、川が夜間にさらに1メートル上昇する可能性があるため、シダー通りの住民に対し正午までに避難するよう命じた。。 | J-E 4.6; J-E-J 4.1 | Critical action, deadline, and risk were preserved. Role and name spelling drifted, and punctuation doubled. |

## Low Quality Mode Results

The following results used `-q low` with the same source strings as the high-quality evaluation above. The source texts are not repeated here because they are identical to the case texts in the previous section.

### Low Mode Summary

`-q low` was much faster in the README benchmark and was not uniformly worse on short sentences. In several cases it produced more natural domain terms, such as `決算説明会` for `earnings call`, `ピア4` for `Pier 4`, and `トークンをローテーション` for `rotating tokens`. However, it also made context errors that high mode avoided, including interpreting `St. Mary's Clinic` as a street-related phrase and losing `Sara` as the booked passenger in one round trip.

The strongest low-mode cases were finance, climate-science direct translation, software, culture/literature, and emergency direct translation. The weakest low-mode case remained education, especially `Ms.` / `先生` handling.

### Low Mode Case Table

| Domain | Low English to Japanese | Low English Round Trip | Low Japanese to English | Low Japanese Round Trip | Scores | Assessment |
| --- | --- | --- | --- | --- | --- | --- |
| Medicine | 通りで メアリーの診療所、医師 エレナ・ルイスはノアに、発疹はアレルギーの可能性が高く、感染ではないと伝え、安静を勧めました。 | On the street, Mary's clinic, doctor Elena Lewis told Noah that the rash was likely to be an allergy and not an infection, and advised her to rest. | At the St. Maria Clinic, Dr. Elena Lewis told Noah that the rash was not an infection, but was likely to be allergic and needed to rest. | 通りで マリアクリニック、医師 エレナ・ルイスはノアに、発疹は感染ではなく、アレルギーの可能性が高く、休む必要があると伝えました。 | E-J 3.0, E-J-E 3.1; J-E 4.0, J-E-J 3.5 | Core medical meaning survived, but `St.` was misread as a street-related phrase and the back translation introduced a wrong pronoun. |
| Legal | 弁護士のマヤ・チェンは、オリバーに対し、月曜日までにリースに署名すれば、7日以内に解約する権利を放棄できると警告しました。 | Lawyer Maya Chen warned Oliver that if she signed the lease by Monday, she could waive her right to terminate within seven days. | Lawyer Maya Chen warned Oliver that if she signed the lease before Monday, she could lose her right to cancel within seven days. | 弁護士のマヤ・チェンは、オリバーに対し、月曜日までにリースにサインすれば、7日以内に解約権を失う可能性があると警告しました。 | E-J 3.3, E-J-E 3.4; J-E 4.2, J-E-J 3.7 | The legal consequence was mostly preserved, but `before Monday` weakened to `by Monday`, and the pronoun drifted to `she`. |
| Finance | 決算説明会で、CFOのダニエル・キム氏は、Apex Roboticsが在庫を12%削減し、修理のための資金を保護したと述べました。 | At the earnings briefing, CFO Daniel Kim said that Apex Robotics had reduced inventory by 12% and protected funds for repairs. | At the earnings briefing, CFO Daniel Kim said that Apex Robotics had reduced inventory by 12% while securing cash for repair costs. | 決算説明会で、CFOのダニエル・キム氏は、Apex Roboticsが在庫を12%削減し、修理費用のための現金を確保したと述べました。 | E-J 4.5, E-J-E 4.4; J-E 4.7, J-E-J 4.6 | Low mode handled the finance context better than high mode, especially `earnings briefing` / `決算説明会`. |
| Climate Science | アイシャ・カーン教授は、暖かい夜の後に湾の夏季酸素濃度が低下し、ピア4付近の小型カニに害を及ぼすことを発見しました。 | Professor Aisha Khan found that summer oxygen levels in the bay drop after a warm night, causing harm to small crabs near Pier 4. | Professor Aisha Khan confirmed that the summer oxygen concentration in the bay decreased after a warm night, which adversely affected the small crabs near Pier 4. | アイシャ・カーン教授は、暖かい夜の後に湾の夏季酸素濃度が低下したことを確認し、それがsmに悪影響を及ぼしたと述べました。ピア4付近のすべてのカニ。 | E-J 4.7, E-J-E 4.4; J-E 4.7, J-E-J 3.0 | Direct translation was strong and `Pier 4` was better than high mode. The Japanese round trip still broke `small` into `sm` and distorted `small crabs`. |
| Software | エンジニアのプリヤ・ナイルは、すべてのユーザーにパスワードをリセットさせるのではなく、期限切れのトークンをローテーションすることでログインバグを修正しました。 | Engineer Priya Nile fixed a login bug by rotating expired tokens instead of having all users reset their passwords. | Engineer Priya Nile did not force all users to reset their passwords, but updated the expired token to fix the login problem. | エンジニアのプリヤ・ナイルは、すべてのユーザーにパスワードのリセットを強制しませんでしたが、期限切れのトークンを更新してログイン問題を解決しました。 | E-J 4.6, E-J-E 4.2; J-E 4.5, J-E-J 4.5 | Low mode used more natural software terminology than high mode. Name spelling still drifted from `Nair` to `Nile`. |
| Travel and Transportation | 京都の電車が遅れたとき、リアムはサラが名古屋経由のバスを予約し、午後3時までに作業場に到着できるようにしました。 | When the Kyoto train was delayed, Liam booked a bus via Nagoya so that she could arrive at the workshop by 3 p.m. | Because the train to Kyoto was delayed, Liam booked a bus via Nagoya so that Sarah could arrive at the training session by 3 p.m. | 京都行きの電車が遅れたため、リアムは名古屋経由でバスを予約し、サラが午後3時までにトレーニングセッションに到着できるようにしました。 | E-J 3.3, E-J-E 3.7; J-E 4.7, J-E-J 4.5 | Japanese-to-English was strong. English-to-Japanese made the booking subject ambiguous, as if Sara booked the bus. |
| Education | ミズ 田中はミゲルに答えを声に出して説明するよう依頼しました。ワークシートは結果は示しているものの、彼の論理は示されていませんでした。 | Mizu Tanaka asked Miguel to explain the answer out loud. Although the worksheet showed the result, his logic was not shown. | Mr. Tanaka asked Miguel to explain out loud how to solve it because the worksheet was not written only with answers and ideas. | ミスター 田中はミゲルに、ワークシートが答えやアイデアだけで書かれていないため、解き方を声に出して説明するよう依頼しました。 | E-J 2.8, E-J-E 2.8; J-E 2.4, J-E-J 2.3 | Education remained weak. `Ms.` became a name-like token, and the Japanese source was mistranslated into a confusing opposite-ish statement about answers and ideas. |
| Culture and Literature | 彼女のレビューで、ジュリアはハルキの静かな結末を、解決された謎ではなく、雨が降った後に開いたままの扉に例えました。 | In her review, Julia compared Haruki's quiet ending to a door that remained open after the rain, not a solved mystery. | In a book review, Julia compared Haruki's quiet ending to a door that remained open after the rain, not a solved mystery. | 書評で、ジュリアはハルキの静かな結末を、解決された謎ではなく、雨の後に開いたままの扉に例えました。 | E-J 4.7, E-J-E 4.7; J-E 4.7, J-E-J 4.5 | Low mode preserved the metaphor and contrast well, similar to high mode. |
| E-Commerce and Support | ニナが誤った充電器を受け取った後、BrightCartのケンは金曜日までに返金または交換品の発送を申し出ました。 | After Nina received the wrong charger, BrightCart's Ken offered to ship a refund or replacement by Friday. | After Nina received a different charger, BrightCart's Ken suggested a refund or a replacement item that would be shipped by Friday. | ニナが別の充電器を受け取った後、BrightCartのケンは、金曜日までに発送される返金または交換品を提案しました。 | E-J 3.6, E-J-E 3.5; J-E 4.6, J-E-J 3.6 | The offer was understandable, but the phrase could imply shipping a refund, especially after round trip. |
| Emergency and Disaster Response | ソフィア・ロペス船長は、シーダー通りの住民に対し、川が一晩でさらに1メートル上がる可能性があるため、正午までに退去するよう伝えました。 | Captain Sofia Lopez told the residents of Cedar Street to leave by noon because the river could rise another one meter overnight. | Captain Sofia Lopez instructed residents of Cedar Street to evacuate by noon because the river could rise another 1 meter at night. | ソフィア・ロペス大尉は、シーダー・ストリートの住民に対し、夜に川がさらに1メートル上昇する可能性があるため、正午までに避難するよう指示しました。 | E-J 3.9, E-J-E 4.4; J-E 4.7, J-E-J 4.2 | The action instruction remained clear. `Captain` still mapped to a potentially wrong role, but `Sofia` stayed stable in low mode. |

## Long Text Evaluation

The short-text results above do not fully represent how `trn` behaves on longer paragraphs. This section adds two longer passages and uses the default streaming settings, so the tool can split text near the default 512-character buffer boundary.

### Long Text Inputs

| Passage | Direction | Source length | Scenario |
| --- | --- | ---: | --- |
| Incident report | English to Japanese | 1,006 characters | A software incident report about duplicate renewal emails, billing safety, audit logs, an idempotency key, and a customer apology. |
| Municipal notice | Japanese to English | 884 characters | A city disaster-prevention notice about typhoon preparation, shelter routing, medical refrigeration, buses, residents with disabilities, and official information channels. |

### Long Text Speed

| Passage | Quality | Direct translation | Round-trip step | Direct output length | Round-trip output length |
| --- | --- | ---: | ---: | ---: | ---: |
| Incident report | `high` | 6.387 s | 5.395 s | 476 chars | 1,014 chars |
| Incident report | `low` | 0.681 s | 0.293 s | 489 chars | 971 chars |
| Municipal notice | `high` | 16.231 s | 15.461 s | 3,046 chars | 1,027 chars |
| Municipal notice | `low` | 0.966 s | 1.034 s | 2,909 chars | 1,054 chars |

### Long Text Quality Scores

| Passage | Quality | Direct score | Round-trip score | Direct translation assessment | Round-trip assessment |
| --- | ---: | ---: | ---: | --- | --- |
| Incident report | `high` | 4.0 | 3.7 | Preserved billing safety, duplicate emails, audit-log rationale, and exposed credentials. Weaker points: `Satoshi Hayashi` became `林直人`, `idempotency key` became `一意性キー`, and one sentence fragment appeared: `異なるサポートリンクで。` | Mostly recoverable, but `renewal emails` became `update emails`, Satoshi became `Naoki`, and `not exposed` weakened to `not publicly available`. |
| Incident report | `low` | 4.2 | 3.5 | Slightly better on key technical language: `idempotency key` became `冪等キー`, and `exposed` became `漏洩`. Satoshi was preserved as `林聡`. Still had a sentence-fragment problem around different support links. | Preserved the overall incident, but `idempotency key` became `power keys`, retry became a simpler `tried`, and the support-link clause attached to the wrong sentence. |
| Municipal notice | `high` | 4.0 | 2.8 | Covered most operational details, including shelter routing, medical equipment priority, buses, and official channels. Weaker points: gender drift, `class` for local groups, a boundary artifact `rain.She`, and some town/name drift. | Long round trip degraded heavily: stray fragments such as `e`, `p`, and `briefing`; `Sho Inoue` became `井上正`; `Wakakusa-cho` became `和泉町`; the final official-information sentence became garbled. |
| Municipal notice | `low` | 3.5 | 2.7 | Faster but less reliable. It introduced first-person `I asked`, `chairman of the self-government`, wrong pronouns, `fees/charges` style wording for charging priority, and `make a questionnaire` instead of drafting answers. | Similar degradation to high mode, with artifacts such as `Ght` and `メッドマップ画像`, awkward agency, and broken final instructions. |

### Long Text Comparison

| Finding | Evidence |
| --- | --- |
| Low mode stayed much faster on long text. | 9.38x faster for the English incident report and 16.80x faster for the Japanese municipal notice. |
| Low mode was competitive for the English technical incident. | It handled `idempotency key` as `冪等キー` and `exposed` as `漏洩`, both better than high mode. |
| High mode was better for the Japanese municipal notice. | It preserved more of the operational structure, while low mode introduced first-person and pronoun errors. |
| Both modes showed chunk-boundary or long-output artifacts. | High mode produced `rain.She` and Japanese round-trip fragments such as `e` and `p`; low mode produced `Ght` and `メッドマップ画像`. |
| Round-trip quality dropped more sharply on long text than on short text. | The long municipal notice had direct scores around 3.5-4.0, but round-trip scores around 2.7-2.8. |

## Overall Judgment

For casual use, `trn` is useful for English/Japanese short-form translation. For user-facing publication, legal text, financial communications, education settings, emergency messaging, or any text where names and roles matter, the output should be reviewed by a person.

The long-text tests strengthen that caution. `-q low` remained much faster and was sometimes competitive on technical terminology, but longer passages exposed more sentence-boundary artifacts, pronoun drift, and round-trip information loss in both quality modes. For long operational notices, `-q high` looked safer overall, while still requiring review.

The most important practical recommendation is to treat round-trip translation as a diagnostic signal, not as proof of correctness. The round-trip check revealed problems that were easy to miss in direct output, including a legal polarity reversal and broken text fragments. However, a clean round trip does not guarantee that the direct translation is correct.

## README Speed Benchmark

The speed check translated the current `README.md` from English to Japanese once per quality mode, using the default streaming settings. This is a single-run measurement, so it should be treated as an indicative local observation rather than a stable benchmark.

Command shape:

```sh
.build/debug/trn --from en --to ja --quality high < README.md
.build/debug/trn --from en --to ja --quality low < README.md
```

Results:

| Quality | Wall time | Input characters | Input bytes | Output characters | Output bytes |
| --- | ---: | ---: | ---: | ---: | ---: |
| `high` | 39.777 s | 4,818 | 5,039 | 3,294 | 6,737 |
| `low` | 3.461 s | 4,818 | 5,039 | 3,283 | 6,692 |

In this run, `-q low` was about 11.49x faster than `-q high` for README translation.

## Reproducible Process

The following process was used for this check.

1. Build the debug executable:

   ```sh
   swift build
   ```

2. Confirm that `trn` can call the local macOS Translation framework:

   ```sh
   printf 'こんにちは、佐藤さん。今日は研究室で新しい翻訳ツールを試します。\n' \
     | .build/debug/trn --from ja --to en
   ```

3. Create ten short test cases across diverse domains. Each case included at least one person name and roughly 100 characters of source text on the English side, with a matched Japanese source.

4. Run direct translations in both directions. The initial quality pass used explicit `high` mode. To preserve one output line per input line, each line was kept below the stream buffer size:

   ```sh
   .build/debug/trn --from en --to ja --quality high --buffer-size 140 --concurrency 4
   .build/debug/trn --from ja --to en --quality high --buffer-size 80 --concurrency 4
   ```

5. Run high-mode round-trip translations:

   ```sh
   .build/debug/trn --from ja --to en --quality high --buffer-size 100 --concurrency 4
   .build/debug/trn --from en --to ja --quality high --buffer-size 140 --concurrency 4
   ```

6. Repeat the same direct and round-trip batches with `--quality low`.

7. Check that the number of output lines matched the number of input lines after each batch.

8. Read each direct translation and round-trip translation. Assign 5-point scores for:

   - Direct meaning preservation.
   - Round-trip information preservation.
   - Proper names and roles.
   - Numbers, dates, and conditions.
   - Domain terminology.
   - Naturalness in the target language.

9. Benchmark `README.md` translation once per quality mode:

   ```sh
   .build/debug/trn --from en --to ja --quality high < README.md
   .build/debug/trn --from en --to ja --quality low < README.md
   ```

10. Add two long-text passages and run direct plus round-trip translations with default streaming settings:

   ```sh
   .build/debug/trn --from en --to ja --quality high
   .build/debug/trn --from en --to ja --quality low
   .build/debug/trn --from ja --to en --quality high
   .build/debug/trn --from ja --to en --quality low
   ```

11. Record wall-clock time for each long-text direct translation and round-trip step.

12. Summarize the results in an HTML report first, then consolidate and update the same findings in this project note.
